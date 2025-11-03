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
