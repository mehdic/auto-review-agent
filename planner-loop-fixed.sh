#!/bin/bash
# Fixed Planner Loop - Properly handles approval and continues to implementation

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
PLANNER_PROMPT="$4"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"
NOTIFICATION_LOG="$PROJECT_PATH/coordination/logs/notifications.log"

# Ensure log directory exists
mkdir -p "$(dirname "$NOTIFICATION_LOG")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PLANNER: $1" | tee -a "$NOTIFICATION_LOG"
}

log_message "Planner starting for $FEATURE_NAME"

# Phase 1: Create proposals if they don't exist or are idle
if [ ! -f "$PROPOSALS_FILE" ] || grep -q '"idle"' "$PROPOSALS_FILE" 2>/dev/null || [ $(grep -c "proposals" "$PROPOSALS_FILE" 2>/dev/null || echo 0) -eq 0 ]; then
    log_message "Creating proposals..."
    
    # Start Claude to create proposals
    claude <<EOF
Read the planner instructions from: $PLANNER_PROMPT
Read the specification from: $SPEC_FILE

Your task is to create proposals for implementing this specification.
Write the proposals to: $PROPOSALS_FILE
Set status to "awaiting_review"
Include at least 2-3 different approaches.

Create the proposals now.
EOF
    
    log_message "Proposals creation completed"
fi

# Phase 2: Wait for approval
log_message "Waiting for reviewer approval..."
MAX_WAIT=300  # 5 minutes max wait
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    if grep -q '"approved"' "$PROPOSALS_FILE" 2>/dev/null; then
        log_message "Approval detected!"
        break
    fi
    
    # Show waiting status every 30 seconds
    if [ $((WAITED % 30)) -eq 0 ]; then
        log_message "Still waiting for approval... ($WAITED seconds)"
    fi
    
    sleep 10
    WAITED=$((WAITED + 10))
done

# Phase 3: Implementation
if grep -q '"approved"' "$PROPOSALS_FILE" 2>/dev/null; then
    log_message "Starting implementation phase..."
    
    # Get the chosen approach
    CHOSEN_APPROACH=$(grep -o '"chosen_approach"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROPOSALS_FILE" | cut -d'"' -f4)
    log_message "Implementing $CHOSEN_APPROACH"
    
    # Update status to implementing
    python3 -c "
import json
with open('$PROPOSALS_FILE', 'r') as f:
    data = json.load(f)
data['status'] = 'implementing'
with open('$PROPOSALS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
    
    log_message "Status updated to implementing"
    
    # Start implementation with Claude
    cd "$PROJECT_PATH"
    
    claude <<EOF
You are the implementation agent.

Read the approved proposal from: $PROPOSALS_FILE

The proposal has been approved with chosen_approach: $CHOSEN_APPROACH

Review the implementation_instructions and workstream_coordination in the file.

Your task:
1. Implement the chosen approach to fix all failing tests
2. Currently 108/183 tests pass (75 need fixing)
3. Work autonomously - don't ask for permission between fixes
4. Follow the workstream structure in the proposal
5. Start with Workstream 1A + 1B as indicated
6. Run mvn test periodically to check progress
7. Continue until all 183 tests pass

Begin implementation now. Start by running mvn test to see current failures.
EOF
    
    log_message "Implementation session started"
    
else
    log_message "ERROR: Approval not received within timeout period"
    log_message "Please check reviewer status"
fi

log_message "Planner loop completed"
