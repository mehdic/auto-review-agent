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

# Check if Claude process is running in tmux window
is_claude_running() {
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

    # Check if Claude process exists under this pane
    pgrep -P "$pane_pid" "claude" >/dev/null 2>&1
    return $?
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
