#!/bin/bash
# Fixed planner that tells Claude to read files instead of piping content

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"
PLANNER_PROMPT="$4"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLM_BIN="${LLM_BIN:-codex}"
LLM_MODEL="${LLM_MODEL:-}"
if [[ -z "${LLM_ARGS:-}" && -n "${LLM_ARGS_CAUTIOUS:-}" ]]; then
    LLM_ARGS="$LLM_ARGS_CAUTIOUS"
fi
LLM_ARGS="${LLM_ARGS:-}"
export LLM_BIN LLM_MODEL LLM_ARGS
LLM_SH="$SCRIPT_DIR/scripts/llm.sh"

if ! command -v "$LLM_BIN" &> /dev/null; then
    echo "Missing LLM CLI: $LLM_BIN" >&2
    exit 1
fi
if [ ! -x "$LLM_SH" ]; then
    echo "Missing LLM shim at $LLM_SH" >&2
    exit 1
fi

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
    
    # Start LLM and give it a simple instruction
    "$LLM_SH" chat "Read these files: $PLANNER_PROMPT and $SPEC_FILE. Follow the instructions to create proposals for fixing 75 tests (108/183 passing). Write to $PROJECT_PATH/coordination/task_proposals.json with status awaiting_review"
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
"$LLM_SH" chat "Read $PROJECT_PATH/coordination/task_proposals.json. Implement the approved approach to fix all 75 remaining tests in $PROJECT_PATH. Work autonomously without asking permission."

echo -e "${GREEN}✅ Complete${NC}"
