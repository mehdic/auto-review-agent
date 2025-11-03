#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Launching Autonomous Agent System from Spec File${NC}"
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Usage: ./launch-agents-from-spec.sh /path/to/your/project [feature-number]${NC}"
    exit 1
fi

PROJECT_PATH="$1"
FEATURE_NUM="${2:-999}"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}❌ Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

# Find spec file
SPEC_FILE="$PROJECT_PATH/specs/$FEATURE_NUM-fix-remaining-tests/spec.md"
if [ ! -f "$SPEC_FILE" ]; then
    # Try generic pattern
    SPEC_FOLDER=$(ls -d "$PROJECT_PATH/specs/$FEATURE_NUM"* 2>/dev/null | head -1)
    if [ -n "$SPEC_FOLDER" ]; then
        SPEC_FILE="$SPEC_FOLDER/spec.md"
    fi
fi

if [ ! -f "$SPEC_FILE" ]; then
    echo -e "${RED}❌ Spec file not found for feature $FEATURE_NUM${NC}"
    exit 1
fi

FEATURE_NAME=$(basename $(dirname "$SPEC_FILE"))
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
PLANNER_PROMPT="$SCRIPT_DIR/prompts/planner_agent_spec.txt"
REVIEWER_PROMPT="$SCRIPT_DIR/prompts/reviewer_agent_spec.txt"
LLM_BIN="${LLM_BIN:-codex}"
LLM_MODEL="${LLM_MODEL:-}"
if [[ -z "${LLM_ARGS:-}" && -n "${LLM_ARGS_CAUTIOUS:-}" ]]; then
    LLM_ARGS="$LLM_ARGS_CAUTIOUS"
fi
LLM_ARGS="${LLM_ARGS:-}"
export LLM_BIN LLM_MODEL LLM_ARGS
LLM_SH="$SCRIPT_DIR/scripts/llm.sh"

if ! command -v "$LLM_BIN" &> /dev/null; then
    echo -e "${RED}❌ $LLM_BIN CLI is not installed.${NC}"
    exit 1
fi
if [ ! -x "$LLM_SH" ]; then
    echo -e "${RED}❌ LLM shim not found at $LLM_SH.${NC}"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  Project: $PROJECT_PATH"
echo "  Feature: $FEATURE_NAME"
echo "  Spec File: $SPEC_FILE"
echo ""

SESSION_NAME="agent_system_spec"

# Kill existing session if it exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Existing session found. Killing it...${NC}"
    tmux kill-session -t $SESSION_NAME
fi

echo -e "${GREEN}Creating tmux session: $SESSION_NAME${NC}"

# Create tmux session
tmux new-session -d -s $SESSION_NAME -n planner -c "$PROJECT_PATH"
tmux new-window -t $SESSION_NAME -n reviewer -c "$PROJECT_PATH"
tmux new-window -t $SESSION_NAME -n monitor -c "$PROJECT_PATH"

# Start planner using the loop script
echo -e "${GREEN}Starting Planner Agent...${NC}"
if [ -f "$SCRIPT_DIR/planner-loop.sh" ]; then
    chmod +x "$SCRIPT_DIR/planner-loop.sh"
    tmux send-keys -t $SESSION_NAME:planner "$SCRIPT_DIR/planner-loop.sh '$PROJECT_PATH' '$SPEC_FILE' '$FEATURE_NAME' '$PLANNER_PROMPT'" Enter
else
    # Fallback: Start LLM repl and send a simple file-based command
    tmux send-keys -t $SESSION_NAME:planner "$LLM_SH" Space "repl" Enter
    sleep 2
    tmux send-keys -t $SESSION_NAME:planner "Read $PLANNER_PROMPT and $SPEC_FILE. Create proposals in $PROJECT_PATH/coordination/task_proposals.json" Enter
fi

# Start reviewer using the loop script
echo -e "${GREEN}Starting Reviewer Agent...${NC}"
if [ -f "$SCRIPT_DIR/reviewer-loop.sh" ]; then
    chmod +x "$SCRIPT_DIR/reviewer-loop.sh"
    tmux send-keys -t $SESSION_NAME:reviewer "$SCRIPT_DIR/reviewer-loop.sh '$PROJECT_PATH' '$SPEC_FILE' '$FEATURE_NAME' '$REVIEWER_PROMPT'" Enter
else
    # Fallback: Simple monitoring loop
    tmux send-keys -t $SESSION_NAME:reviewer "echo 'Reviewer waiting...'; sleep 5; echo 'Check proposals manually'" Enter
fi

# Start monitor with simple loop
echo -e "${GREEN}Starting Monitor...${NC}"
if [ -f "$SCRIPT_DIR/monitor-loop.sh" ]; then
    chmod +x "$SCRIPT_DIR/monitor-loop.sh"
    tmux send-keys -t $SESSION_NAME:monitor "$SCRIPT_DIR/monitor-loop.sh '$PROJECT_PATH'" Enter
else
    # Fallback: Simple monitor
    tmux send-keys -t $SESSION_NAME:monitor "watch -n 2 'cat $PROJECT_PATH/coordination/task_proposals.json 2>/dev/null | head -20'" Enter
fi

echo -e "${GREEN}✅ Session started: $SESSION_NAME${NC}"
echo ""
echo -e "${YELLOW}💡 Controls:${NC}"
echo "  Ctrl+b 0  → Planner window"
echo "  Ctrl+b 1  → Reviewer window"
echo "  Ctrl+b 2  → Monitor window"
echo "  Ctrl+b d  → Detach from session"
echo ""

# Attach to the session
tmux attach-session -t $SESSION_NAME
