#!/bin/bash
# Generic Planner Loop - Works with ANY spec.md file (TMUX-COMPATIBLE)
# Continuously implements until all success criteria in spec are met

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
PLANNER_PROMPT="$4"

PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"
NOTIFICATION_LOG="$PROJECT_PATH/coordination/logs/notifications.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$(dirname "$NOTIFICATION_LOG")"
mkdir -p "$PROJECT_PATH/coordination/prompts"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PLANNER: $1" | tee -a "$NOTIFICATION_LOG"
}

log_message "🎯 Planner Starting for $FEATURE_NAME"
log_message "Spec: $SPEC_FILE"
log_message "Will run until all success criteria are met"

# Main loop - continues until work is complete
ITERATION=1

while true; do
    log_message "===== ITERATION $ITERATION ====="

    # Phase 1: Create proposals if they don't exist
    if [ ! -f "$PROPOSALS_FILE" ] || [ $(wc -l < "$PROPOSALS_FILE" 2>/dev/null || echo 0) -lt 10 ]; then
        log_message "Phase 1: Creating proposals..."

        cd "$PROJECT_PATH"

        # Create prompt file (tmux-compatible approach)
        PROMPT_FILE="$PROJECT_PATH/coordination/prompts/planner_prompt_$$.txt"
        cat > "$PROMPT_FILE" <<EOF
Read the planner instructions from: $PLANNER_PROMPT
Read the specification from: $SPEC_FILE

Your task is to create proposals for implementing this specification.

Analyze the specification carefully:
- Understand the current state and goals
- Identify what needs to be done
- Check the "Definition of Done" and "Success Criteria"
- Create a systematic approach to achieve those criteria

Create 2-3 different implementation approaches.
Write the proposals to: $PROPOSALS_FILE
Set status to "awaiting_review"

Be thorough and create comprehensive proposals.
EOF

        # Call claude with prompt file
        cat "$PROMPT_FILE" | claude 2>&1 | tee -a "$NOTIFICATION_LOG"

        # Clean up prompt file
        rm -f "$PROMPT_FILE"

        log_message "Proposals created, status: awaiting_review"
        sleep 10
    fi

    # Phase 2: Wait for approval
    if ! grep -q '"approved"\|"implementing"' "$PROPOSALS_FILE" 2>/dev/null; then
        log_message "Phase 2: Waiting for reviewer approval..."

        MAX_WAIT=600  # 10 minutes max wait
        WAITED=0

        while [ $WAITED -lt $MAX_WAIT ]; do
            if grep -q '"approved"\|"implementing"' "$PROPOSALS_FILE" 2>/dev/null; then
                log_message "✓ Approval detected"
                break
            fi

            if [ $((WAITED % 60)) -eq 0 ] && [ $WAITED -gt 0 ]; then
                log_message "Still waiting for approval... ($WAITED seconds)"
            fi

            sleep 10
            WAITED=$((WAITED + 10))
        done

        if ! grep -q '"approved"\|"implementing"' "$PROPOSALS_FILE" 2>/dev/null; then
            log_message "ERROR: No approval received within timeout"
            log_message "Waiting 60s before retry..."
            sleep 60
            continue
        fi
    fi

    # Phase 3: Update status to implementing
    if grep -q '"approved"' "$PROPOSALS_FILE" 2>/dev/null; then
        log_message "Phase 3: Updating status to implementing..."

        python3 -c "
import json
try:
    with open('$PROPOSALS_FILE', 'r') as f:
        data = json.load(f)
    data['status'] = 'implementing'
    with open('$PROPOSALS_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except:
    pass
" 2>/dev/null
        log_message "Status updated to implementing"
    fi

    # Phase 4: Implementation
    log_message "Phase 4: Running implementation..."

    CHOSEN_APPROACH=$(python3 -c "
import json
try:
    with open('$PROPOSALS_FILE', 'r') as f:
        data = json.load(f)
    print(data.get('chosen_approach', 'unknown'))
except:
    print('unknown')
" 2>/dev/null)

    log_message "Implementing approach: $CHOSEN_APPROACH"

    cd "$PROJECT_PATH"

    # Create implementation prompt file
    IMPL_PROMPT_FILE="$PROJECT_PATH/coordination/prompts/impl_prompt_$$.txt"
    cat > "$IMPL_PROMPT_FILE" <<EOF
You are the implementation agent.

Read the approved proposal: $PROPOSALS_FILE
Read the specification: $SPEC_FILE

CRITICAL INSTRUCTIONS:
1. Review the chosen approach ($CHOSEN_APPROACH) in the proposals file
2. Review the "Definition of Done" in the spec file
3. Implement the approach systematically
4. Work autonomously - don't ask permission between steps
5. Regularly verify progress toward completion criteria
6. Continue until ALL success criteria in the spec are met

When you believe all work is complete:
- Verify every item in "Definition of Done" is satisfied
- Run any final validation steps
- Update $PROPOSALS_FILE status to "completed"

DO NOT STOP until the specification's success criteria are fully met.

Begin implementation now.
EOF

    # Call claude with implementation prompt
    cat "$IMPL_PROMPT_FILE" | claude 2>&1 | tee -a "$NOTIFICATION_LOG"

    # Clean up
    rm -f "$IMPL_PROMPT_FILE"

    log_message "Implementation session completed"

    # Phase 5: Check completion
    log_message "Phase 5: Checking if work is complete..."

    if bash "$SCRIPT_DIR/check-completion.sh" "$PROJECT_PATH" "$SPEC_FILE" true; then
        log_message "🎉 SUCCESS! All success criteria met!"

        # Update status to completed
        python3 -c "
import json
try:
    with open('$PROPOSALS_FILE', 'r') as f:
        data = json.load(f)
    data['status'] = 'completed'
    data['completed_at'] = '$(date -Iseconds)'
    with open('$PROPOSALS_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except:
    pass
" 2>/dev/null

        log_message "Status updated to completed"
        log_message "Planner exiting - mission accomplished!"
        exit 0
    else
        log_message "Work not complete yet. Continuing..."
        log_message "Waiting 120 seconds before next iteration..."
        sleep 120
    fi

    ITERATION=$((ITERATION + 1))
done

log_message "Planner loop ended"
