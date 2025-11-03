#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Launching Autonomous Agent System${NC}"
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Usage: ./launch-agents.sh /path/to/your/project [task_description]${NC}"
    echo ""
    echo "Example:"
    echo "  ./launch-agents.sh /home/user/my-project 'Create a REST API for user authentication'"
    exit 1
fi

PROJECT_PATH="$1"
TASK="${2:-No specific task provided yet}"

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
PLANNER_PROMPT="$SCRIPT_DIR/prompts/planner_agent.txt"
REVIEWER_PROMPT="$SCRIPT_DIR/prompts/reviewer_agent.txt"

echo -e "${BLUE}Configuration:${NC}"
echo "  Project: $PROJECT_PATH"
echo "  Planner prompt: $PLANNER_PROMPT"
echo "  Reviewer prompt: $REVIEWER_PROMPT"
echo "  Task: $TASK"
echo ""

# Check if prompts exist
if [ ! -f "$PLANNER_PROMPT" ]; then
    echo -e "${RED}❌ Planner prompt not found: $PLANNER_PROMPT${NC}"
    exit 1
fi

if [ ! -f "$REVIEWER_PROMPT" ]; then
    echo -e "${RED}❌ Reviewer prompt not found: $REVIEWER_PROMPT${NC}"
    exit 1
fi

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux is not installed. Please install it first:${NC}"
    echo "  Ubuntu/Debian: sudo apt install tmux"
    echo "  macOS: brew install tmux"
    exit 1
fi

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo -e "${RED}❌ Claude Code is not installed. Please install it first:${NC}"
    echo "  npm install -g claude"
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

# Set up planner pane title
tmux select-pane -t $SESSION_NAME:planner -T "🎯 PLANNER AGENT"

# Create reviewer window
tmux new-window -t $SESSION_NAME -n reviewer -c "$PROJECT_PATH"
tmux select-pane -t $SESSION_NAME:reviewer -T "✅ REVIEWER AGENT"

# Create monitor window
tmux new-window -t $SESSION_NAME -n monitor -c "$PROJECT_PATH"
tmux select-pane -t $SESSION_NAME:monitor -T "📊 MONITORING"

# Create logs window
tmux new-window -t $SESSION_NAME -n logs -c "$PROJECT_PATH"
tmux select-pane -t $SESSION_NAME:logs -T "📝 LOGS"

echo -e "${YELLOW}Setting up agents...${NC}"

# Start planner agent
tmux send-keys -t $SESSION_NAME:planner "clear" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '🎯 PLANNER AGENT STARTING'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo 'Project: $PROJECT_PATH'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo 'Prompt: $PLANNER_PROMPT'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo ''" C-m
tmux send-keys -t $SESSION_NAME:planner "echo 'Starting Claude Code with planner role...'" C-m
tmux send-keys -t $SESSION_NAME:planner "echo ''" C-m

# Send the prompt file content to planner
tmux send-keys -t $SESSION_NAME:planner "claude --project ." C-m
sleep 2
tmux send-keys -t $SESSION_NAME:planner "$(cat $PLANNER_PROMPT | head -100)" C-m
sleep 1
tmux send-keys -t $SESSION_NAME:planner "" C-m
tmux send-keys -t $SESSION_NAME:planner "Task: $TASK" C-m

# Start reviewer agent  
tmux send-keys -t $SESSION_NAME:reviewer "clear" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '✅ REVIEWER AGENT STARTING'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo '═══════════════════════════════════════════════════════'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo 'Project: $PROJECT_PATH'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo 'Prompt: $REVIEWER_PROMPT'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo ''" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo 'Starting Claude Code with reviewer role...'" C-m
tmux send-keys -t $SESSION_NAME:reviewer "echo ''" C-m

# Send the prompt file content to reviewer
tmux send-keys -t $SESSION_NAME:reviewer "claude --project ." C-m
sleep 2
tmux send-keys -t $SESSION_NAME:reviewer "$(cat $REVIEWER_PROMPT | head -100)" C-m

# Set up monitoring dashboard
tmux send-keys -t $SESSION_NAME:monitor "clear" C-m
tmux send-keys -t $SESSION_NAME:monitor "$SCRIPT_DIR/monitor.sh $PROJECT_PATH" C-m

# Set up logs viewer
tmux send-keys -t $SESSION_NAME:logs "clear" C-m
tmux send-keys -t $SESSION_NAME:logs "tail -f coordination/logs/notifications.log" C-m

# Select planner window as default
tmux select-window -t $SESSION_NAME:planner

echo ""
echo -e "${GREEN}✅ Agent system launched successfully!${NC}"
echo ""
echo -e "${BLUE}📺 Tmux Windows:${NC}"
echo "  1. planner  - The task planning agent"
echo "  2. reviewer - The review and approval agent"  
echo "  3. monitor  - Real-time coordination monitoring"
echo "  4. logs     - Live notification logs"
echo ""
echo -e "${BLUE}🎮 Tmux Controls:${NC}"
echo "  Ctrl+b 0  - Switch to planner"
echo "  Ctrl+b 1  - Switch to reviewer"
echo "  Ctrl+b 2  - Switch to monitor"
echo "  Ctrl+b 3  - Switch to logs"
echo "  Ctrl+b n  - Next window"
echo "  Ctrl+b p  - Previous window"
echo "  Ctrl+b d  - Detach (agents keep running)"
echo "  Ctrl+b z  - Zoom current pane"
echo ""
echo -e "${BLUE}📋 To intervene:${NC}"
echo "  1. Switch to the agent window (Ctrl+b 0 or Ctrl+b 1)"
echo "  2. Type your message directly"
echo "  3. Press Enter"
echo ""
echo -e "${BLUE}🔗 To attach to the session:${NC}"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo -e "${BLUE}🛑 To stop the agents:${NC}"
echo "  ./stop-agents.sh"
echo ""
echo -e "${YELLOW}Attaching to session in 3 seconds...${NC}"
sleep 3

# Attach to the session
tmux attach -t $SESSION_NAME
