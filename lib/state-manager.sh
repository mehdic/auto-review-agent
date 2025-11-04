#!/bin/bash
# Robust state file management with file locking

# Read state file with retry and locking
read_state() {
    local state_file="$1"
    local key="$2"
    local default="${3:-unknown}"

    # Retry up to 3 times for race conditions
    for i in {1..3}; do
        if [ -f "$state_file" ]; then
            local value=$(python3 -c "
import json
import sys
try:
    with open('$state_file', 'r') as f:
        state = json.load(f)
    print(state.get('$key', '$default'))
except (json.JSONDecodeError, IOError):
    print('$default')
    sys.exit(1)
" 2>/dev/null)

            if [ $? -eq 0 ]; then
                echo "$value"
                return 0
            fi
        fi
        sleep 0.5
    done

    echo "$default"
    return 1
}

# Update state file atomically with file locking
update_state() {
    local state_file="$1"
    local status="$2"
    local message="$3"

    # Use atomic write: write to temp, then move
    local temp_file="${state_file}.tmp.$$"

    python3 << EOF
import json
import fcntl
from datetime import datetime
import os

state = {}

# Try to read existing state (preserve other fields)
if os.path.exists('$state_file'):
    try:
        with open('$state_file', 'r') as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_SH)
            state = json.load(f)
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    except:
        pass  # Start fresh if corrupt

# Update only these fields, preserve others
state['status'] = '$status'
state['last_update'] = datetime.now().isoformat()
state['message'] = '''$message'''

# Write atomically
with open('$temp_file', 'w') as f:
    json.dump(state, f, indent=2)
    f.flush()
    os.fsync(f.fileno())

# Atomic rename
os.rename('$temp_file', '$state_file')
EOF

    return $?
}

# Check if implementer loop script is still running in tmux window
is_implementer_alive() {
    local session_name="$1"
    local window_name="$2"

    # Check if window exists
    if ! tmux list-windows -t "$session_name" 2>/dev/null | grep -q "$window_name"; then
        return 1
    fi

    # Get pane PID
    local pane_pid=$(tmux list-panes -t "$session_name:$window_name" -F "#{pane_pid}" 2>/dev/null | head -1)

    if [ -z "$pane_pid" ]; then
        return 1
    fi

    # NEW ARCHITECTURE: Check if Claude is running in the pane (not implementer-loop.sh)
    # Claude runs IN the window, implementer-loop.sh runs in background
    pgrep -P "$pane_pid" "claude" >/dev/null 2>&1
    local claude_running=$?

    # Check if background implementer-loop.sh is running (from PID file)
    local project_path=$(tmux display-message -t "$session_name:$window_name" -p "#{pane_current_path}" 2>/dev/null)
    local pid_file="$project_path/coordination/implementer.pid"
    local loop_running=1  # Default to not running

    if [ -f "$pid_file" ]; then
        local implementer_pid=$(cat "$pid_file" 2>/dev/null)
        if [ -n "$implementer_pid" ] && kill -0 "$implementer_pid" 2>/dev/null; then
            loop_running=0  # Running
        fi
    fi

    # Both should be running for healthy state
    if [ $loop_running -eq 0 ] && [ $claude_running -eq 0 ]; then
        return 0  # Both running, healthy
    elif [ $loop_running -eq 0 ] && [ $claude_running -ne 0 ]; then
        # Loop running but Claude crashed - loop will detect and handle
        return 0
    else
        # Background loop crashed
        return 1
    fi
}

# Detect if Claude is waiting for input (more robust)
is_waiting_for_input() {
    local output="$1"

    # Multiple patterns for waiting state
    echo "$output" | tail -10 | grep -qE "(^>|^\$|^claude>|Waiting for|Enter your|Press any key|^Please |^Choose |^\?)"
}

# Detect if asking a question (more robust patterns)
is_asking_question() {
    local output="$1"

    # More comprehensive question patterns
    echo "$output" | tail -20 | grep -qiE "(should I|would you like|do you want|which.*prefer|what.*better|need.*input|please.*confirm|approve|permission|which option|select.*option|choose between|or would you|proceed\?|continue\?)"
}

# Check if output indicates error/stuck state
is_error_state() {
    local output="$1"

    echo "$output" | tail -20 | grep -qiE "(error:|exception|traceback|fatal|failed|unable to|cannot|could not|permission denied|command not found)"
}

# Detect if implementer is skipping or giving up on tasks
is_giving_up() {
    local output="$1"

    # Patterns that indicate giving up
    echo "$output" | tail -30 | grep -qiE "(skipping|skip this|moving on|can't fix|unable to fix|too complex|requires.*work|will need|leaving.*for later|TODO|FIXME|not possible|blocked by|requires feature)"
}

# Extract what the implementer is giving up on
extract_blocked_task() {
    local output="$1"

    # Try to extract the test/task name that's being skipped
    echo "$output" | tail -30 | grep -iE "(skipping|skip this|moving on|can't fix)" | head -1
}
