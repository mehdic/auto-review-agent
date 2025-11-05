#!/bin/bash
# Orchestrator Loop - Manages Developer and Tech Lead sub-agents
# This is the MASTER COORDINATOR that orchestrates the multi-agent system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state-manager.sh"

PROJECT_PATH="$1"
SPEC_DIR="$2"
SESSION_NAME="$3"

# Validation
if [ -z "$PROJECT_PATH" ] || [ -z "$SPEC_DIR" ] || [ -z "$SESSION_NAME" ]; then
    echo "Usage: $0 <project_path> <spec_dir> <session_name>"
    exit 1
fi

# Validate paths
if [ ! -d "$PROJECT_PATH" ]; then
    echo "ERROR: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

if [ ! -d "$SPEC_DIR" ]; then
    echo "ERROR: Spec directory does not exist: $SPEC_DIR"
    exit 1
fi

COORDINATION_DIR="$PROJECT_PATH/coordination"
ORCHESTRATOR_STATE="$COORDINATION_DIR/orchestrator_state.json"
DEVELOPER_STATE="$COORDINATION_DIR/developer_state.json"
TECHLEAD_STATE="$COORDINATION_DIR/techlead_state.json"
LOG_FILE="$COORDINATION_DIR/logs/orchestrator.log"

SPEC_FILE="$SPEC_DIR/spec.md"
TASKS_FILE="$SPEC_DIR/tasks.md"

mkdir -p "$COORDINATION_DIR/logs"
mkdir -p "$COORDINATION_DIR/messages"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ORCHESTRATOR: $1" | tee -a "$LOG_FILE"
}

# Initialize state files
initialize_states() {
    log_message "Initializing state files..."

    # Orchestrator state
    cat > "$ORCHESTRATOR_STATE" <<EOF
{
  "current_phase": "initializing",
  "active_agent": "none",
  "current_task_id": "none",
  "iteration": 0,
  "status": "starting",
  "message": "Orchestrator initializing",
  "last_update": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "conversation_log": []
}
EOF

    # Developer state
    cat > "$DEVELOPER_STATE" <<EOF
{
  "status": "idle",
  "current_task": "none",
  "task_id": "none",
  "progress": "Waiting for task assignment",
  "files_modified": [],
  "blockers": [],
  "questions": [],
  "last_update": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "message": "Ready to work"
}
EOF

    # Tech lead state
    cat > "$TECHLEAD_STATE" <<EOF
{
  "status": "idle",
  "reviewing_task": "none",
  "review_type": "none",
  "feedback": {
    "approved": null,
    "issues": [],
    "suggestions": [],
    "next_steps": []
  },
  "decisions": [],
  "last_update": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    # Message queues
    cat > "$COORDINATION_DIR/messages/developer_to_techlead.json" <<EOF
{
  "messages": [],
  "unread_count": 0
}
EOF

    cat > "$COORDINATION_DIR/messages/techlead_to_developer.json" <<EOF
{
  "messages": [],
  "unread_count": 0
}
EOF

    log_message "✓ State files initialized"
}

# Read orchestrator prompt
ORCHESTRATOR_PROMPT=$(cat "$SCRIPT_DIR/prompts/orchestrator_agent.txt")
DEVELOPER_PROMPT=$(cat "$SCRIPT_DIR/prompts/sub-agents/developer_agent.txt")
TECHLEAD_PROMPT=$(cat "$SCRIPT_DIR/prompts/sub-agents/techlead_agent.txt")

log_message "═══════════════════════════════════════════════════════════"
log_message "Orchestrator Starting - Multi-Agent System"
log_message "Project: $PROJECT_PATH"
log_message "Spec: $SPEC_DIR"
log_message "Session: $SESSION_NAME"
log_message "═══════════════════════════════════════════════════════════"

# Initialize states
initialize_states

# Change to project directory
if ! cd "$PROJECT_PATH"; then
    log_message "ERROR: Failed to cd to $PROJECT_PATH"
    exit 1
fi

# Main orchestration loop
ITERATION=1
MAX_ITERATIONS=500
CONSECUTIVE_IDLE=0

log_message "Starting orchestration loop..."

while [ $ITERATION -le $MAX_ITERATIONS ]; do
    log_message "─────────────────────────────────────────────────────────"
    log_message "ITERATION $ITERATION"
    log_message "─────────────────────────────────────────────────────────"

    # Read current states
    DEVELOPER_STATUS=$(read_state "$DEVELOPER_STATE" "status" "unknown")
    TECHLEAD_STATUS=$(read_state "$TECHLEAD_STATE" "status" "unknown")
    ORCHESTRATOR_STATUS=$(read_state "$ORCHESTRATOR_STATE" "status" "unknown")

    log_message "States: Developer=$DEVELOPER_STATUS, TechLead=$TECHLEAD_STATUS, Orchestrator=$ORCHESTRATOR_STATUS"

    # Check if session still exists
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        log_message "Session $SESSION_NAME no longer exists - exiting gracefully"
        exit 0
    fi

    # Check for completion
    if [ "$ORCHESTRATOR_STATUS" = "completed" ]; then
        log_message "🎉 ORCHESTRATION COMPLETE!"
        log_message "All tasks completed successfully"
        exit 0
    fi

    # Decision logic: Who should act next?
    NEXT_ACTION="none"

    # Priority 1: Developer is blocked - activate tech lead
    if [ "$DEVELOPER_STATUS" = "blocked" ]; then
        log_message "🚨 Developer is BLOCKED - activating tech lead to unblock"
        NEXT_ACTION="techlead_unblock"

    # Priority 2: Developer waiting for review - activate tech lead
    elif [ "$DEVELOPER_STATUS" = "waiting_review" ]; then
        log_message "📋 Developer requests REVIEW - activating tech lead"
        NEXT_ACTION="techlead_review"

    # Priority 3: Developer has questions - activate tech lead
    elif python3 -c "import json; f=open('$DEVELOPER_STATE'); d=json.load(f); print(len(d.get('questions', [])))" 2>/dev/null | grep -q -v "^0$"; then
        log_message "❓ Developer has QUESTIONS - activating tech lead"
        NEXT_ACTION="techlead_answer"

    # Priority 4: Tech lead provided feedback - send to developer
    elif [ "$TECHLEAD_STATUS" = "complete" ]; then
        TECH_APPROVED=$(python3 -c "import json; f=open('$TECHLEAD_STATE'); d=json.load(f); print(d.get('feedback', {}).get('approved', 'null'))" 2>/dev/null)

        if [ "$TECH_APPROVED" = "True" ] || [ "$TECH_APPROVED" = "true" ]; then
            log_message "✅ Tech lead APPROVED - assigning next task to developer"
            NEXT_ACTION="developer_next_task"
        else
            log_message "🔄 Tech lead requests CHANGES - sending feedback to developer"
            NEXT_ACTION="developer_revise"
        fi

    # Priority 5: Developer is idle - give work
    elif [ "$DEVELOPER_STATUS" = "idle" ] || [ "$DEVELOPER_STATUS" = "complete" ]; then
        log_message "💼 Developer is IDLE - assigning work"
        NEXT_ACTION="developer_assign_task"

    # Priority 6: Developer is working - monitor
    elif [ "$DEVELOPER_STATUS" = "working" ]; then
        log_message "⚙️  Developer is WORKING - monitoring progress"
        NEXT_ACTION="monitor"

    # Priority 7: Error states
    elif [ "$DEVELOPER_STATUS" = "error" ]; then
        log_message "❌ Developer in ERROR state - attempting recovery"
        NEXT_ACTION="developer_recover"

    else
        log_message "⏸️  No action needed - waiting"
        NEXT_ACTION="wait"
    fi

    log_message "Decision: $NEXT_ACTION"

    # Execute the decided action
    case "$NEXT_ACTION" in
        techlead_unblock)
            log_message "Activating Tech Lead for unblocking..."

            # Get blocker details
            BLOCKERS=$(python3 -c "import json; f=open('$DEVELOPER_STATE'); d=json.load(f); print(' | '.join(d.get('blockers', [])))" 2>/dev/null)

            # Prepare tech lead prompt
            TECH_PROMPT="$TECHLEAD_PROMPT

=== CURRENT REQUEST ===
Type: UNBLOCKING
Developer is blocked on: $BLOCKERS

Developer state file: $DEVELOPER_STATE
Your state file: $TECHLEAD_STATE
Messages from developer: $COORDINATION_DIR/messages/developer_to_techlead.json
Send your guidance to: $COORDINATION_DIR/messages/techlead_to_developer.json

Read the developer's blockers and provide specific, actionable solutions.
Update your state file when done.
"

            # Send to Claude in tech lead window
            echo "$TECH_PROMPT" | tmux load-buffer -
            tmux paste-buffer -t "$SESSION_NAME:techlead"
            tmux send-keys -t "$SESSION_NAME:techlead" Enter

            # Wait for tech lead to respond (check state file)
            log_message "Waiting for tech lead to provide guidance..."
            sleep 30
            ;;

        techlead_review)
            log_message "Activating Tech Lead for code review..."

            # Get files modified
            FILES_MODIFIED=$(python3 -c "import json; f=open('$DEVELOPER_STATE'); d=json.load(f); print(', '.join(d.get('files_modified', [])))" 2>/dev/null)
            CURRENT_TASK=$(read_state "$DEVELOPER_STATE" "current_task" "unknown")

            TECH_PROMPT="$TECHLEAD_PROMPT

=== CURRENT REQUEST ===
Type: CODE REVIEW
Task: $CURRENT_TASK
Files modified: $FILES_MODIFIED

Developer state: $DEVELOPER_STATE
Your state file: $TECHLEAD_STATE
Developer's message: $COORDINATION_DIR/messages/developer_to_techlead.json
Send feedback to: $COORDINATION_DIR/messages/techlead_to_developer.json

Review the developer's implementation and provide feedback.
Update your state file with approval or requested changes.
"

            echo "$TECH_PROMPT" | tmux load-buffer -
            tmux paste-buffer -t "$SESSION_NAME:techlead"
            tmux send-keys -t "$SESSION_NAME:techlead" Enter

            log_message "Waiting for tech lead review..."
            sleep 30
            ;;

        developer_assign_task)
            log_message "Assigning task to developer..."

            # Read tasks file and find next task
            # For now, use a simple approach - read the first uncompleted task

            DEV_PROMPT="$DEVELOPER_PROMPT

=== TASK ASSIGNMENT ===
Project: $PROJECT_PATH
Specification: $SPEC_FILE
Tasks file: $TASKS_FILE

Your state file: $DEVELOPER_STATE
Messages from tech lead: $COORDINATION_DIR/messages/techlead_to_developer.json
Send messages to tech lead: $COORDINATION_DIR/messages/developer_to_techlead.json

Read the tasks file and start working on the next task.
Update your state file as you work.
Request review when complete.
"

            echo "$DEV_PROMPT" | tmux load-buffer -
            tmux paste-buffer -t "$SESSION_NAME:developer"
            tmux send-keys -t "$SESSION_NAME:developer" Enter

            # Update developer state to working
            python3 << EOF
import json
from datetime import datetime
with open('$DEVELOPER_STATE', 'r') as f:
    state = json.load(f)
state['status'] = 'working'
state['message'] = 'Working on assigned task'
state['last_update'] = datetime.now().isoformat()
with open('$DEVELOPER_STATE', 'w') as f:
    json.dump(state, f, indent=2)
EOF

            log_message "Task assigned to developer"
            sleep 30
            ;;

        developer_revise)
            log_message "Sending tech lead feedback to developer..."

            # Get tech lead feedback
            FEEDBACK=$(python3 -c "import json; f=open('$TECHLEAD_STATE'); d=json.load(f); import json as j; print(j.dumps(d.get('feedback', {})))" 2>/dev/null)

            DEV_PROMPT="$DEVELOPER_PROMPT

=== TECH LEAD FEEDBACK ===
Your tech lead has reviewed your work and requests changes.

Read the feedback from: $COORDINATION_DIR/messages/techlead_to_developer.json

Your state file: $DEVELOPER_STATE

Implement the requested changes and resubmit for review.
Update your state file as you work.
"

            echo "$DEV_PROMPT" | tmux load-buffer -
            tmux paste-buffer -t "$SESSION_NAME:developer"
            tmux send-keys -t "$SESSION_NAME:developer" Enter

            # Reset tech lead state to idle
            python3 << EOF
import json
from datetime import datetime
with open('$TECHLEAD_STATE', 'r') as f:
    state = json.load(f)
state['status'] = 'idle'
state['last_update'] = datetime.now().isoformat()
with open('$TECHLEAD_STATE', 'w') as f:
    json.dump(state, f, indent=2)
EOF

            log_message "Feedback sent to developer"
            sleep 30
            ;;

        developer_next_task)
            log_message "Moving developer to next task..."

            # Mark current task complete and assign next
            DEV_PROMPT="$DEVELOPER_PROMPT

=== TASK APPROVED ===
Tech lead approved your work! Well done.

Read the next task from: $TASKS_FILE
Your state file: $DEVELOPER_STATE

Move to the next task and start working.
If all tasks are complete, update orchestrator state to 'completed'.
"

            echo "$DEV_PROMPT" | tmux load-buffer -
            tmux paste-buffer -t "$SESSION_NAME:developer"
            tmux send-keys -t "$SESSION_NAME:developer" Enter

            # Reset tech lead state to idle
            python3 << EOF
import json
from datetime import datetime
with open('$TECHLEAD_STATE', 'r') as f:
    state = json.load(f)
state['status'] = 'idle'
state['reviewing_task'] = 'none'
state['feedback'] = {
    'approved': None,
    'issues': [],
    'suggestions': [],
    'next_steps': []
}
state['last_update'] = datetime.now().isoformat()
with open('$TECHLEAD_STATE', 'w') as f:
    json.dump(state, f, indent=2)
EOF

            log_message "Next task assigned"
            sleep 30
            ;;

        monitor)
            log_message "Monitoring developer progress..."

            # Check for file activity
            RECENT_CHANGES=$(find "$PROJECT_PATH" -type f \
                \( -name "*.java" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \
                -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" -o -name "*.c" \) \
                -mmin -5 2>/dev/null | wc -l)

            log_message "Recent file changes: $RECENT_CHANGES"

            # Check how long developer has been in working state
            LAST_UPDATE=$(read_state "$DEVELOPER_STATE" "last_update" "unknown")
            log_message "Developer last update: $LAST_UPDATE"

            # If no activity for 10 minutes, nudge developer
            # (Implementation would check timestamp difference)

            CONSECUTIVE_IDLE=0
            sleep 60  # Monitor less frequently
            ;;

        wait)
            CONSECUTIVE_IDLE=$((CONSECUTIVE_IDLE + 1))
            log_message "Waiting... (idle count: $CONSECUTIVE_IDLE)"

            if [ $CONSECUTIVE_IDLE -gt 5 ]; then
                log_message "⚠️  System idle for too long - may be stuck"
                # Could implement recovery logic here
            fi

            sleep 30
            ;;

        developer_recover)
            log_message "Attempting to recover from error state..."

            # Reset developer to idle and try again
            python3 << EOF
import json
from datetime import datetime
with open('$DEVELOPER_STATE', 'r') as f:
    state = json.load(f)
state['status'] = 'idle'
state['message'] = 'Recovered from error, ready for work'
state['last_update'] = datetime.now().isoformat()
with open('$DEVELOPER_STATE', 'w') as f:
    json.dump(state, f, indent=2)
EOF

            sleep 10
            ;;

        *)
            log_message "Unknown action: $NEXT_ACTION"
            sleep 30
            ;;
    esac

    # Update orchestrator state
    python3 << EOF
import json
from datetime import datetime
with open('$ORCHESTRATOR_STATE', 'r') as f:
    state = json.load(f)
state['iteration'] = $ITERATION
state['active_agent'] = '${NEXT_ACTION}'
state['last_update'] = datetime.now().isoformat()
with open('$ORCHESTRATOR_STATE', 'w') as f:
    json.dump(state, f, indent=2)
EOF

    ITERATION=$((ITERATION + 1))
done

log_message "❌ Max iterations ($MAX_ITERATIONS) reached"
python3 << EOF
import json
from datetime import datetime
with open('$ORCHESTRATOR_STATE', 'r') as f:
    state = json.load(f)
state['status'] = 'max_iterations'
state['message'] = 'Stopped after $MAX_ITERATIONS iterations'
state['last_update'] = datetime.now().isoformat()
with open('$ORCHESTRATOR_STATE', 'w') as f:
    json.dump(state, f, indent=2)
EOF

exit 1
