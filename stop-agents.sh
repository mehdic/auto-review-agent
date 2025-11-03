#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SESSION_NAME="agent_system"

echo -e "${BLUE}🛑 Stopping Autonomous Agent System${NC}"
echo ""

# Check if session exists
if ! tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo -e "${YELLOW}⚠️  No active session found (${SESSION_NAME})${NC}"
    exit 0
fi

echo -e "${YELLOW}Sending stop signal to all agents...${NC}"

# Send Ctrl+C to all windows to stop Claude instances gracefully
tmux send-keys -t $SESSION_NAME:planner C-c
tmux send-keys -t $SESSION_NAME:reviewer C-c
tmux send-keys -t $SESSION_NAME:monitor C-c
tmux send-keys -t $SESSION_NAME:logs C-c

sleep 2

# Kill the session
echo -e "${YELLOW}Terminating tmux session...${NC}"
tmux kill-session -t $SESSION_NAME

echo -e "${GREEN}✅ Agent system stopped${NC}"
echo ""
echo -e "${BLUE}Note: Coordination files are preserved in your project's coordination/ directory${NC}"
