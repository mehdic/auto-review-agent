#!/bin/bash
# Launch Autonomous System - Implementer + Watchdog
# This is the main entry point for the autonomous agent system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load spec finder
source "$SCRIPT_DIR/lib/find-spec.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

show_usage() {
    echo "Usage: $0 <project_path> <spec_number>"
    echo ""
    echo "Arguments:"
    echo "  project_path   Path to project (or '.' for current directory)"
    echo "  spec_number    Spec number (e.g., 001, 002, 999)"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/project 001"
    echo "  $0 . 002"
    echo ""
    echo "This will:"
    echo "  1. Find specs/001-feature-name/tasks.md"
    echo "  2. Launch implementer (does the work)"
    echo "  3. Launch watchdog (monitors and guides)"
    echo "  4. Show you the tmux session"
}

if [ -z "$1" ] || [ -z "$2" ]; then
    show_usage
    exit 1
fi

PROJECT_PATH="$1"
SPEC_NUMBER="$2"

# Resolve project path
if [ "$PROJECT_PATH" = "." ]; then
    PROJECT_PATH="$(pwd)"
fi

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# Find the spec
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AUTONOMOUS AGENT SYSTEM${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Finding spec...${NC}"

SPEC_INFO=$(find_spec "$PROJECT_PATH" "$SPEC_NUMBER")

if [ $? -ne 0 ]; then
    echo -e "${RED}$SPEC_INFO${NC}"
    exit 1
fi

# Parse spec info
eval "$SPEC_INFO"

echo -e "${GREEN}✓ Found spec:${NC}"
echo -e "  Spec: ${CYAN}$SPEC_NAME${NC}"
echo -e "  Tasks: ${CYAN}$TASKS_FILE${NC}"
echo ""

# Create session name
SESSION_NAME="agent_${SPEC_NUMBER}_$(date +%s)"

echo -e "${CYAN}Creating tmux session: ${YELLOW}$SESSION_NAME${NC}"

# Kill existing session with same base name if exists
tmux kill-session -t "agent_${SPEC_NUMBER}*" 2>/dev/null

# Create tmux session with windows
tmux new-session -d -s "$SESSION_NAME" -n "implementer" -c "$PROJECT_PATH"

# Window 0: Implementer
echo -e "${CYAN}Starting implementer...${NC}"
tmux send-keys -t "$SESSION_NAME:implementer" "$SCRIPT_DIR/implementer-loop.sh '$PROJECT_PATH' '$TASKS_FILE' '$SPEC_NAME' '$SESSION_NAME'"
tmux send-keys -t "$SESSION_NAME:implementer" Enter
sleep 3

# Window 1: Watchdog
echo -e "${CYAN}Starting watchdog...${NC}"
tmux new-window -t "$SESSION_NAME" -n "watchdog" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:watchdog" "$SCRIPT_DIR/watchdog-loop.sh '$PROJECT_PATH' '$TASKS_FILE' '$SPEC_NAME' '$SESSION_NAME'"
tmux send-keys -t "$SESSION_NAME:watchdog" Enter
sleep 2

# Window 2: Monitor
echo -e "${CYAN}Starting monitor...${NC}"
tmux new-window -t "$SESSION_NAME" -n "monitor" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:monitor" "watch -n 5 'cat coordination/state.json 2>/dev/null | jq .'"
tmux send-keys -t "$SESSION_NAME:monitor" Enter

# Select implementer window
tmux select-window -t "$SESSION_NAME:implementer"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ AUTONOMOUS SYSTEM LAUNCHED${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Session:${NC} ${YELLOW}$SESSION_NAME${NC}"
echo ""
echo -e "${CYAN}Windows:${NC}"
echo -e "  ${GREEN}0: implementer${NC} - Does the work (you can watch Claude here)"
echo -e "  ${GREEN}1: watchdog${NC}    - Monitors and guides implementer"
echo -e "  ${GREEN}2: monitor${NC}     - Shows current status"
echo ""
echo -e "${CYAN}Commands:${NC}"
echo -e "  Attach:  ${YELLOW}tmux attach -t $SESSION_NAME${NC}"
echo -e "  Detach:  ${YELLOW}Ctrl+b d${NC}"
echo -e "  Windows: ${YELLOW}Ctrl+b 0/1/2${NC}"
echo -e "  Stop:    ${YELLOW}tmux kill-session -t $SESSION_NAME${NC}"
echo ""
echo -e "${CYAN}Logs:${NC}"
echo -e "  Implementer: ${YELLOW}tail -f $PROJECT_PATH/coordination/logs/implementer.log${NC}"
echo -e "  Watchdog:    ${YELLOW}tail -f $PROJECT_PATH/coordination/logs/watchdog.log${NC}"
echo ""

read -p "Attach to session now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Attaching... (Ctrl+b d to detach)${NC}"
    sleep 1
    tmux attach -t "$SESSION_NAME"
fi

echo ""
echo -e "${GREEN}System is running in background${NC}"
echo -e "Attach anytime with: ${YELLOW}tmux attach -t $SESSION_NAME${NC}"
