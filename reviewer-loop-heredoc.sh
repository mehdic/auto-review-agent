#!/bin/bash
# Generic Reviewer Loop - Works with ANY spec.md file
# Monitors proposals, approves them, and tracks implementation progress

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
REVIEWER_PROMPT="$4"

PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"
NOTIFICATION_LOG="$PROJECT_PATH/coordination/logs/notifications.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$(dirname "$NOTIFICATION_LOG")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] REVIEWER: $1" | tee -a "$NOTIFICATION_LOG"
}

log_message "✅ Reviewer Starting for $FEATURE_NAME"
log_message "Spec: $SPEC_FILE"
log_message "Will monitor until all work is complete"

# Main loop - continues until work is complete
LAST_STATUS=""

while true; do

    # Check current status
    if [ -f "$PROPOSALS_FILE" ]; then
        STATUS=$(python3 -c "
import json
try:
    with open('$PROPOSALS_FILE', 'r') as f:
        data = json.load(f)
    print(data.get('status', 'unknown'))
except:
    print('unknown')
" 2>/dev/null)

        # Only log status changes to reduce noise
        if [ "$STATUS" != "$LAST_STATUS" ]; then
            log_message "Status changed: $LAST_STATUS → $STATUS"
            LAST_STATUS="$STATUS"
        fi

        case "$STATUS" in
            awaiting_review)
                log_message "📝 Reviewing proposals..."
                echo ""

                cd "$PROJECT_PATH"

                claude <<EOF
Read the reviewer instructions: $REVIEWER_PROMPT
Read the task proposals: $PROPOSALS_FILE
Read the specification: $SPEC_FILE

Your task: Evaluate the proposals and select the best approach.

Consider:
- Which approach best addresses the spec requirements?
- Are the approaches systematic and comprehensive?
- Do they address all items in "Definition of Done"?
- Are time estimates realistic?

Update $PROPOSALS_FILE with:
- status: "approved"
- chosen_approach: (which approach you selected)
- implementation_instructions: (detailed steps for implementation)
- Add any additional guidance needed

Make your decision and update the file now.
EOF

                log_message "Review completed and file updated"
                sleep 30
                ;;

            implementing)
                # Monitor implementation progress
                if [ -d "$PROJECT_PATH" ]; then
                    # Check for recent activity (files modified in last 10 min)
                    RECENT_CHANGES=$(find "$PROJECT_PATH" -type f -mmin -10 2>/dev/null | grep -v ".git" | grep -v "node_modules" | wc -l)

                    if [ $RECENT_CHANGES -gt 0 ]; then
                        if [ $((RANDOM % 10)) -eq 0 ]; then  # Log occasionally, not every loop
                            log_message "Implementation active: $RECENT_CHANGES files modified recently"
                        fi
                    else
                        log_message "⚠️  No recent file changes - implementation may be idle"
                    fi
                fi

                # Wait before next check
                sleep 120
                ;;

            completed)
                log_message "✅ Status marked as 'completed' - verifying..."

                # Verify completion using check-completion.sh
                if bash "$SCRIPT_DIR/check-completion.sh" "$PROJECT_PATH" "$SPEC_FILE" true; then
                    log_message "🎉 VERIFIED: All success criteria met!"
                    log_message "Reviewer exiting - mission accomplished!"
                    exit 0
                else
                    log_message "⚠️  Status is 'completed' but success criteria not met"
                    log_message "Resetting status to 'implementing' to continue work"

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
                fi

                sleep 60
                ;;

            approved)
                if [ $((RANDOM % 10)) -eq 0 ]; then  # Log occasionally
                    log_message "Waiting for implementation to start..."
                fi
                sleep 30
                ;;

            unknown|*)
                if [ -s "$PROPOSALS_FILE" ]; then
                    log_message "Unknown status: $STATUS"
                fi
                sleep 30
                ;;
        esac
    else
        # No proposals file yet
        sleep 30
    fi

done

log_message "Reviewer loop ended"
