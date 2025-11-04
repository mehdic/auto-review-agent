#!/bin/bash
# Wake up the existing planner in tmux and tell it to implement

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔔 Waking Up Existing Planner${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if tmux session exists
if ! tmux has-session -t agent_system_spec 2>/dev/null; then
    echo -e "${RED}ERROR: No tmux session 'agent_system_spec' found${NC}"
    echo "Your agents aren't running in tmux."
    echo ""
    echo "Check with: tmux list-sessions"
    exit 1
fi

echo "✓ Found tmux session: agent_system_spec"

# Check if planner window exists
if ! tmux list-windows -t agent_system_spec 2>/dev/null | grep -q "planner"; then
    echo -e "${RED}ERROR: No 'planner' window in tmux session${NC}"
    echo ""
    echo "Available windows:"
    tmux list-windows -t agent_system_spec
    exit 1
fi

echo "✓ Found planner window"
echo ""

# Show current state
echo "Current planner window state (last 10 lines):"
echo "────────────────────────────────────────"
tmux capture-pane -t agent_system_spec:planner -p 2>/dev/null | tail -10
echo "────────────────────────────────────────"
echo ""

# Get chosen approach
if [ -f "$PROPOSALS_FILE" ]; then
    CHOSEN=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('chosen_approach', 'unknown'))" 2>/dev/null)
    echo "Chosen approach: $CHOSEN"
else
    echo -e "${RED}ERROR: Cannot find $PROPOSALS_FILE${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Sending implementation command to existing planner window...${NC}"
echo ""

# First, try to interrupt anything that might be stuck
tmux send-keys -t agent_system_spec:planner C-c
sleep 2

# Check if Claude is already running in that window
WINDOW_STATE=$(tmux capture-pane -t agent_system_spec:planner -p 2>/dev/null | tail -5)

if echo "$WINDOW_STATE" | grep -q "claude>"; then
    echo "Claude is already running in planner window - sending instructions directly..."

    # Send instructions to existing Claude session
    tmux send-keys -t agent_system_spec:planner "Read the file: $PROPOSALS_FILE"
    tmux send-keys -t agent_system_spec:planner Enter
    sleep 2
    tmux send-keys -t agent_system_spec:planner "The status is 'implementing' and chosen_approach is '$CHOSEN'. Implement the approved plan. Start by running mvn test in $PROJECT_PATH to see current failures. Then fix tests systematically according to the workstream structure in the file. Work autonomously until all 183 tests pass."
    tmux send-keys -t agent_system_spec:planner Enter

elif echo "$WINDOW_STATE" | grep -qE "\$|#|%"; then
    echo "Planner is at shell prompt - starting Claude..."

    # Start Claude
    tmux send-keys -t agent_system_spec:planner "cd $PROJECT_PATH"
    tmux send-keys -t agent_system_spec:planner Enter
    sleep 1
    tmux send-keys -t agent_system_spec:planner "claude"
    tmux send-keys -t agent_system_spec:planner Enter
    sleep 3

    # Send instructions
    tmux send-keys -t agent_system_spec:planner "Read the proposals file: $PROPOSALS_FILE"
    tmux send-keys -t agent_system_spec:planner Enter
    sleep 2
    tmux send-keys -t agent_system_spec:planner "Status is 'implementing' with chosen_approach '$CHOSEN'. Implement the approved plan to fix all 75 failing tests. Start by running mvn test to see failures, then fix systematically. Work autonomously."
    tmux send-keys -t agent_system_spec:planner Enter

else
    echo "Unknown state - will try to reset and start..."

    # Reset the window
    tmux send-keys -t agent_system_spec:planner C-c C-c
    sleep 2
    tmux send-keys -t agent_system_spec:planner Enter
    sleep 1

    # Start Claude
    tmux send-keys -t agent_system_spec:planner "cd $PROJECT_PATH"
    tmux send-keys -t agent_system_spec:planner Enter
    sleep 1
    tmux send-keys -t agent_system_spec:planner "claude"
    tmux send-keys -t agent_system_spec:planner Enter
    sleep 3

    # Send instructions
    tmux send-keys -t agent_system_spec:planner "Read $PROPOSALS_FILE and implement the approved $CHOSEN plan. Start with mvn test in $PROJECT_PATH then fix all 75 failing tests autonomously."
    tmux send-keys -t agent_system_spec:planner Enter
fi

echo ""
echo -e "${GREEN}✅ Commands sent to existing planner window!${NC}"
echo ""
echo "To monitor:"
echo "  tmux attach -t agent_system_spec"
echo "  (Then press Ctrl+b 0 to see planner window)"
echo ""
echo "To detach: Ctrl+b d"
echo ""
echo "Verify implementation started:"
echo "  # Wait 30-60 seconds, then:"
echo "  find $PROJECT_PATH/src -name '*.java' -mmin -5 | head"
echo ""
