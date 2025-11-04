#!/bin/bash
# Implementer Loop - Continuously implements tasks from tasks.md
# This is the WORKER that does the actual implementation

PROJECT_PATH="$1"
TASKS_FILE="$2"
SPEC_NAME="$3"
SESSION_NAME="$4"

if [ -z "$PROJECT_PATH" ] || [ -z "$TASKS_FILE" ] || [ -z "$SPEC_NAME" ]; then
    echo "Usage: $0 <project_path> <tasks_file> <spec_name> <session_name>"
    exit 1
fi

COORDINATION_DIR="$PROJECT_PATH/coordination"
STATE_FILE="$COORDINATION_DIR/state.json"
LOG_FILE="$COORDINATION_DIR/logs/implementer.log"

mkdir -p "$COORDINATION_DIR/logs"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] IMPLEMENTER: $1" | tee -a "$LOG_FILE"
}

update_state() {
    local status="$1"
    local message="$2"

    python3 << EOF
import json
from datetime import datetime

try:
    with open('$STATE_FILE', 'r') as f:
        state = json.load(f)
except:
    state = {}

state['status'] = '$status'
state['last_update'] = datetime.now().isoformat()
state['message'] = '$message'

with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
EOF
}

log_message "═══════════════════════════════════════════════════════════"
log_message "Implementer Loop Starting"
log_message "Project: $PROJECT_PATH"
log_message "Tasks: $TASKS_FILE"
log_message "Spec: $SPEC_NAME"
log_message "═══════════════════════════════════════════════════════════"

# Initialize state
update_state "initializing" "Implementer starting up"

cd "$PROJECT_PATH"

# Main continuous loop
ITERATION=1
MAX_ITERATIONS=1000  # Prevent infinite loops

while [ $ITERATION -le $MAX_ITERATIONS ]; do
    log_message "───────────────────────────────────────────────────────────"
    log_message "ITERATION $ITERATION"
    log_message "───────────────────────────────────────────────────────────"

    update_state "implementing" "Iteration $ITERATION - Working on tasks"

    # Start Claude for this iteration
    log_message "Starting Claude for implementation..."

    # Create the implementation prompt
    PROMPT="You are an autonomous implementer working on: $SPEC_NAME

Read the tasks from: $TASKS_FILE

Your job:
1. Read ALL tasks in the file
2. Implement them systematically, one by one
3. Work autonomously - when you face choices, pick the best option and continue
4. Do NOT stop to ask questions - make reasonable decisions
5. Update $STATE_FILE with progress after completing each task
6. Continue until ALL tasks are complete

Format for state updates:
{
  \"status\": \"implementing\",
  \"current_task\": \"task description\",
  \"completed_tasks\": [\"task1\", \"task2\", ...],
  \"total_tasks\": number
}

CRITICAL:
- Be autonomous - make decisions and move forward
- Don't wait for approval - just do the work
- If uncertain, pick the most reasonable option
- Document your decisions in code comments
- Update progress regularly

Start with the first uncompleted task."

    # Send prompt to Claude
    echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"

    CLAUDE_EXIT_CODE=$?

    log_message "Claude exited with code: $CLAUDE_EXIT_CODE"

    # Check if work is actually complete
    if [ -f "$STATE_FILE" ]; then
        STATUS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('status', 'unknown'))" 2>/dev/null || echo "unknown")

        if [ "$STATUS" = "completed" ]; then
            log_message "✅ Work marked as COMPLETED"
            log_message "Implementer exiting successfully"
            update_state "completed" "All tasks implemented successfully"
            exit 0
        fi
    fi

    # Claude exited but work not complete
    log_message "⚠️  Claude exited but work not complete (status: $STATUS)"
    log_message "Waiting 30 seconds before retry..."

    update_state "retrying" "Iteration $ITERATION ended, restarting..."

    sleep 30

    ITERATION=$((ITERATION + 1))
done

log_message "❌ Max iterations ($MAX_ITERATIONS) reached"
update_state "max_iterations" "Stopped after $MAX_ITERATIONS iterations"
exit 1
