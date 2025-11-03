#!/bin/bash
# Claude Skill: Check Agent Progress
# Call this with: ./check-agent-progress.sh

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
LOG_DIR="$PROJECT_PATH/coordination/logs"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}              AGENT SYSTEM PROGRESS REPORT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📊 Current Status${NC}"
echo "────────────────────────────────────────"
if [ -f "$PROPOSALS_FILE" ]; then
    STATUS=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('status', 'unknown'))" 2>/dev/null || echo "error reading")
    CHOSEN=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('chosen_approach', 'none'))" 2>/dev/null || echo "none")
    PROPOSAL_COUNT=$(python3 -c "import json; print(len(json.load(open('$PROPOSALS_FILE')).get('proposals', [])))" 2>/dev/null || echo "0")
    
    case $STATUS in
        "idle")
            echo -e "Status: ${YELLOW}IDLE${NC} - No activity"
            ;;
        "awaiting_review")
            echo -e "Status: ${YELLOW}AWAITING REVIEW${NC} - $PROPOSAL_COUNT proposal(s) created"
            ;;
        "approved")
            echo -e "Status: ${GREEN}APPROVED${NC} - Ready for implementation"
            echo -e "Chosen Approach: ${GREEN}$CHOSEN${NC}"
            ;;
        "implementing")
            echo -e "Status: ${GREEN}IMPLEMENTING${NC} - Work in progress"
            ;;
        *)
            echo -e "Status: ${RED}$STATUS${NC}"
            ;;
    esac
else
    echo -e "${RED}No proposals file found${NC}"
fi

echo ""
echo -e "${BLUE}🧪 Test Progress${NC}"
echo "────────────────────────────────────────"
if [ -d "$PROJECT_PATH" ]; then
    cd "$PROJECT_PATH"
    if command -v mvn &> /dev/null; then
        TEST_OUTPUT=$(mvn test 2>/dev/null | grep "Tests run:" | tail -1)
        if [ -n "$TEST_OUTPUT" ]; then
            echo "$TEST_OUTPUT"
            PASSING=$(echo "$TEST_OUTPUT" | grep -o 'Failures: [0-9]*' | grep -o '[0-9]*')
            ERRORS=$(echo "$TEST_OUTPUT" | grep -o 'Errors: [0-9]*' | grep -o '[0-9]*')
            TOTAL=$(echo "$TEST_OUTPUT" | grep -o 'Tests run: [0-9]*' | grep -o '[0-9]*$')
            if [ -n "$TOTAL" ] && [ -n "$PASSING" ] && [ -n "$ERRORS" ]; then
                FIXED=$((TOTAL - PASSING - ERRORS))
                PERCENTAGE=$((FIXED * 100 / TOTAL))
                echo -e "Progress: ${GREEN}$FIXED/$TOTAL tests passing ($PERCENTAGE%)${NC}"
                REMAINING=$((TOTAL - FIXED))
                echo -e "Remaining: ${YELLOW}$REMAINING tests to fix${NC}"
            fi
        else
            echo "Tests not run yet or build system not configured"
        fi
    else
        echo "Maven not found - cannot check test status"
    fi
else
    echo "Project directory not found"
fi

echo ""
echo -e "${BLUE}📝 Recent Agent Activity${NC}"
echo "────────────────────────────────────────"
if [ -d "$LOG_DIR" ]; then
    if [ -f "$LOG_DIR/notifications.log" ]; then
        RECENT_LOGS=$(tail -10 "$LOG_DIR/notifications.log" 2>/dev/null)
        if [ -n "$RECENT_LOGS" ]; then
            echo "$RECENT_LOGS" | while IFS= read -r line; do
                if [[ "$line" == *"PLANNER"* ]]; then
                    echo -e "${GREEN}$line${NC}"
                elif [[ "$line" == *"REVIEWER"* ]]; then
                    echo -e "${BLUE}$line${NC}"
                else
                    echo "$line"
                fi
            done
        else
            echo "No recent activity in logs"
        fi
    else
        echo "No notification log found"
    fi
    
    echo ""
    echo -e "${BLUE}📁 Latest Files Modified${NC}"
    echo "────────────────────────────────────────"
    RECENT_FILES=$(find "$PROJECT_PATH" -type f -name "*.java" -mmin -30 2>/dev/null | head -5)
    if [ -n "$RECENT_FILES" ]; then
        echo "$RECENT_FILES" | while read -r file; do
            echo "  ✓ $(basename "$file") - $(date -r "$file" '+%H:%M:%S')"
        done
    else
        echo "  No Java files modified in last 30 minutes"
    fi
fi

echo ""
echo -e "${BLUE}💭 Agent Communication${NC}"
echo "────────────────────────────────────────"
if tmux has-session -t agent_system_spec 2>/dev/null; then
    echo -e "${GREEN}✅ Agents are running${NC}"
    
    PLANNER_LAST=$(tmux capture-pane -t agent_system_spec:planner -p 2>/dev/null | tail -2 | head -1)
    REVIEWER_LAST=$(tmux capture-pane -t agent_system_spec:reviewer -p 2>/dev/null | tail -2 | head -1)
    
    echo ""
    echo "Planner last output:"
    echo "  $PLANNER_LAST"
    echo ""
    echo "Reviewer last output:"
    echo "  $REVIEWER_LAST"
else
    echo -e "${RED}❌ No agent session running${NC}"
fi

echo ""
echo -e "${BLUE}📈 Timeline${NC}"
echo "────────────────────────────────────────"
if [ -f "$PROPOSALS_FILE" ]; then
    CREATED=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('created_at', 'unknown'))" 2>/dev/null)
    REVIEWED=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('reviewed_at', 'not yet'))" 2>/dev/null)
    
    echo "Proposals created: $CREATED"
    echo "Review completed: $REVIEWED"
    
    if [ -f "$LOG_DIR/combined/agent_history.log" ]; then
        START_TIME=$(head -1 "$LOG_DIR/combined/agent_history.log" 2>/dev/null | grep -o '\[.*\]' | head -1)
        LAST_TIME=$(tail -1 "$LOG_DIR/combined/agent_history.log" 2>/dev/null | grep -o '\[.*\]' | head -1)
        echo "Session started: $START_TIME"
        echo "Last activity: $LAST_TIME"
    fi
fi

echo ""
echo -e "${BLUE}🎯 Recommendations${NC}"
echo "────────────────────────────────────────"

if [ "$STATUS" == "idle" ] || [ "$PROPOSAL_COUNT" == "0" ]; then
    echo -e "${YELLOW}⚠️  No proposals created yet${NC}"
    echo "   Run: ./agent-autofix.sh"
elif [ "$STATUS" == "awaiting_review" ]; then
    echo -e "${YELLOW}⚠️  Waiting for review${NC}"
    echo "   Reviewer should approve soon, or run: ./agent-autofix.sh"
elif [ "$STATUS" == "approved" ]; then
    if [[ "$PLANNER_LAST" == *"waiting"* ]] || [[ "$PLANNER_LAST" == *"Waiting"* ]]; then
        echo -e "${YELLOW}⚠️  Planner not implementing${NC}"
        echo "   Run: ./agent-autofix.sh to trigger implementation"
    else
        echo -e "${GREEN}✅ Implementation should be in progress${NC}"
        echo "   Monitor with: tmux attach -t agent_system_spec"
    fi
elif [ "$STATUS" == "implementing" ]; then
    echo -e "${GREEN}✅ Implementation in progress${NC}"
    echo "   Let agents continue working"
else
    echo -e "${RED}⚠️  Unknown state${NC}"
    echo "   Run: ./agent-autofix.sh to diagnose"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "Full logs: $LOG_DIR"
echo -e "Monitor live: tmux attach -t agent_system_spec"
echo -e "Auto-fix issues: ./agent-autofix.sh"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
