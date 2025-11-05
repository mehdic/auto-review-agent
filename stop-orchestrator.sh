#!/bin/bash
# Stop Orchestrator System - Clean shutdown of multi-agent orchestration

SESSION_NAME="$1"

if [ -z "$SESSION_NAME" ]; then
    echo "Usage: $0 <session_name>"
    echo ""
    echo "To list running orchestrator sessions:"
    echo "  tmux ls | grep orchestrator"
    exit 1
fi

# Check if session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session $SESSION_NAME does not exist"
    exit 1
fi

echo "Stopping orchestrator session: $SESSION_NAME"

# Get project path from tmux session
PROJECT_PATH=$(tmux display-message -t "$SESSION_NAME:orchestrator" -p "#{pane_current_path}" 2>/dev/null)

if [ -n "$PROJECT_PATH" ] && [ -d "$PROJECT_PATH/coordination" ]; then
    echo "Project: $PROJECT_PATH"

    # Kill orchestrator loop process
    if [ -f "$PROJECT_PATH/coordination/orchestrator.pid" ]; then
        ORCH_PID=$(cat "$PROJECT_PATH/coordination/orchestrator.pid" 2>/dev/null)
        if [ -n "$ORCH_PID" ] && kill -0 "$ORCH_PID" 2>/dev/null; then
            echo "Stopping orchestrator loop (PID: $ORCH_PID)..."
            kill -15 "$ORCH_PID" 2>/dev/null

            # Wait for graceful exit
            for i in {1..10}; do
                if ! kill -0 "$ORCH_PID" 2>/dev/null; then
                    echo "Orchestrator loop stopped gracefully"
                    break
                fi
                sleep 0.5
            done

            # Force kill if still alive
            if kill -0 "$ORCH_PID" 2>/dev/null; then
                echo "Force killing orchestrator loop..."
                kill -9 "$ORCH_PID" 2>/dev/null || true
            fi
        fi
        rm -f "$PROJECT_PATH/coordination/orchestrator.pid"
    fi

    # Update state files to indicate shutdown
    if [ -f "$PROJECT_PATH/coordination/orchestrator_state.json" ]; then
        python3 << EOF
import json
from datetime import datetime
try:
    with open('$PROJECT_PATH/coordination/orchestrator_state.json', 'r') as f:
        state = json.load(f)
    state['status'] = 'stopped'
    state['message'] = 'Orchestrator stopped by user'
    state['last_update'] = datetime.now().isoformat()
    with open('$PROJECT_PATH/coordination/orchestrator_state.json', 'w') as f:
        json.dump(state, f, indent=2)
    print("Updated orchestrator state to 'stopped'")
except:
    pass
EOF
    fi
fi

# Kill tmux session
echo "Killing tmux session..."
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

echo "✓ Orchestrator stopped"
echo ""
echo "Logs are available in: $PROJECT_PATH/coordination/logs/"
