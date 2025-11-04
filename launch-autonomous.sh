#!/bin/bash
# Launch Autonomous System - Implementer + Watchdog
# This is the main entry point for the autonomous agent system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helpers
source "$SCRIPT_DIR/lib/find-spec.sh"
source "$SCRIPT_DIR/lib/state-manager.sh"

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

# Dependency checks
check_dependencies() {
    local missing=()

    command -v tmux >/dev/null 2>&1 || missing+=("tmux")
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    command -v jq >/dev/null 2>&1 || missing+=("jq")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}ERROR: Missing required dependencies: ${missing[*]}${NC}"
        echo ""
        echo "Install them with:"
        echo "  Ubuntu/Debian: sudo apt install tmux python3 jq"
        echo "  macOS: brew install tmux python3 jq"
        exit 1
    fi
}

if [ -z "$1" ] || [ -z "$2" ]; then
    show_usage
    exit 1
fi

PROJECT_PATH="$1"
SPEC_NUMBER="$2"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  AUTONOMOUS AGENT SYSTEM${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check dependencies
echo -e "${CYAN}Checking dependencies...${NC}"
check_dependencies
echo -e "${GREEN}✓ All dependencies found${NC}"
echo ""

# Resolve project path
if [ "$PROJECT_PATH" = "." ]; then
    PROJECT_PATH="$(pwd)"
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}ERROR: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# Find the spec
echo -e "${CYAN}Finding spec...${NC}"

SPEC_INFO=$(find_spec "$PROJECT_PATH" "$SPEC_NUMBER")

if [ $? -ne 0 ]; then
    echo -e "${RED}$SPEC_INFO${NC}"
    exit 1
fi

# Parse spec info
eval "$SPEC_INFO"

if [ ! -f "$TASKS_FILE" ]; then
    echo -e "${RED}ERROR: Tasks file not found: $TASKS_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found spec:${NC}"
echo -e "  Spec: ${CYAN}$SPEC_NAME${NC}"
echo -e "  Tasks: ${CYAN}$TASKS_FILE${NC}"
echo ""

# Check for existing sessions with same spec
echo -e "${CYAN}Checking for existing sessions...${NC}"
EXISTING_SESSIONS=$(tmux list-sessions 2>/dev/null | grep "agent_${SPEC_NUMBER}_" | cut -d: -f1)

if [ -n "$EXISTING_SESSIONS" ]; then
    echo -e "${YELLOW}Found existing session(s) for spec $SPEC_NUMBER:${NC}"
    echo "$EXISTING_SESSIONS" | while read sess; do
        echo -e "  - ${YELLOW}$sess${NC}"
    done
    echo ""
    read -p "Kill existing sessions and start fresh? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$EXISTING_SESSIONS" | while read sess; do
            echo -e "${CYAN}Killing session: $sess${NC}"
            tmux kill-session -t "$sess" 2>/dev/null
        done
        echo -e "${GREEN}✓ Existing sessions killed${NC}"

        # Kill any zombie background processes for this spec
        echo -e "${CYAN}Cleaning up zombie processes...${NC}"
        ZOMBIE_COUNT=0
        for pid in $(ps aux | grep -E "(implementer-loop|watchdog-loop).*${SPEC_NUMBER}" | grep -v grep | awk '{print $2}'); do
            kill "$pid" 2>/dev/null && ZOMBIE_COUNT=$((ZOMBIE_COUNT + 1))
        done
        if [ $ZOMBIE_COUNT -gt 0 ]; then
            echo -e "${GREEN}✓ Killed $ZOMBIE_COUNT zombie processes${NC}"
            sleep 2  # Give them time to die
        fi
    else
        echo -e "${RED}Aborted - existing sessions still running${NC}"
        exit 1
    fi
    echo ""
fi

# Create session name with timestamp
SESSION_NAME="agent_${SPEC_NUMBER}_$(date +%s)"

echo -e "${CYAN}Creating tmux session: ${YELLOW}$SESSION_NAME${NC}"

# Create coordination directory
COORDINATION_DIR="$PROJECT_PATH/coordination"
mkdir -p "$COORDINATION_DIR/logs"

# Initialize state file
echo -e "${CYAN}Initializing state file...${NC}"
cat > "$COORDINATION_DIR/state.json" << EOF
{
  "status": "initializing",
  "last_update": "$(date -Iseconds)",
  "message": "System starting up",
  "current_task": "none",
  "completed_tasks": [],
  "total_tasks": 0,
  "iteration": 0
}
EOF

# Create tmux session with windows
tmux new-session -d -s "$SESSION_NAME" -n "implementer" -c "$PROJECT_PATH"

# Window 0: Start Claude interactively
echo -e "${CYAN}Starting Claude in implementer window...${NC}"
tmux send-keys -t "$SESSION_NAME:implementer" "cd '$PROJECT_PATH' && claude"
tmux send-keys -t "$SESSION_NAME:implementer" Enter
sleep 3

# Run implementer-loop.sh in background (not in a tmux window)
echo -e "${CYAN}Starting implementer loop in background...${NC}"
IMPLEMENTER_SCRIPT="$SCRIPT_DIR/implementer-loop.sh"

if [ ! -f "$IMPLEMENTER_SCRIPT" ]; then
    echo -e "${RED}ERROR: Implementer script not found: $IMPLEMENTER_SCRIPT${NC}"
    tmux kill-session -t "$SESSION_NAME"
    exit 1
fi

# Run in background with output to log
nohup "$IMPLEMENTER_SCRIPT" "$PROJECT_PATH" "$TASKS_FILE" "$SPEC_NAME" "$SESSION_NAME" > "$COORDINATION_DIR/logs/implementer-loop.log" 2>&1 &
IMPLEMENTER_PID=$!
echo "$IMPLEMENTER_PID" > "$COORDINATION_DIR/implementer.pid"
sleep 2

# Window 1: Tech Lead Dashboard (formatted live view)
echo -e "${CYAN}Creating tech lead dashboard...${NC}"
tmux new-window -t "$SESSION_NAME" -n "tech-lead" -c "$PROJECT_PATH"

# Create a formatted dashboard that updates every 3 seconds
TECH_LEAD_CMD="watch -n 3 -c 'echo \"═══════════════════════════════════════════════════════════\"; \
echo \"  TECH LEAD DASHBOARD\"; \
echo \"═══════════════════════════════════════════════════════════\"; \
echo \"\"; \
echo \"Last 20 observations:\"; \
echo \"───────────────────────────────────────────────────────────\"; \
tail -20 \"$COORDINATION_DIR/logs/watchdog.log\" 2>/dev/null || echo \"Waiting for tech lead to start...\"; \
echo \"\"; \
echo \"═══════════════════════════════════════════════════════════\"; \
echo \"Current Status:\"; \
echo \"───────────────────────────────────────────────────────────\"; \
cat \"$COORDINATION_DIR/state.json\" 2>/dev/null | jq -r \".status,.message\" || echo \"Initializing...\"; \
echo \"\"; \
echo \"Press Ctrl-C to exit, Ctrl-b 0 for developer window\"'"

tmux send-keys -t "$SESSION_NAME:tech-lead" "$TECH_LEAD_CMD"
tmux send-keys -t "$SESSION_NAME:tech-lead" Enter
sleep 1

# Run watchdog-loop.sh in background (not in a tmux window)
echo -e "${CYAN}Starting watchdog loop in background...${NC}"
WATCHDOG_SCRIPT="$SCRIPT_DIR/watchdog-loop.sh"

if [ ! -f "$WATCHDOG_SCRIPT" ]; then
    echo -e "${RED}ERROR: Watchdog script not found: $WATCHDOG_SCRIPT${NC}"
    tmux kill-session -t "$SESSION_NAME"
    exit 1
fi

# Run in background with output to log
nohup "$WATCHDOG_SCRIPT" "$PROJECT_PATH" "$TASKS_FILE" "$SPEC_NAME" "$SESSION_NAME" > "$COORDINATION_DIR/logs/watchdog-loop.log" 2>&1 &
WATCHDOG_PID=$!
echo "$WATCHDOG_PID" > "$COORDINATION_DIR/watchdog.pid"
sleep 2

# Window 2: Monitor (state + activity summary)
echo -e "${CYAN}Starting monitor...${NC}"
tmux new-window -t "$SESSION_NAME" -n "monitor" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:monitor" "watch -n 5 'echo \"=== State File ===\"  && cat \"$COORDINATION_DIR/state.json\" 2>/dev/null | jq . || echo \"Waiting for state file...\" ; echo \"\" ; echo \"=== Recent Developer Activity ===\" ; tail -20 \"$COORDINATION_DIR/logs/implementer.log\" 2>/dev/null || echo \"No logs yet\"'"
tmux send-keys -t "$SESSION_NAME:monitor" Enter

# Window 3: Developer Loop Logs (raw background process output)
echo -e "${CYAN}Creating developer loop log viewer...${NC}"
tmux new-window -t "$SESSION_NAME" -n "dev-loop" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:dev-loop" "tail -f '$COORDINATION_DIR/logs/implementer-loop.log'"
tmux send-keys -t "$SESSION_NAME:dev-loop" Enter

# Window 4: Tech Lead Loop Logs (raw background process output)
echo -e "${CYAN}Creating tech lead loop log viewer...${NC}"
tmux new-window -t "$SESSION_NAME" -n "lead-loop" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:lead-loop" "tail -f '$COORDINATION_DIR/logs/watchdog-loop.log'"
tmux send-keys -t "$SESSION_NAME:lead-loop" Enter

# Select developer window (window 0) as default
tmux select-window -t "$SESSION_NAME:implementer"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ AUTONOMOUS SYSTEM LAUNCHED${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Session:${NC} ${YELLOW}$SESSION_NAME${NC}"
echo ""
echo -e "${CYAN}Windows:${NC}"
echo -e "  ${GREEN}0: developer${NC}   - Claude Code (watch the developer work)"
echo -e "  ${GREEN}1: tech-lead${NC}   - Tech lead dashboard (formatted observations)"
echo -e "  ${GREEN}2: monitor${NC}     - System status (state + activity summary)"
echo -e "  ${GREEN}3: dev-loop${NC}    - Developer loop logs (background process debug)"
echo -e "  ${GREEN}4: lead-loop${NC}   - Tech lead loop logs (background process debug)"
echo ""
echo -e "${CYAN}Commands:${NC}"
echo -e "  Attach:  ${YELLOW}tmux attach -t $SESSION_NAME${NC}"
echo -e "  Detach:  ${YELLOW}Ctrl+b d${NC}"
echo -e "  Windows: ${YELLOW}Ctrl+b 0/1/2/3/4${NC} or ${YELLOW}Ctrl+b n${NC} (next) / ${YELLOW}Ctrl+b p${NC} (previous)"
echo -e "  Stop:    ${YELLOW}tmux kill-session -t $SESSION_NAME${NC}"
echo ""
echo -e "${CYAN}Background Processes:${NC}"
echo -e "  Developer loop: ${YELLOW}PID $(cat $COORDINATION_DIR/implementer.pid 2>/dev/null || echo 'starting...')${NC} → ${YELLOW}$COORDINATION_DIR/logs/implementer-loop.log${NC}"
echo -e "  Tech lead loop: ${YELLOW}PID $(cat $COORDINATION_DIR/watchdog.pid 2>/dev/null || echo 'starting...')${NC} → ${YELLOW}$COORDINATION_DIR/logs/watchdog-loop.log${NC}"
echo ""
echo -e "${CYAN}Activity Logs:${NC}"
echo -e "  Developer:  ${YELLOW}$COORDINATION_DIR/logs/implementer.log${NC}"
echo -e "  Tech Lead:  ${YELLOW}$COORDINATION_DIR/logs/watchdog.log${NC}"
echo ""
echo -e "${CYAN}State File:${NC}"
echo -e "  ${YELLOW}cat $COORDINATION_DIR/state.json | jq .${NC}"
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
