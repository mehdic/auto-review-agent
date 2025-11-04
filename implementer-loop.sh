#!/bin/bash
# Implementer Loop - Works with PERSISTENT Claude session in tmux
# This is the WORKER that does the actual implementation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state-manager.sh"

PROJECT_PATH="$1"
TASKS_FILE="$2"
SPEC_NAME="$3"
SESSION_NAME="$4"

# Validation
if [ -z "$PROJECT_PATH" ] || [ -z "$TASKS_FILE" ] || [ -z "$SPEC_NAME" ] || [ -z "$SESSION_NAME" ]; then
    echo "Usage: $0 <project_path> <tasks_file> <spec_name> <session_name>"
    exit 1
fi

# Validate paths exist
if [ ! -d "$PROJECT_PATH" ]; then
    echo "ERROR: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
    echo "ERROR: Tasks file does not exist: $TASKS_FILE"
    exit 1
fi

COORDINATION_DIR="$PROJECT_PATH/coordination"
STATE_FILE="$COORDINATION_DIR/state.json"
LOG_FILE="$COORDINATION_DIR/logs/implementer.log"

mkdir -p "$COORDINATION_DIR/logs"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] IMPLEMENTER: $1" | tee -a "$LOG_FILE"
}

# Detect if Claude is waiting for input
# Strategy: Instead of trying to detect absence of working messages,
# detect PRESENCE of the input prompt (positive signal)
is_claude_waiting_for_input() {
    local output="$1"

    # PRIMARY SIGNAL: Look for the "Message:" prompt that Claude shows
    # This is what appears when Claude is ready for input
    if echo "$output" | tail -10 | grep -qE "^Message:"; then
        return 0  # Definitely waiting for input
    fi

    # SECONDARY: Look for input cursor indicators
    if echo "$output" | tail -5 | grep -qE "(^>|Type a message|Enter your|^│.*│$)"; then
        return 0  # Waiting for input
    fi

    # If we DON'T see the prompt, Claude is probably still working
    return 1  # Not waiting, still working
}

log_message "═══════════════════════════════════════════════════════════"
log_message "Implementer Loop Starting (Persistent Claude Session)"
log_message "Project: $PROJECT_PATH"
log_message "Tasks: $TASKS_FILE"
log_message "Spec: $SPEC_NAME"
log_message "═══════════════════════════════════════════════════════════"

# Initialize state
update_state "$STATE_FILE" "initializing" "Implementer starting up"

# Change to project directory with error checking
if ! cd "$PROJECT_PATH"; then
    log_message "ERROR: Failed to cd to $PROJECT_PATH"
    update_state "$STATE_FILE" "error" "Failed to access project directory"
    exit 1
fi

# Start Claude ONCE in this window (NOT in a loop)
log_message "Starting Claude Code session..."
tmux send-keys -t "$SESSION_NAME:implementer" "cd '$PROJECT_PATH' && claude"
tmux send-keys -t "$SESSION_NAME:implementer" Enter
sleep 3

# Main loop - send prompts to existing Claude session
ITERATION=1
MAX_ITERATIONS=1000
CONSECUTIVE_FAILURES=0
MAX_CONSECUTIVE_FAILURES=5

while [ $ITERATION -le $MAX_ITERATIONS ]; do
    log_message "───────────────────────────────────────────────────────────"
    log_message "ITERATION $ITERATION"
    log_message "───────────────────────────────────────────────────────────"

    update_state "$STATE_FILE" "implementing" "Iteration $ITERATION - Working on tasks"

    # Create the implementation prompt
    SAFE_SPEC_NAME=$(echo "$SPEC_NAME" | tr -d '\n\r' | head -c 200)

    PROMPT="You are an autonomous implementer working on: ${SAFE_SPEC_NAME}

Read the tasks from: $TASKS_FILE

Your job:
1. Read ALL tasks in the file
2. Implement them systematically, one by one
3. Work autonomously - when you face choices, pick the best option and continue
4. DO NOT stop to ask questions - make reasonable decisions
5. Update progress by modifying $STATE_FILE
6. Continue until 100% OF ALL TASKS ARE COMPLETE

CRITICAL REQUIREMENTS - 100% COMPLETION:
- You MUST complete EVERY task in the tasks.md file
- You MUST fix EVERY failing test until ALL tests pass
- DO NOT skip any task for any reason
- DO NOT mark work as complete until 100% success is achieved
- If you encounter a problem, you MUST solve it, not skip it
- Partial completion is NOT acceptable

State file: $STATE_FILE
Iteration: $ITERATION
Previous status: $(read_state "$STATE_FILE" "status" "unknown")

When you complete 100% of tasks, update $STATE_FILE with status=\"completed\".

Start working now."

    # Wait for Claude to be ready for input
    log_message "Waiting for Claude to be ready..."
    for i in {1..30}; do
        sleep 2
        CURRENT_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p -S -20)

        if is_claude_waiting_for_input "$CURRENT_OUTPUT"; then
            log_message "Claude is ready for input"
            break
        fi

        if [ $i -eq 30 ]; then
            log_message "⚠️  Timeout waiting for Claude to be ready"
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
            break
        fi
    done

    # Send the prompt to Claude
    log_message "Sending prompt to Claude..."

    # Send prompt line by line to avoid issues
    echo "$PROMPT" | while IFS= read -r line; do
        tmux send-keys -t "$SESSION_NAME:implementer" "$line"
        tmux send-keys -t "$SESSION_NAME:implementer" Enter
        sleep 0.1
    done

    # Send final Enter to submit
    tmux send-keys -t "$SESSION_NAME:implementer" Enter

    # Wait for Claude to finish processing
    # PRIMARY: Detect output stability (no changes for 20 seconds)
    # SECONDARY: Look for "Message:" prompt as confirmation
    log_message "Waiting for Claude to finish working..."
    WORK_START_TIME=$(date +%s)
    LAST_ACTIVITY_TIME=$(date +%s)
    LAST_OUTPUT_HASH=""
    STABLE_COUNT=0  # How many checks in a row output has been stable
    LAST_DETECTION=""

    while true; do
        sleep 5
        CURRENT_TIME=$(date +%s)

        # Capture current output
        CURRENT_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p -S -50)

        # Calculate hash of last 20 lines (the "active" area)
        OUTPUT_HASH=$(echo "$CURRENT_OUTPUT" | tail -20 | md5sum | cut -d' ' -f1)

        # Check if output has changed
        if [ "$OUTPUT_HASH" = "$LAST_OUTPUT_HASH" ] && [ -n "$LAST_OUTPUT_HASH" ]; then
            # Output unchanged
            STABLE_COUNT=$((STABLE_COUNT + 1))

            # Log every 4 checks (20 seconds)
            if [ $((STABLE_COUNT % 4)) -eq 0 ]; then
                STABLE_DURATION=$((STABLE_COUNT * 5))
                log_message "Output stable for ${STABLE_DURATION}s (checking...)"
            fi

            # Check if we see the "Message:" prompt
            HAS_PROMPT=$(is_claude_waiting_for_input "$CURRENT_OUTPUT" && echo "yes" || echo "no")

            # If output stable for 20+ seconds AND we see prompt, definitely done
            if [ $STABLE_COUNT -ge 4 ] && [ "$HAS_PROMPT" = "yes" ]; then
                log_message "✅ Claude finished (stable 20s + prompt detected)"
                CONSECUTIVE_FAILURES=0
                break
            fi

            # If output stable for 40+ seconds, done even without seeing prompt
            # (prompt might be scrolled out of view)
            if [ $STABLE_COUNT -ge 8 ]; then
                log_message "✅ Claude finished (stable 40s, assuming done)"
                CONSECUTIVE_FAILURES=0
                break
            fi
        else
            # Output changed, Claude is working
            if [ $STABLE_COUNT -gt 0 ]; then
                log_message "Output changed after ${STABLE_COUNT} stable checks, Claude resumed working"
            fi

            STABLE_COUNT=0
            LAST_ACTIVITY_TIME=$CURRENT_TIME
            LAST_OUTPUT_HASH="$OUTPUT_HASH"
        fi

        # Check for total idle timeout (no activity for 10 minutes = likely stuck)
        IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVITY_TIME))
        if [ $IDLE_TIME -gt 600 ]; then
            log_message "⚠️  No output changes for $IDLE_TIME seconds - may be stuck"
            # Watchdog will handle this
            break
        fi

        # Max overall time per iteration: 60 minutes
        ELAPSED=$((CURRENT_TIME - WORK_START_TIME))
        if [ $ELAPSED -gt 3600 ]; then
            log_message "⚠️  Iteration exceeded 60 minutes"
            break
        fi
    done

    # Check if work is actually complete
    STATUS=$(read_state "$STATE_FILE" "status" "unknown")
    log_message "Current status from state file: $STATUS"

    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "complete" ] || [ "$STATUS" = "done" ]; then
        log_message "✅ Work marked as COMPLETED"

        # Verify completion
        COMPLETED_COUNT=$(python3 -c "
import json
try:
    with open('$STATE_FILE') as f:
        state = json.load(f)
    completed = state.get('completed_tasks', [])
    print(len(completed))
except:
    print(0)
" 2>/dev/null)

        log_message "Tasks completed: $COMPLETED_COUNT"
        log_message "Implementer exiting successfully"
        update_state "$STATE_FILE" "completed" "All tasks implemented successfully at iteration $ITERATION"

        # Close Claude session
        tmux send-keys -t "$SESSION_NAME:implementer" C-c
        sleep 1
        exit 0
    fi

    # Check for error status
    if [ "$STATUS" = "error" ] || [ "$STATUS" = "failed" ]; then
        log_message "❌ Work marked as FAILED"
        log_message "Implementer exiting with error"
        exit 1
    fi

    # Check for blocked status (from watchdog)
    if [ "$STATUS" = "blocked" ]; then
        log_message "⚠️  Work blocked - requires manual intervention"
        log_message "Pausing for user to review and fix"
        sleep 300  # Wait 5 minutes for user intervention
        # Continue trying after pause
    fi

    # Claude finished turn but work not complete
    log_message "⚠️  Claude finished turn but work not complete (status: $STATUS)"
    log_message "Waiting 30 seconds before next iteration..."

    update_state "$STATE_FILE" "retrying" "Iteration $ITERATION ended, continuing..."

    sleep 30

    ITERATION=$((ITERATION + 1))
done

log_message "❌ Max iterations ($MAX_ITERATIONS) reached"
update_state "$STATE_FILE" "max_iterations" "Stopped after $MAX_ITERATIONS iterations"
exit 1
