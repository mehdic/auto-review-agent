#!/bin/bash
# Quick fix: Replace problematic scripts with file-based approach

echo "🔧 Fixing 'command too long' issue with file-based approach..."

# Backup existing scripts
if [ -f planner-loop.sh ]; then
    cp planner-loop.sh planner-loop.sh.bak
fi
if [ -f reviewer-loop.sh ]; then
    cp reviewer-loop.sh reviewer-loop.sh.bak
fi

# Create new planner-loop.sh
cat > planner-loop.sh << 'EOF'
#!/bin/bash
# Fixed planner that tells Claude to read files instead of piping content

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
PLANNER_PROMPT="$4"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🎯 PLANNER - Starting${NC}"

# Check if we need to create proposals
if [ ! -f "$PROJECT_PATH/coordination/task_proposals.json" ] || ! grep -q '"awaiting_review"' "$PROJECT_PATH/coordination/task_proposals.json" 2>/dev/null; then
    echo -e "${GREEN}Creating proposals...${NC}"
    echo ""
    echo "Telling Claude to read:"
    echo "  1. $PLANNER_PROMPT"
    echo "  2. $SPEC_FILE"
    echo ""
    
    # Start Claude and give it a simple instruction
    claude "Read these files: $PLANNER_PROMPT and $SPEC_FILE. Follow the instructions to create proposals for fixing 75 tests (108/183 passing). Write to $PROJECT_PATH/coordination/task_proposals.json with status awaiting_review"
fi

# Wait for approval
echo -e "${YELLOW}Waiting for approval...${NC}"
while true; do
    if grep -q '"approved"' "$PROJECT_PATH/coordination/task_proposals.json" 2>/dev/null; then
        echo -e "${GREEN}Approved! Starting implementation...${NC}"
        break
    fi
    echo "Checking... (every 30s)"
    sleep 30
done

# Implementation
echo -e "${GREEN}Implementing approved approach...${NC}"
claude "Read $PROJECT_PATH/coordination/task_proposals.json. Implement the approved approach to fix all 75 remaining tests in $PROJECT_PATH. Work autonomously without asking permission."

echo -e "${GREEN}✅ Complete${NC}"
EOF

# Create new reviewer-loop.sh
cat > reviewer-loop.sh << 'EOF'
#!/bin/bash
# Fixed reviewer that tells Claude to read files instead of piping content

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
REVIEWER_PROMPT="$4"

# Colors
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}✅ REVIEWER - Starting${NC}"

while true; do
  if grep -q '"awaiting_review"' "$PROJECT_PATH/coordination/task_proposals.json" 2>/dev/null; then
    echo -e "${BLUE}Found proposals to review!${NC}"
    echo "Telling Claude to read:"
    echo "  1. $REVIEWER_PROMPT"
    echo "  2. $PROJECT_PATH/coordination/task_proposals.json"
    echo "  3. $SPEC_FILE"
    echo ""
    
    # Start Claude and give it a simple instruction
    claude "Read: $REVIEWER_PROMPT, $PROJECT_PATH/coordination/task_proposals.json, and $SPEC_FILE. Evaluate proposals and update JSON with status approved and chosen_approach"
    
    echo "Review complete. Waiting 60s..."
    sleep 60
  else
    echo -e "${YELLOW}No proposals yet... (checking every 30s)${NC}"
    sleep 30
  fi
done
EOF

# Make them executable
chmod +x planner-loop.sh reviewer-loop.sh

echo "✅ Scripts updated!"
echo ""
echo "The scripts now:"
echo "  • Pass file paths to Claude instead of content"
echo "  • Avoid 'command too long' error"
echo "  • Should work with your Claude CLI"
echo ""
echo "Test with:"
echo "./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 999"
