#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Launching Autonomous Agent System (STRICT MODE)${NC}"
echo ""

# Parse arguments
PROJECT_PATH=""
TASK=""
RESUME_SESSION=false
SESSION_ID=""
USE_STRICT_MODE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --resume)
            RESUME_SESSION=true
            SESSION_ID="$2"
            shift 2
            ;;
        --continue)
            RESUME_SESSION=true
            shift
            ;;
        --standard)
            USE_STRICT_MODE=false
            shift
            ;;
        *)
            if [ -z "$PROJECT_PATH" ]; then
                PROJECT_PATH="$1"
            elif [ -z "$TASK" ]; then
                TASK="$1"
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$PROJECT_PATH" ]; then
    echo -e "${RED}Usage: ./launch-agents-strict.sh [OPTIONS] /path/to/project [task_description]${NC}"
    echo ""
    echo "Options:"
    echo "  --continue              Resume the most recent session"
    echo "  --resume SESSION_ID     Resume a specific session"
    echo "  --standard              Use standard mode (not strict)"
    echo ""
    echo "Examples:"
    echo "  # New task with strict mode"
    echo "  ./launch-agents-strict.sh ~/my-project 'Add authentication'"
    echo ""
    echo "  # Resume last session"
    echo "  ./launch-agents-strict.sh --continue ~/my-project"
    echo ""
    echo "  # Use task list from tasks.md"
    echo "  ./launch-agents-strict.sh ~/my-project 'Follow tasks in tasks.md'"
    exit 1
fi

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}❌ Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

# Check if coordination directory exists
if [ ! -d "$PROJECT_PATH/coordination" ]; then
    echo -e "${YELLOW}⚠️  Coordination directory not found. Run setup.sh first!${NC}"
    echo "Run: ./setup.sh $PROJECT_PATH"
    exit 1
fi

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# Select prompts based on mode
if [ "$USE_STRICT_MODE" = true ]; then
    PLANNER_PROMPT="$SCRIPT_DIR/prompts/planner_agent_strict.txt"
    REVIEWER_PROMPT="$SCRIPT_DIR/prompts/reviewer_agent_strict.txt"
    MODE_LABEL="STRICT MODE"
else
    PLANNER_PROMPT="$SCRIPT_DIR/prompts/planner_agent.txt"
    REVIEWER_PROMPT="$SCRIPT_DIR/prompts/reviewer_agent.txt"
    MODE_LABEL="STANDARD MODE"
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  Mode: $MODE_LABEL"
echo "  Project: $PROJECT_PATH"
echo "  Planner prompt: $PLANNER_PROMPT"
echo "  Reviewer prompt: $REVIEWER_PROMPT"

if [ "$RESUME_SESSION" = true ]; then
    echo "  Resume: YES"
    [ -n "$SESSION_ID" ] && echo "  Session ID: $SESSION_ID"
else
    echo "  Task: ${TASK:-Check tasks.md file}"
fi

# Check if tasks.md exists
if [ -f "$PROJECT_PATH/tasks.md" ]; then
    TASK_COUNT=$(grep -c "^[0-9]\+\." "$PROJECT_PATH/tasks.md" 2>/dev/null || echo "0")
    echo -e "${CYAN}  📋 Found tasks.md with $TASK_COUNT tasks${NC}"
fi

echo ""

# Check prerequisites
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux is not installed.${NC}"
    exit 1
fi

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

SESSION_NAME="agent_system"

# Kill existing session if it exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Existing session found. Killing it...${NC}"
    tmux kill-session -t $SESSION_NAME
fi

echo -e "${GREEN}Creating tmux session: $SESSION_NAME${NC}"
echo ""

# Create tmux session with planner agent
tmux new-session -d -s $SESSION_NAME -n planner -c "$PROJECT_PATH"
tmux select-pane -t $SESSION_NAME:planner -T "🎯 PLANNER AGENT (STRICT)"

# Create reviewer window
tmux new-window -t $SESSION_NAME -n reviewer -c "$PROJECT_PATH"
tmux select-pane -t $SESSION_NAME:reviewer -T "✅ REVIEWER AGENT (STRICT)"

# Create monitor window
tmux new-window -t $SESSION_NAME -n monitor -c "$PROJECT_PATH"
tmux select-pane -t $SESSION_NAME:monitor -T "📊 MONITORING"

# Create logs window
tmux new-window -t $SESSION_NAME -n logs -c "$PROJECT_PATH"
tmux select-pane -t $SESSION_NAME:logs -T "📝 LOGS"

echo -e "${YELLOW}Setting up agents in STRICT MODE...${NC}"

join_args() {
    local out=()
    for arg in "$@"; do
        out+=("$(printf '%q' "$arg")")
    done
    printf '%s' "${out[*]}"
}

# Prepare planner command
PLANNER_CMD=("$LLM_SH" repl --project .)
if [ "$RESUME_SESSION" = true ]; then
    if [ -n "$SESSION_ID" ]; then
        PLANNER_CMD+=(--resume "$SESSION_ID")
    else
        PLANNER_CMD+=(--continue)
    fi
fi
PLANNER_CMD_STRING=$(join_args "${PLANNER_CMD[@]}")

# Start planner agent
tmux send-keys -t $SESSION_NAME:planner "clear" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '🎯 PLANNER AGENT (STRICT MODE) STARTING'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo 'Project: $PROJECT_PATH'" C-m

if [ "$RESUME_SESSION" = true ]; then
    tmux send-keys -t $SESSION_NAME:planner "echo 'Mode: RESUMING PREVIOUS SESSION'" C-m
else
    tmux send-keys -t $SESSION_NAME:planner "echo 'Mode: NEW SESSION'" C-m
fi

tmux send-keys -t $SESSION_NAME:planner "echo ''" C-m
tmux send-keys -t $SESSION_NAME:planner "echo 'STRICT MODE ENABLED:'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '  ✓ Complete implementation required'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '  ✓ All tests must pass (unit, integration, contract, e2e)'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '  ✓ No TODOs or placeholders allowed'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '  ✓ Full verification before proceeding'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo ''" C-m

# Launch LLM CLI via shim
tmux send-keys -t $SESSION_NAME:planner "$PLANNER_CMD_STRING" C-m
sleep 3

# Load prompt
if [ "$RESUME_SESSION" = false ]; then
    # For new session, send full prompt
    tmux send-keys -t $SESSION_NAME:planner "$(cat "$PLANNER_PROMPT")" C-m
    sleep 1
    
    if [ -f "$PROJECT_PATH/tasks.md" ]; then
        tmux send-keys -t $SESSION_NAME:planner "" C-m
        tmux send-keys -t $SESSION_NAME:planner "IMPORTANT: Read tasks.md in the project root and work through ALL tasks sequentially." C-m
        tmux send-keys -t $SESSION_NAME:planner "Task: ${TASK:-Complete all tasks in tasks.md file}" C-m
    else
        tmux send-keys -t $SESSION_NAME:planner "" C-m
        tmux send-keys -t $SESSION_NAME:planner "Task: $TASK" C-m
    fi
else
    # For resumed session, just remind about strict mode
    sleep 2
    tmux send-keys -t $SESSION_NAME:planner "Continue with previous task. Remember: STRICT MODE - complete implementation, all tests passing, no shortcuts." C-m
fi

# Start reviewer agent
tmux send-keys -t $SESSION_NAME:reviewer "clear" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '✅ REVIEWER AGENT (STRICT MODE) STARTING'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo 'Project: $PROJECT_PATH'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo ''" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo 'ENFORCEMENT ENABLED:'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '  ✓ Comprehensive test coverage required'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '  ✓ All tests must pass (100%)'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '  ✓ Will reject incomplete implementations'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '  ✓ Zero tolerance for shortcuts'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo ''" C-m

tmux send-keys -t $SESSION_NAME:reviewer "$(join_args "$LLM_SH" repl --project .)" C-m
sleep 3
tmux send-keys -t $SESSION_NAME:reviewer "$(cat "$REVIEWER_PROMPT")" C-m

# Set up monitoring dashboard
tmux send-keys -t $SESSION_NAME:monitor "clear" C-m
tmux send-keys -t $SESSION_NAME:monitor "$SCRIPT_DIR/monitor.sh $PROJECT_PATH" C-m

# Set up logs viewer
tmux send-keys -t $SESSION_NAME:logs "clear" C-m
tmux send-keys -t $SESSION_NAME:logs "tail -f coordination/logs/notifications.log" C-m

# Select planner window as default
tmux select-window -t $SESSION_NAME:planner

echo ""
echo -e "${GREEN}✅ Agent system launched successfully in STRICT MODE!${NC}"
echo ""
echo -e "${RED}${BOLD}⚠️  STRICT MODE ACTIVE ⚠️${NC}"
echo ""
echo -e "${YELLOW}Strict mode requirements:${NC}"
echo "  • Complete implementation (no TODOs, no placeholders)"
echo "  • All tests written (unit, integration, contract, e2e)"
echo "  • All tests must pass (100%)"
echo "  • Code coverage ≥ 80%"
echo "  • No linter or type errors"
echo "  • Reviewer will reject incomplete work"
echo ""
echo -e "${BLUE}📺 Tmux Windows:${NC}"
echo "  1. planner  - Task planning and implementation"
echo "  2. reviewer - Strict quality enforcement"
echo "  3. monitor  - Real-time status dashboard"
echo "  4. logs     - Live activity logs"
echo ""
echo -e "${BLUE}🎮 Tmux Controls:${NC}"
echo "  Ctrl+b 0  - Planner agent"
echo "  Ctrl+b 1  - Reviewer agent"
echo "  Ctrl+b 2  - Monitor dashboard"
echo "  Ctrl+b 3  - Activity logs"
echo "  Ctrl+b d  - Detach"
echo ""
echo -e "${BLUE}📋 Session Info:${NC}"
if [ "$RESUME_SESSION" = true ]; then
    echo "  Mode: RESUMED SESSION"
else
    echo "  Mode: NEW SESSION"
fi
if [ -f "$PROJECT_PATH/tasks.md" ]; then
    echo "  Tasks: Working from tasks.md ($TASK_COUNT tasks found)"
fi
echo ""
echo -e "${BLUE}🛑 To stop:${NC}"
echo "  ./stop-agents.sh"
echo ""
echo -e "${YELLOW}Attaching to session in 3 seconds...${NC}"
sleep 3

# Attach to the session
tmux attach -t $SESSION_NAME
