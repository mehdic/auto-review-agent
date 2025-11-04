#!/bin/bash

# Start Here - Main entry point for autonomous implementer system
# This script provides an interactive menu to launch and manage the autonomous agent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/find-spec.sh"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Autonomous Implementer System${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get project path
echo -e "${GREEN}Enter project path (press Enter for current directory):${NC}"
read -r PROJECT_PATH
if [ -z "$PROJECT_PATH" ]; then
    PROJECT_PATH="$(pwd)"
fi

# Validate project path
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}Using project path: $PROJECT_PATH${NC}"
echo ""

# Get spec number
echo -e "${GREEN}Enter spec number (e.g., 001, 002, 999):${NC}"
read -r SPEC_NUMBER

if [ -z "$SPEC_NUMBER" ]; then
    echo -e "${RED}Error: Spec number is required${NC}"
    exit 1
fi

# Find the spec
SPEC_INFO=$(find_spec "$PROJECT_PATH" "$SPEC_NUMBER")
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Could not find spec $SPEC_NUMBER in $PROJECT_PATH/specs${NC}"
    echo -e "${YELLOW}Available specs:${NC}"
    ls -d "$PROJECT_PATH/specs"/*/ 2>/dev/null | xargs -n1 basename
    exit 1
fi

eval "$SPEC_INFO"

echo -e "${BLUE}Found spec: $SPEC_NAME${NC}"
echo -e "${BLUE}Tasks file: $TASKS_FILE${NC}"
echo ""

# Show menu
echo -e "${GREEN}Select an operation:${NC}"
echo "  1) Launch autonomous implementer (new session)"
echo "  2) Monitor running session"
echo "  3) Stop running session"
echo "  4) View implementer logs"
echo "  5) View watchdog logs"
echo "  6) Exit"
echo ""
echo -e "${GREEN}Enter choice [1-6]:${NC}"
read -r CHOICE

SESSION_NAME="auto-impl-$(basename "$SPEC_DIR")"

case $CHOICE in
    1)
        echo -e "${BLUE}Launching autonomous implementer...${NC}"

        # Check if session already exists
        if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            echo -e "${YELLOW}Session $SESSION_NAME already exists.${NC}"
            echo -e "${GREEN}Do you want to kill it and start fresh? (y/n):${NC}"
            read -r KILL_EXISTING
            if [ "$KILL_EXISTING" = "y" ]; then
                tmux kill-session -t "$SESSION_NAME"
                echo -e "${BLUE}Killed existing session${NC}"
            else
                echo -e "${YELLOW}Attaching to existing session...${NC}"
                tmux attach-session -t "$SESSION_NAME"
                exit 0
            fi
        fi

        # Launch the autonomous system
        "$SCRIPT_DIR/launch-autonomous.sh" "$PROJECT_PATH" "$SPEC_NUMBER"

        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  Session launched successfully!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "${BLUE}Session name: $SESSION_NAME${NC}"
        echo ""
        echo -e "${YELLOW}To attach and watch the implementer:${NC}"
        echo -e "  tmux attach-session -t $SESSION_NAME"
        echo ""
        echo -e "${YELLOW}Inside tmux:${NC}"
        echo -e "  Ctrl-b 0  - Switch to implementer window"
        echo -e "  Ctrl-b 1  - Switch to watchdog window"
        echo -e "  Ctrl-b 2  - Switch to monitor window"
        echo -e "  Ctrl-b d  - Detach (session keeps running)"
        echo ""
        echo -e "${YELLOW}To stop the session:${NC}"
        echo -e "  ./start-here.sh  (then choose option 3)"
        echo ""
        ;;

    2)
        if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            echo -e "${RED}Error: Session $SESSION_NAME is not running${NC}"
            exit 1
        fi

        echo -e "${BLUE}Attaching to session $SESSION_NAME...${NC}"
        echo -e "${YELLOW}Press Ctrl-b d to detach${NC}"
        sleep 2
        tmux attach-session -t "$SESSION_NAME"
        ;;

    3)
        if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            echo -e "${YELLOW}Session $SESSION_NAME is not running${NC}"
            exit 0
        fi

        echo -e "${YELLOW}Stopping session $SESSION_NAME...${NC}"
        tmux kill-session -t "$SESSION_NAME"
        echo -e "${GREEN}Session stopped${NC}"
        ;;

    4)
        LOG_FILE="$PROJECT_PATH/logs/implementer-$(basename "$SPEC_DIR").log"
        if [ ! -f "$LOG_FILE" ]; then
            echo -e "${RED}Error: Log file not found: $LOG_FILE${NC}"
            exit 1
        fi

        echo -e "${BLUE}Viewing implementer logs (press q to quit):${NC}"
        sleep 1
        less +G "$LOG_FILE"
        ;;

    5)
        LOG_FILE="$PROJECT_PATH/logs/watchdog-$(basename "$SPEC_DIR").log"
        if [ ! -f "$LOG_FILE" ]; then
            echo -e "${RED}Error: Log file not found: $LOG_FILE${NC}"
            exit 1
        fi

        echo -e "${BLUE}Viewing watchdog logs (press q to quit):${NC}"
        sleep 1
        less +G "$LOG_FILE"
        ;;

    6)
        echo -e "${BLUE}Goodbye!${NC}"
        exit 0
        ;;

    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac
