#!/bin/bash
# Nuclear Option - Force implementation regardless of current status

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}☢️  NUCLEAR FIX - Forcing Implementation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if proposals file exists
if [ ! -f "$PROPOSALS_FILE" ]; then
    echo -e "${RED}ERROR: Proposals file not found at $PROPOSALS_FILE${NC}"
    exit 1
fi

# Get current state
echo "📊 Current State:"
STATUS=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('status', 'unknown'))" 2>/dev/null)
CHOSEN=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('chosen_approach', 'none'))" 2>/dev/null)

echo "   Status: $STATUS"
echo "   Chosen approach: $CHOSEN"
echo ""

if [ "$CHOSEN" == "none" ] || [ -z "$CHOSEN" ]; then
    echo -e "${RED}ERROR: No chosen approach found in proposals!${NC}"
    exit 1
fi

# Option 1: Try to use existing tmux session
echo -e "${BLUE}Step 1: Checking tmux session...${NC}"
if tmux has-session -t agent_system_spec 2>/dev/null; then
    echo "   ✓ Session exists"

    # Check if planner window exists
    if tmux list-windows -t agent_system_spec | grep -q "planner"; then
        echo "   ✓ Planner window exists"
        echo ""
        echo -e "${YELLOW}Killing any stuck processes in planner window...${NC}"
        tmux send-keys -t agent_system_spec:planner C-c C-c C-c
        sleep 2
    else
        echo "   ⚠ Planner window missing, creating..."
        tmux new-window -t agent_system_spec -n planner -c "$PROJECT_PATH"
    fi
else
    echo "   ⚠ No tmux session, will use direct Claude call"
    DIRECT_CALL=1
fi

echo ""
echo -e "${GREEN}Step 2: Starting Implementation...${NC}"
echo ""

# Create the implementation prompt
IMPL_PROMPT="You are implementing the approved test fixes for StockMonitor project.

Read the approved proposal: $PROPOSALS_FILE

Key Information:
- Status: $STATUS (we're forcing implementation)
- Chosen approach: $CHOSEN
- Current state: 108/183 tests passing
- Goal: Fix all 75 failing tests

The proposals file contains detailed implementation_instructions with a workstream structure.

Your task:
1. Read the proposals file to understand the full plan
2. Start with the first workstream (usually config fixes + universe/portfolio tests)
3. Run 'mvn test' to see current failures
4. Fix tests systematically according to the workstream plan
5. Work autonomously - don't ask permission between fixes
6. Run mvn test periodically to track progress
7. Continue until all 183 tests pass

Begin implementation NOW. Start by running mvn test to assess the current failures."

if [ "$DIRECT_CALL" == "1" ]; then
    # Direct Claude call
    echo "Starting Claude directly..."
    cd "$PROJECT_PATH"
    echo "$IMPL_PROMPT" | claude
else
    # Use tmux
    echo "Sending commands to tmux planner window..."
    tmux send-keys -t agent_system_spec:planner "cd $PROJECT_PATH" Enter
    sleep 1
    tmux send-keys -t agent_system_spec:planner "claude" Enter
    sleep 3

    # Send the prompt
    tmux send-keys -t agent_system_spec:planner "$IMPL_PROMPT" Enter

    echo ""
    echo -e "${GREEN}✅ Implementation command sent to tmux!${NC}"
    echo ""
    echo "Monitor progress:"
    echo "   tmux attach -t agent_system_spec"
    echo "   (Press Ctrl+b 0 to switch to planner window)"
    echo ""
    echo "To detach from tmux: Ctrl+b d"
fi

echo ""
echo -e "${BLUE}Step 3: Verification${NC}"
echo ""
echo "Wait 30-60 seconds, then verify implementation is running:"
echo ""
echo "1. Check Claude is active:"
echo "   ps aux | grep claude | grep -v grep"
echo ""
echo "2. Check for recent file changes:"
echo "   find $PROJECT_PATH/src -name '*.java' -mmin -5 | head"
echo ""
echo "3. Check logs:"
echo "   tail -f $PROJECT_PATH/coordination/logs/notifications.log"
echo ""
echo "4. Monitor tests (in another terminal):"
echo "   cd $PROJECT_PATH && watch -n 60 'mvn test 2>&1 | grep -E \"Tests run|BUILD\"'"
echo ""
