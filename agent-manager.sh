#!/bin/bash
# Simple Agent Manager - One command to check and fix
# Usage: ./agent-manager.sh [check|fix|restart|status|help]

PROJECT_PATH="/Users/mchaouachi/IdeaProjects/StockMonitor"
AGENT_SYSTEM="/Users/mchaouachi/agent-system"
COMMAND="${1:-check}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

case $COMMAND in
    check|c)
        echo -e "${BLUE}AGENT STATUS CHECK${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        STATUS=$(python3 -c "import json; print(json.load(open('$PROJECT_PATH/coordination/task_proposals.json')).get('status', 'unknown'))" 2>/dev/null || echo "no file")
        echo "Current Status: $STATUS"
        
        if tmux has-session -t agent_system_spec 2>/dev/null; then
            echo "Session: ✅ Running"
            
            PLANNER=$(tmux capture-pane -t agent_system_spec:planner -p 2>/dev/null | tail -1)
            REVIEWER=$(tmux capture-pane -t agent_system_spec:reviewer -p 2>/dev/null | tail -1)
            
            echo ""
            echo "Planner: ${PLANNER:0:60}..."
            echo "Reviewer: ${REVIEWER:0:60}..."
        else
            echo "Session: ❌ Not running"
        fi
        
        cd "$PROJECT_PATH" 2>/dev/null
        TESTS=$(mvn test 2>/dev/null | grep "Tests run:" | tail -1)
        if [ -n "$TESTS" ]; then
            echo ""
            echo "Tests: $TESTS"
        fi
        
        echo ""
        if [ "$STATUS" == "idle" ] || [ "$STATUS" == "no file" ]; then
            echo -e "${YELLOW}Recommendation: Run './agent-manager.sh fix'${NC}"
        elif [ "$STATUS" == "awaiting_review" ]; then
            echo -e "${YELLOW}Status: Waiting for reviewer to approve${NC}"
        elif [ "$STATUS" == "approved" ]; then
            echo -e "${GREEN}Status: Should be implementing${NC}"
        fi
        ;;
        
    fix|f)
        echo -e "${BLUE}AUTO-FIXING AGENT SYSTEM${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        if [ -f "$AGENT_SYSTEM/agent-autofix.sh" ]; then
            "$AGENT_SYSTEM/agent-autofix.sh" "$PROJECT_PATH"
        else
            echo "Quick fix attempt..."
            
            STATUS=$(python3 -c "import json; print(json.load(open('$PROJECT_PATH/coordination/task_proposals.json')).get('status', 'unknown'))" 2>/dev/null || echo "no file")
            
            if [ "$STATUS" == "no file" ] || [ "$STATUS" == "idle" ]; then
                echo "Triggering proposal creation..."
                tmux send-keys -t agent_system_spec:planner C-c Enter 2>/dev/null
                sleep 2
                tmux send-keys -t agent_system_spec:planner "claude" Enter 2>/dev/null
                sleep 3
                tmux send-keys -t agent_system_spec:planner "Read /Users/mchaouachi/agent-system/prompts/planner_agent_spec.txt and $PROJECT_PATH/specs/999-fix-remaining-tests/spec.md. Create proposals in $PROJECT_PATH/coordination/task_proposals.json" Enter 2>/dev/null
                
            elif [ "$STATUS" == "awaiting_review" ]; then
                echo "Triggering review..."
                tmux send-keys -t agent_system_spec:reviewer C-c Enter 2>/dev/null
                sleep 2
                tmux send-keys -t agent_system_spec:reviewer "claude" Enter 2>/dev/null
                sleep 3
                tmux send-keys -t agent_system_spec:reviewer "Read $PROJECT_PATH/coordination/task_proposals.json and approve the best approach with status: approved" Enter 2>/dev/null
                
            elif [ "$STATUS" == "approved" ]; then
                echo "Triggering implementation..."
                tmux send-keys -t agent_system_spec:planner C-c Enter 2>/dev/null
                sleep 2
                tmux send-keys -t agent_system_spec:planner "claude" Enter 2>/dev/null
                sleep 3
                tmux send-keys -t agent_system_spec:planner "Read $PROJECT_PATH/coordination/task_proposals.json. Implement the approved approach to fix 75 tests in $PROJECT_PATH. Work autonomously." Enter 2>/dev/null
            fi
            
            echo -e "${GREEN}Fix attempted. Check status in 30 seconds.${NC}"
        fi
        ;;
        
    restart|r)
        echo -e "${BLUE}RESTARTING AGENT SYSTEM${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        tmux kill-session -t agent_system_spec 2>/dev/null
        echo "Killed old session"
        
        cd "$AGENT_SYSTEM"
        ./launch-agents-from-spec.sh "$PROJECT_PATH" 999
        ;;
        
    status|s)
        if [ -f "$PROJECT_PATH/coordination/task_proposals.json" ]; then
            python3 -c "
import json
data = json.load(open('$PROJECT_PATH/coordination/task_proposals.json'))
print(f'Status: {data.get(\"status\")}')
print(f'Proposals: {len(data.get(\"proposals\", []))}')
print(f'Chosen: {data.get(\"chosen_approach\", \"none\")}')
"
        else
            echo "No proposals file"
        fi
        
        if tmux has-session -t agent_system_spec 2>/dev/null; then
            echo "Session: Running"
        else
            echo "Session: Not running"
        fi
        ;;
        
    help|h|*)
        echo -e "${BLUE}Agent Manager Commands${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  check (c)    - Check current status and progress"
        echo "  fix (f)      - Auto-diagnose and fix issues"
        echo "  restart (r)  - Kill and restart entire system"
        echo "  status (s)   - Quick status (one-line)"
        echo "  help (h)     - Show this help"
        echo ""
        echo "Usage: ./agent-manager.sh [command]"
        echo "Default: check"
        ;;
esac
