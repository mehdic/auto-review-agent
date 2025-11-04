#!/bin/bash
# Launch Orchestrator System - Start multi-agent orchestration with developer and tech lead

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
PROJECT_PATH="$1"
SPEC_NUMBER="$2"

if [ -z "$PROJECT_PATH" ] || [ -z "$SPEC_NUMBER" ]; then
    echo "Usage: $0 <project_path> <spec_number>"
    echo ""
    echo "Example: $0 /path/to/StockMonitor 001"
    echo ""
    echo "This will:"
    echo "  1. Create tmux session with 3 windows:"
    echo "     - Window 0 (developer): Developer agent implementing tasks"
    echo "     - Window 1 (techlead): Tech lead agent reviewing and guiding"
    echo "     - Window 2 (orchestrator): Orchestrator coordinating both"
    echo "  2. Initialize coordination directory and state files"
    echo "  3. Start orchestration loop managing both agents"
    exit 1
fi

# Validate paths
if [ ! -d "$PROJECT_PATH" ]; then
    echo "ERROR: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

# Find spec directory
source "$SCRIPT_DIR/lib/find-spec.sh"
SPEC_DIR=$(find_spec_dir "$PROJECT_PATH" "$SPEC_NUMBER")

if [ -z "$SPEC_DIR" ] || [ ! -d "$SPEC_DIR" ]; then
    echo "ERROR: Could not find spec directory for number: $SPEC_NUMBER"
    echo "Searched in: $PROJECT_PATH/specs/"
    exit 1
fi

SPEC_FILE="$SPEC_DIR/spec.md"
TASKS_FILE="$SPEC_DIR/tasks.md"

if [ ! -f "$TASKS_FILE" ]; then
    echo "ERROR: Tasks file not found: $TASKS_FILE"
    exit 1
fi

# Extract spec name
SPEC_NAME=$(basename "$SPEC_DIR")

echo "═══════════════════════════════════════════════════════════"
echo "LAUNCHING MULTI-AGENT ORCHESTRATOR"
echo "═══════════════════════════════════════════════════════════"
echo "Project:     $PROJECT_PATH"
echo "Spec:        $SPEC_NAME"
echo "Spec file:   $SPEC_FILE"
echo "Tasks file:  $TASKS_FILE"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Generate unique session name
SESSION_NAME="orchestrator_${SPEC_NUMBER}_$$"

echo "Creating tmux session: $SESSION_NAME"
echo ""

# Initialize coordination directory
COORDINATION_DIR="$PROJECT_PATH/coordination"
mkdir -p "$COORDINATION_DIR/logs"
mkdir -p "$COORDINATION_DIR/messages"

# Create tmux session with 3 windows
tmux new-session -d -s "$SESSION_NAME" -n "developer" -c "$PROJECT_PATH"

# Window 0: Developer Agent (Claude Code)
tmux send-keys -t "$SESSION_NAME:developer" "cd '$PROJECT_PATH' && claude" Enter
sleep 2

# Window 1: Tech Lead Agent (Claude Code)
tmux new-window -t "$SESSION_NAME" -n "techlead" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:techlead" "cd '$PROJECT_PATH' && claude" Enter
sleep 2

# Window 2: Orchestrator Dashboard
tmux new-window -t "$SESSION_NAME" -n "orchestrator" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:orchestrator" "clear" Enter
tmux send-keys -t "$SESSION_NAME:orchestrator" "echo 'Orchestrator Dashboard - Multi-Agent System'" Enter
tmux send-keys -t "$SESSION_NAME:orchestrator" "echo '═══════════════════════════════════════════════════════════'" Enter
tmux send-keys -t "$SESSION_NAME:orchestrator" "echo 'Monitoring orchestration state...'" Enter
tmux send-keys -t "$SESSION_NAME:orchestrator" "echo ''" Enter
tmux send-keys -t "$SESSION_NAME:orchestrator" "watch -n 5 \"cat $COORDINATION_DIR/orchestrator_state.json 2>/dev/null || echo 'Waiting for orchestrator to start...'\"" Enter

# Window 3: Developer State Monitor
tmux new-window -t "$SESSION_NAME" -n "dev-state" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:dev-state" "watch -n 5 \"echo 'Developer State:' && cat $COORDINATION_DIR/developer_state.json 2>/dev/null || echo 'Waiting...'\"" Enter

# Window 4: Tech Lead State Monitor
tmux new-window -t "$SESSION_NAME" -n "lead-state" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:lead-state" "watch -n 5 \"echo 'Tech Lead State:' && cat $COORDINATION_DIR/techlead_state.json 2>/dev/null || echo 'Waiting...'\"" Enter

# Window 5: Orchestrator Logs
tmux new-window -t "$SESSION_NAME" -n "logs" -c "$PROJECT_PATH"
tmux send-keys -t "$SESSION_NAME:logs" "tail -f $COORDINATION_DIR/logs/orchestrator.log" Enter

echo "Tmux session created with windows:"
echo "  0: developer   - Developer agent (Claude Code)"
echo "  1: techlead    - Tech lead agent (Claude Code)"
echo "  2: orchestrator - Orchestration state monitor"
echo "  3: dev-state   - Developer state monitor"
echo "  4: lead-state  - Tech lead state monitor"
echo "  5: logs        - Orchestrator logs"
echo ""

# Start orchestrator loop in background
echo "Starting orchestrator loop..."
nohup "$SCRIPT_DIR/orchestrator-loop.sh" "$PROJECT_PATH" "$SPEC_DIR" "$SESSION_NAME" \
    > "$COORDINATION_DIR/logs/orchestrator-loop.log" 2>&1 &

ORCHESTRATOR_PID=$!
echo "$ORCHESTRATOR_PID" > "$COORDINATION_DIR/orchestrator.pid"

echo "Orchestrator loop started (PID: $ORCHESTRATOR_PID)"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "ORCHESTRATOR RUNNING"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "To attach to the session:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo "To detach (while keeping it running):"
echo "  Press: Ctrl+b, then d"
echo ""
echo "To switch between windows:"
echo "  Ctrl+b 0  - Developer agent"
echo "  Ctrl+b 1  - Tech lead agent"
echo "  Ctrl+b 2  - Orchestrator state"
echo "  Ctrl+b 3  - Developer state"
echo "  Ctrl+b 4  - Tech lead state"
echo "  Ctrl+b 5  - Logs"
echo ""
echo "To stop orchestration:"
echo "  ./stop-orchestrator.sh $SESSION_NAME"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Auto-attach to session
echo "Attaching to session in 3 seconds..."
sleep 3
tmux attach -t "$SESSION_NAME"
