#!/bin/bash
# Force Implementation Script - For when approved but not implementing

PROJECT_PATH="/Users/mchaouachi/IdeaProjects/StockMonitor"
AGENT_SYSTEM="/Users/mchaouachi/agent-system"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔨 Force Implementation Script${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

STATUS=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('status', 'unknown'))" 2>/dev/null)
CHOSEN=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('chosen_approach', 'none'))" 2>/dev/null)

echo "Current status: $STATUS"
echo "Chosen approach: $CHOSEN"
echo ""

if [ "$STATUS" != "approved" ]; then
    echo -e "${RED}Status is not approved. This script is for approved but stuck implementations.${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking planner window state...${NC}"

PLANNER_STATE=$(tmux capture-pane -t agent_system_spec:planner -p 2>/dev/null | tail -10)
echo "Planner window last 10 lines:"
echo "────────────────────────────────"
echo "$PLANNER_STATE"
echo "────────────────────────────────"

if [[ "$PLANNER_STATE" == *"Waiting"* ]] || [[ "$PLANNER_STATE" == *"waiting"* ]]; then
    echo -e "${YELLOW}Planner is stuck waiting. Breaking the loop...${NC}"
    tmux send-keys -t agent_system_spec:planner C-c
    sleep 2
fi

if [[ "$PLANNER_STATE" == *"$"* ]] || [[ "$PLANNER_STATE" == *"#"* ]] || [[ "$PLANNER_STATE" == *"%"* ]]; then
    echo -e "${YELLOW}Planner at command prompt. Starting Claude...${NC}"
    NEEDS_CLAUDE=1
elif [[ "$PLANNER_STATE" == *"claude"* ]] && [[ "$PLANNER_STATE" != *"implementation"* ]]; then
    echo -e "${YELLOW}Claude is running but not implementing. Sending instructions...${NC}"
    NEEDS_INSTRUCTIONS=1
else
    echo -e "${YELLOW}Unknown state. Will try to start implementation...${NC}"
    NEEDS_CLAUDE=1
fi

echo ""
echo -e "${GREEN}Forcing implementation to start...${NC}"

if [ "$NEEDS_CLAUDE" == "1" ]; then
    echo "Starting Claude..."
    tmux send-keys -t agent_system_spec:planner "cd $PROJECT_PATH" Enter
    sleep 1
    tmux send-keys -t agent_system_spec:planner "claude" Enter
    sleep 4
fi

echo "Sending implementation instructions..."
tmux send-keys -t agent_system_spec:planner "
The task proposals at $PROPOSALS_FILE show status: approved with $CHOSEN selected.

Read the file to see the implementation plan. The approach includes 10 phases for fixing tests:

Phase 1: Batch Processing Fixes (14 tests)
Phase 2: WebSocket Manager Fixes (12 tests)
Phase 3: NPE Fixes (8 tests)
Phase 4: Thread Safety (6 tests)
Phase 5: Error Message Fixes (5 tests)
Phase 6: Validation Logic (10 tests)
Phase 7: Historical Data Tests (8 tests)
Phase 8: Configuration Tests (5 tests)
Phase 9: Alert System Tests (5 tests)
Phase 10: Edge Cases (2 tests)

Current state: 108/183 tests passing (87 unit + 21 integration)
Goal: Fix all 75 failing tests

Start with Phase 1. Run mvn test to see current failures.
Fix the tests systematically.
Work autonomously without asking permission between fixes.
Continue until all 183 tests pass.

Begin implementation now." Enter

echo ""
echo -e "${GREEN}✅ Implementation command sent!${NC}"
echo ""
echo "Wait 30 seconds then check:"
echo "1. tmux attach -t agent_system_spec"
echo "2. Press Ctrl+b 0 to see planner"
echo "3. Claude should be implementing"
echo ""
echo "To verify it's working:"
echo "watch -n 5 'find $PROJECT_PATH -name \"*.java\" -mmin -5 | head -10'"
echo ""
echo "If still not working, try the nuclear option:"
echo "tmux kill-window -t agent_system_spec:planner"
echo "tmux new-window -t agent_system_spec:planner -n planner -c $PROJECT_PATH"
echo "tmux send-keys -t agent_system_spec:planner 'claude' Enter"
echo "Then paste the implementation instructions again."
