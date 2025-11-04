#!/bin/bash
# Direct Implementation - Bypasses all state checking, just starts implementation

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 Direct Implementation Starter${NC}"
echo ""

# Verify proposals file exists
if [ ! -f "$PROPOSALS_FILE" ]; then
    echo "ERROR: Cannot find $PROPOSALS_FILE"
    exit 1
fi

echo "Starting implementation in: $PROJECT_PATH"
echo ""
echo "This will start Claude and give it the implementation task."
echo "Press Ctrl+C within 3 seconds to cancel..."
sleep 3

echo ""
echo -e "${BLUE}Starting Claude...${NC}"
echo ""

cd "$PROJECT_PATH"

claude << 'EOF'
You are implementing approved test fixes for the StockMonitor project.

First, read the proposals file:
/Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json

This file contains:
- Status (may say "implementing" or "approved")
- The chosen_approach (should be "approach_2")
- Detailed implementation_instructions with workstream structure
- Testing requirements and checkpoints

Your task:
1. Read and understand the full implementation plan from the file
2. Start with Workstream 1A + 1B (config fixes + universe/portfolio tests)
3. Run 'mvn test' to see current state (should be 108/183 passing)
4. Fix tests systematically following the workstream plan
5. Work autonomously - no need to ask permission between fixes
6. Run mvn test periodically to verify fixes
7. Continue through all workstreams until 183/183 tests pass

Key points:
- Currently 108/183 tests pass (75 failing)
- Goal is 183/183 passing
- Follow the workstream priority order in implementation_instructions
- The plan is already approved, just execute it

Start by running mvn test to see what's currently failing.
EOF

echo ""
echo -e "${GREEN}✅ Implementation started!${NC}"
echo ""
echo "Claude should now be working on the tests."
echo "To monitor progress, watch for:"
echo "  - File changes: find src -name '*.java' -mmin -5"
echo "  - Test runs: watch 'mvn test 2>&1 | tail -50'"
echo ""
