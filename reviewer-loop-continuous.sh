#!/bin/bash
# Continuous Reviewer Loop - Monitors proposals and implementation progress
# Does NOT exit until work is complete

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
REVIEWER_PROMPT="$4"

PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"
NOTIFICATION_LOG="$PROJECT_PATH/coordination/logs/notifications.log"

# Colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$(dirname "$NOTIFICATION_LOG")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] REVIEWER: $1" | tee -a "$NOTIFICATION_LOG"
}

log_message "✅ Continuous Reviewer Starting for $FEATURE_NAME"
log_message "Will monitor until all work is complete"

# Main loop - continues until work is complete
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

        case "$STATUS" in
            awaiting_review)
                log_message "📝 Found proposals awaiting review"
                echo ""

                cd "$PROJECT_PATH"

                claude <<EOF
Read the reviewer instructions: $REVIEWER_PROMPT
Read the task proposals: $PROPOSALS_FILE
Read the specification: $SPEC_FILE

Your task: Evaluate the proposals and select the best approach.

Key criteria:
- Systematic approach to fixing all 75 failing tests
- Realistic time estimates
- Clear workstream structure
- Addresses all failure categories

Update $PROPOSALS_FILE with:
- status: "approved"
- chosen_approach: (which approach you selected)
- Add implementation_instructions with detailed steps
- Add workstream_coordination guidelines

Make your decision and update the file now.
EOF

                log_message "Review completed"
                sleep 30
                ;;

            implementing)
                log_message "⚙️  Implementation in progress - monitoring..."

                # Check progress periodically
                if [ -d "$PROJECT_PATH" ]; then
                    cd "$PROJECT_PATH"

                    # Check if any Java files were modified recently (last 10 minutes)
                    RECENT_CHANGES=$(find src -name "*.java" -mmin -10 2>/dev/null | wc -l)

                    if [ $RECENT_CHANGES -gt 0 ]; then
                        log_message "Active implementation detected: $RECENT_CHANGES files modified in last 10 min"
                    else
                        log_message "⚠️  No recent changes - implementation may be stalled"
                        log_message "Consider checking planner window for issues"
                    fi
                fi

                # Wait before next check
                sleep 120
                ;;

            completed)
                log_message "✅ Work marked as completed"
                log_message "Verifying all tests pass..."

                cd "$PROJECT_PATH"

                # Verify completion
                if mvn test -q 2>&1 | grep -q "Tests run: 183" && mvn test -q 2>&1 | grep -q "Failures: 0"; then
                    log_message "🎉 Verified: All 183 tests passing!"
                    log_message "Reviewer loop exiting - mission accomplished!"
                    exit 0
                else
                    log_message "⚠️  Status is 'completed' but tests not all passing"
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
                log_message "✓ Proposals approved - waiting for implementation to start..."
                sleep 30
                ;;

            *)
                log_message "Unknown status: $STATUS - waiting..."
                sleep 30
                ;;
        esac
    else
        log_message "No proposals file yet - waiting for planner..."
        sleep 30
    fi

done

log_message "Reviewer loop ended"
