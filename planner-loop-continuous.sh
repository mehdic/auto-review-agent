#!/bin/bash
# Continuous Planner Loop - Runs until all tasks in spec are complete
# Does NOT exit until 183/183 tests pass

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
PLANNER_PROMPT="$4"

PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"
NOTIFICATION_LOG="$PROJECT_PATH/coordination/logs/notifications.log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$(dirname "$NOTIFICATION_LOG")"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PLANNER: $1" | tee -a "$NOTIFICATION_LOG"
}

check_completion() {
    # Check if all tests are passing
    if [ -d "$PROJECT_PATH" ]; then
        cd "$PROJECT_PATH"

        # Run tests and capture result
        log_message "Checking test status..."

        # Try to get test count from latest maven run
        if mvn test -q 2>&1 | grep -q "Tests run:"; then
            TEST_OUTPUT=$(mvn test -q 2>&1 | grep "Tests run:" | tail -1)
            log_message "Test output: $TEST_OUTPUT"

            # Check if we see "Tests run: 183" and "Failures: 0"
            if echo "$TEST_OUTPUT" | grep -q "Tests run: 183" && echo "$TEST_OUTPUT" | grep -q "Failures: 0"; then
                log_message "🎉 SUCCESS! All 183 tests passing!"
                return 0
            fi
        fi
    fi

    return 1
}

log_message "🎯 Continuous Planner Starting for $FEATURE_NAME"
log_message "Will not exit until 183/183 tests pass"

# Main loop - continues until work is complete
while true; do

    # Phase 1: Create proposals if they don't exist
    if [ ! -f "$PROPOSALS_FILE" ] || [ $(wc -l < "$PROPOSALS_FILE" 2>/dev/null || echo 0) -lt 10 ]; then
        log_message "Phase 1: Creating proposals..."

        cd "$PROJECT_PATH"

        claude <<EOF
Read the planner instructions from: $PLANNER_PROMPT
Read the specification from: $SPEC_FILE

Your task is to create proposals for implementing this specification.

Key information from spec:
- Current state: 108/183 tests passing (75 failing)
- Goal: 183/183 tests passing
- Definition of Done: All 183 tests passing consistently

Create 2-3 different approaches for fixing all 75 failing tests.
Write the proposals to: $PROPOSALS_FILE
Set status to "awaiting_review"

Analyze the test failures systematically and create comprehensive proposals.
EOF

        log_message "Proposals created, status: awaiting_review"
    fi

    # Phase 2: Wait for approval
    log_message "Phase 2: Waiting for reviewer approval..."

    MAX_WAIT=600  # 10 minutes max wait for approval
    WAITED=0

    while [ $WAITED -lt $MAX_WAIT ]; do
        if grep -q '"approved"' "$PROPOSALS_FILE" 2>/dev/null || grep -q '"implementing"' "$PROPOSALS_FILE" 2>/dev/null; then
            log_message "✓ Approval detected or already implementing"
            break
        fi

        if [ $((WAITED % 60)) -eq 0 ]; then
            log_message "Still waiting for approval... ($WAITED seconds)"
        fi

        sleep 10
        WAITED=$((WAITED + 10))
    done

    if ! grep -q '"approved"' "$PROPOSALS_FILE" 2>/dev/null && ! grep -q '"implementing"' "$PROPOSALS_FILE" 2>/dev/null; then
        log_message "ERROR: No approval received within timeout"
        log_message "Waiting 60s before retry..."
        sleep 60
        continue
    fi

    # Phase 3: Implementation - This is the key part that needs to keep running
    log_message "Phase 3: Starting/continuing implementation..."

    # Update status to implementing if not already
    if grep -q '"approved"' "$PROPOSALS_FILE" 2>/dev/null; then
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

    # Get chosen approach
    CHOSEN_APPROACH=$(python3 -c "
import json
try:
    with open('$PROPOSALS_FILE', 'r') as f:
        data = json.load(f)
    print(data.get('chosen_approach', 'approach_1'))
except:
    print('approach_1')
" 2>/dev/null)

    log_message "Implementing $CHOSEN_APPROACH"

    # Start implementation session
    cd "$PROJECT_PATH"

    claude <<EOF
You are the implementation agent working on StockMonitor test fixes.

Read the approved proposal: $PROPOSALS_FILE
Read the specification: $SPEC_FILE

CRITICAL REQUIREMENTS:
- Current state: 108/183 tests passing
- Goal: 183/183 tests passing (all 75 failing tests fixed)
- You MUST continue until this goal is achieved

Implementation Instructions:
1. Read the proposals file to see the detailed plan for $CHOSEN_APPROACH
2. Run 'mvn test' to see current failures
3. Fix tests systematically according to the workstream plan
4. Run 'mvn test' after each significant change to verify progress
5. Work autonomously - don't ask permission between fixes
6. Continue fixing until you see "Tests run: 183, Failures: 0"
7. When all tests pass, update $PROPOSALS_FILE status to "completed"

DO NOT STOP until all 183 tests pass. This is critical.

Start by running mvn test to assess current state.
EOF

    log_message "Implementation session completed"

    # Phase 4: Check if we're done
    log_message "Phase 4: Checking completion status..."

    if check_completion; then
        log_message "🎉 All tests passing! Work complete!"

        # Update status to completed
        python3 -c "
import json
try:
    with open('$PROPOSALS_FILE', 'r') as f:
        data = json.load(f)
    data['status'] = 'completed'
    with open('$PROPOSALS_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except:
    pass
" 2>/dev/null

        log_message "Status updated to completed"
        log_message "Planner loop exiting - mission accomplished!"
        exit 0
    else
        log_message "Tests not all passing yet. Continuing implementation..."
        log_message "Waiting 120 seconds before next implementation round..."
        sleep 120
    fi

done

log_message "Planner loop ended"
