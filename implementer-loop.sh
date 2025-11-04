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

# Detect if Claude finished responding
# USER'S BRILLIANT SOLUTION: We tell Claude to end with "BAZINGA"
# Then we just look for that marker!
is_claude_finished() {
    local output="$1"

    # Look for BAZINGA in the last 30 lines
    # (User tested this and it works!)
    if echo "$output" | tail -30 | grep -q "BAZINGA"; then
        return 0  # Claude finished this turn
    fi

    return 1  # Still working
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

    PROMPT="You are an autonomous developer working on: ${SAFE_SPEC_NAME}

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

IMPORTANT: When you finish your response, make sure the very last word you write is exactly: BAZINGA

Start working now."

    # Wait for Claude to be ready for input
    log_message "Waiting for Claude to be ready..."
    for i in {1..30}; do
        sleep 2
        CURRENT_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p -S -20)

        if is_waiting_for_input "$CURRENT_OUTPUT"; then
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
    # USER'S SOLUTION: Look for BAZINGA marker that Claude adds at end
    log_message "Waiting for Claude to finish (looking for BAZINGA marker)..."
    WORK_START_TIME=$(date +%s)
    LAST_CHECK_TIME=$(date +%s)
    CHECK_COUNT=0

    while true; do
        sleep 5
        CURRENT_TIME=$(date +%s)
        CHECK_COUNT=$((CHECK_COUNT + 1))

        # Capture current output
        CURRENT_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p -S -50)

        # Check for BAZINGA marker (simple and reliable!)
        if is_claude_finished "$CURRENT_OUTPUT"; then
            log_message "✅ Claude finished (BAZINGA marker detected)"
            CONSECUTIVE_FAILURES=0
            break
        fi

        # Log progress every minute
        if [ $((CHECK_COUNT % 12)) -eq 0 ]; then
            ELAPSED=$((CURRENT_TIME - WORK_START_TIME))
            log_message "Still working... (${ELAPSED}s elapsed, waiting for BAZINGA)"
        fi

        # Timeout if no BAZINGA after 60 minutes
        ELAPSED=$((CURRENT_TIME - WORK_START_TIME))
        if [ $ELAPSED -gt 3600 ]; then
            log_message "⚠️  Iteration exceeded 60 minutes without BAZINGA marker"
            log_message "This may indicate Claude didn't follow instructions or is stuck"
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
