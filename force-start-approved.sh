#!/bin/bash
# Force Start Implementation - For when reviewer has approved but planner isn't implementing

PROJECT_PATH="/Users/mchaouachi/IdeaProjects/StockMonitor"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 Checking Current Status...${NC}"

# Check if proposals file exists and has approved status
if [ ! -f "$PROPOSALS_FILE" ]; then
    echo -e "${RED}No proposals file found!${NC}"
    exit 1
fi

STATUS=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('status', 'unknown'))" 2>/dev/null)
CHOSEN=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('chosen_approach', 'unknown'))" 2>/dev/null)

echo "Current Status: $STATUS"
echo "Chosen Approach: $CHOSEN"

if [ "$STATUS" != "approved" ]; then
    echo -e "${RED}Status is not 'approved'. Current status: $STATUS${NC}"
    echo "This script is for when reviewer has approved but planner isn't implementing."
    exit 1
fi

echo -e "${GREEN}✓ Status is approved with $CHOSEN${NC}"
echo ""
echo -e "${YELLOW}Starting implementation immediately...${NC}"

# Kill any waiting planner process
tmux send-keys -t agent_system_spec:planner C-c 2>/dev/null
sleep 1

# Update status to implementing
echo -e "${BLUE}Updating status to 'implementing'...${NC}"
python3 -c "
import json
with open('$PROPOSALS_FILE', 'r') as f:
    data = json.load(f)
data['status'] = 'implementing'
data['implementation_started_at'] = '$(date -Iseconds)'
with open('$PROPOSALS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
print('Status updated to implementing')
"

# Start Claude in planner window with implementation instructions
echo -e "${BLUE}Launching implementation in planner window...${NC}"

tmux send-keys -t agent_system_spec:planner "cd $PROJECT_PATH" Enter
sleep 1

tmux send-keys -t agent_system_spec:planner "claude" Enter
sleep 4

# Send comprehensive implementation instructions
tmux send-keys -t agent_system_spec:planner "You are the implementation agent.

The proposals at $PROPOSALS_FILE have been APPROVED by the reviewer.
Status: approved
Chosen approach: $CHOSEN

The reviewer stated: 'The implementation agent can now proceed with executing Approach 2.'

Review the file to see:
- implementation_instructions with priority order
- testing_requirements with checkpoints  
- workstream_coordination guidelines
- specification_review summary

According to the approval, the workstream structure is:
1. Workstream 1A + 1B (PARALLEL START - CRITICAL): Config fixes + Universe/Portfolio (20h, 27 tests)
2. Workstream 2A + 2B (After 1B): Reports + Recommendations (16h, 26 tests)
3. Workstream 3 (After 1B, 2A): Onboarding + Integration (9h, 5 tests)
4. Workstream 4 (After 2B): Remaining contracts (12h, 16 tests)

Total: 30-36 hours to achieve 183/183 tests passing

Your task:
1. Start with Workstream 1A + 1B as indicated
2. Fix the 75 failing tests systematically
3. Currently 108/183 tests pass
4. Work autonomously - no permission needed between fixes
5. Run 'mvn test' to check progress periodically
6. Continue until all 183 tests pass

Begin implementation NOW. Start by running:
mvn test | grep 'Tests run'

Then fix tests according to the workstream order." Enter

echo ""
echo -e "${GREEN}✅ Implementation instructions sent!${NC}"
echo ""
echo -e "${BLUE}The planner should now be implementing.${NC}"
echo ""
echo "To verify:"
echo "1. tmux attach -t agent_system_spec"
echo "2. Press Ctrl+b 0 (planner window)"
echo "3. You should see Claude working on tests"
echo ""
echo "To check if files are being modified:"
echo "watch -n 5 'find $PROJECT_PATH -name \"*.java\" -mmin -5'"
echo ""
echo -e "${YELLOW}Note: The implementation will take time. Let it work autonomously.${NC}"
