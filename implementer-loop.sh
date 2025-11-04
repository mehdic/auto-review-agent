#!/bin/bash
# Implementer Loop - Continuously implements tasks from tasks.md
# This is the WORKER that does the actual implementation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state-manager.sh"

PROJECT_PATH="$1"
TASKS_FILE="$2"
SPEC_NAME="$3"
SESSION_NAME="$4"

# Validation
if [ -z "$PROJECT_PATH" ] || [ -z "$TASKS_FILE" ] || [ -z "$SPEC_NAME" ]; then
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

log_message "═══════════════════════════════════════════════════════════"
log_message "Implementer Loop Starting"
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

# Main continuous loop
ITERATION=1
MAX_ITERATIONS=1000  # Prevent infinite loops
CONSECUTIVE_FAILURES=0
MAX_CONSECUTIVE_FAILURES=5

while [ $ITERATION -le $MAX_ITERATIONS ]; do
    log_message "───────────────────────────────────────────────────────────"
    log_message "ITERATION $ITERATION (Consecutive failures: $CONSECUTIVE_FAILURES)"
    log_message "───────────────────────────────────────────────────────────"

    update_state "$STATE_FILE" "implementing" "Iteration $ITERATION - Working on tasks"

    # Start Claude for this iteration
    log_message "Starting Claude for implementation..."

    # Create the implementation prompt (sanitize SPEC_NAME to avoid injection)
    SAFE_SPEC_NAME=$(echo "$SPEC_NAME" | tr -d '\n\r' | head -c 200)

    PROMPT="You are an autonomous implementer working on: ${SAFE_SPEC_NAME}

Read the tasks from: $TASKS_FILE

Your job:
1. Read ALL tasks in the file
2. Implement them systematically, one by one
3. Work autonomously - when you face choices, pick the best option and continue
4. Do NOT stop to ask questions - make reasonable decisions
5. Update progress by modifying $STATE_FILE (DO NOT use update_state function, modify the file directly)
6. Continue until 100% OF ALL TASKS ARE COMPLETE

CRITICAL REQUIREMENTS - 100% COMPLETION:
- You MUST complete EVERY task in the tasks.md file
- You MUST fix EVERY failing test until ALL tests pass
- DO NOT skip any task for any reason (\"requires features\", \"too complex\", etc)
- DO NOT mark work as complete until 100% success is achieved
- If you encounter a problem, you MUST solve it, not skip it
- There is a reviewer watching who will send you solutions if you get stuck
- Partial completion (\"I fixed 4 out of 71\") is NOT acceptable

IMPORTANT - State File Format:
The state file is at: $STATE_FILE
To update it, write the ENTIRE state including these fields:
{
  \"status\": \"implementing\" | \"completed\" | \"error\",
  \"last_update\": \"ISO timestamp\",
  \"message\": \"current status message\",
  \"current_task\": \"description of task you're working on\",
  \"completed_tasks\": [\"task1\", \"task2\"],
  \"total_tasks\": number,
  \"iteration\": $ITERATION
}

When you complete 100% of ALL tasks, set status to \"completed\".

ANTI-PATTERNS (DO NOT DO THESE):
- ❌ \"I'll skip this test because it requires feature X\"
- ❌ \"Moving on to the next task\" (without finishing current one)
- ❌ \"This is too complex for me to handle\"
- ❌ \"Leaving this as TODO for later\"
- ❌ \"I can't fix this\" (you can, keep trying)

WHAT TO DO WHEN STUCK:
- State clearly what the problem is
- The reviewer will provide specific solutions
- Try each solution systematically
- Report results
- Persist until success

SUCCESS CRITERIA:
- ALL tests passing (183/183, not 116/183)
- ALL tasks completed
- No skipped items
- No TODO/FIXME comments
- status=\"completed\" in $STATE_FILE

Start with the first uncompleted task (check $STATE_FILE for progress).
ITERATION: $ITERATION
Previous status: $(read_state "$STATE_FILE" "status" "unknown")"

    # Send prompt to Claude and capture output
    echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"

    CLAUDE_EXIT_CODE=$?

    log_message "Claude exited with code: $CLAUDE_EXIT_CODE"

    # Handle different exit codes
    if [ $CLAUDE_EXIT_CODE -eq 0 ]; then
        log_message "✅ Claude exited cleanly"
        CONSECUTIVE_FAILURES=0
    elif [ $CLAUDE_EXIT_CODE -eq 130 ]; then
        log_message "⚠️  Claude interrupted (Ctrl+C)"
        update_state "$STATE_FILE" "interrupted" "User interrupted execution"
        exit 130
    else
        log_message "❌ Claude exited with error code $CLAUDE_EXIT_CODE"
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))

        if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
            log_message "💀 Too many consecutive failures ($CONSECUTIVE_FAILURES)"
            update_state "$STATE_FILE" "failed" "Too many consecutive Claude failures"
            exit 1
        fi
    fi

    # Check if work is actually complete
    STATUS=$(read_state "$STATE_FILE" "status" "unknown")
    log_message "Current status from state file: $STATUS"

    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "complete" ] || [ "$STATUS" = "done" ]; then
        log_message "✅ Work marked as COMPLETED"

        # Double-check by reading more details
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
        exit 0
    fi

    # Check for error status
    if [ "$STATUS" = "error" ] || [ "$STATUS" = "failed" ]; then
        log_message "❌ Work marked as FAILED"
        log_message "Implementer exiting with error"
        exit 1
    fi

    # Claude exited but work not complete
    log_message "⚠️  Claude exited but work not complete (status: $STATUS)"
    log_message "Waiting 30 seconds before retry..."

    update_state "$STATE_FILE" "retrying" "Iteration $ITERATION ended, restarting in 30s..."

    sleep 30

    ITERATION=$((ITERATION + 1))
done

log_message "❌ Max iterations ($MAX_ITERATIONS) reached"
update_state "$STATE_FILE" "max_iterations" "Stopped after $MAX_ITERATIONS iterations"
exit 1
