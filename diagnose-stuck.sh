#!/bin/bash
# Diagnostic script to understand why planner is stuck

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔍 Diagnostic Report - Agent System${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Check proposals file
echo -e "${YELLOW}1. Proposals File Status${NC}"
if [ -f "$PROPOSALS_FILE" ]; then
    echo "   ✓ File exists: $PROPOSALS_FILE"

    STATUS=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('status', 'unknown'))" 2>/dev/null)
    CHOSEN=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('chosen_approach', 'none'))" 2>/dev/null)
    NUM_PROPOSALS=$(python3 -c "import json; data=json.load(open('$PROPOSALS_FILE')); print(len(data.get('proposals', [])))" 2>/dev/null)

    echo "   Status: $STATUS"
    echo "   Chosen approach: $CHOSEN"
    echo "   Number of proposals: $NUM_PROPOSALS"

    # Check for implementation instructions
    HAS_IMPL=$(python3 -c "import json; print('implementation_instructions' in json.load(open('$PROPOSALS_FILE')))" 2>/dev/null)
    echo "   Has implementation_instructions: $HAS_IMPL"

    if [ "$HAS_IMPL" == "True" ]; then
        echo "   ✓ Reviewer has added implementation plan"
    else
        echo "   ⚠ Missing implementation_instructions (reviewer may not have finished)"
    fi
else
    echo "   ✗ File not found!"
fi

echo ""

# 2. Check for running processes
echo -e "${YELLOW}2. Running Processes${NC}"
CLAUDE_PROCS=$(ps aux | grep -E "claude|anthropic" | grep -v grep | wc -l)
echo "   Claude processes: $CLAUDE_PROCS"
if [ $CLAUDE_PROCS -gt 0 ]; then
    echo "   Processes:"
    ps aux | grep -E "claude|anthropic" | grep -v grep | sed 's/^/      /'
else
    echo "   ⚠ No Claude processes running"
fi

echo ""

# 3. Check tmux sessions
echo -e "${YELLOW}3. Tmux Sessions${NC}"
if tmux list-sessions 2>/dev/null | grep -q "agent_system"; then
    echo "   ✓ Agent system session exists"

    echo "   Windows:"
    tmux list-windows -t agent_system_spec 2>/dev/null | sed 's/^/      /' || echo "      (Could not list windows)"

    # Check planner window state
    if tmux list-windows -t agent_system_spec 2>/dev/null | grep -q "planner"; then
        echo ""
        echo "   Planner window (last 15 lines):"
        echo "   ────────────────────────────────────────"
        tmux capture-pane -t agent_system_spec:planner -p 2>/dev/null | tail -15 | sed 's/^/   /'
        echo "   ────────────────────────────────────────"
    fi
else
    echo "   ✗ No agent_system_spec tmux session found"
fi

echo ""

# 4. Check for recent file changes
echo -e "${YELLOW}4. Recent File Changes (last 10 minutes)${NC}"
RECENT_CHANGES=$(find "$PROJECT_PATH/src" -name "*.java" -mmin -10 2>/dev/null | wc -l)
echo "   Java files modified: $RECENT_CHANGES"
if [ $RECENT_CHANGES -gt 0 ]; then
    echo "   Recent files:"
    find "$PROJECT_PATH/src" -name "*.java" -mmin -10 2>/dev/null | head -5 | sed 's/^/      /'
else
    echo "   ⚠ No recent changes (implementation may not be running)"
fi

echo ""

# 5. Check logs
echo -e "${YELLOW}5. Recent Log Entries${NC}"
if [ -f "$PROJECT_PATH/coordination/logs/notifications.log" ]; then
    echo "   Last 5 log entries:"
    echo "   ────────────────────────────────────────"
    tail -5 "$PROJECT_PATH/coordination/logs/notifications.log" | sed 's/^/   /'
    echo "   ────────────────────────────────────────"
else
    echo "   ⚠ No log file found"
fi

echo ""

# 6. Diagnosis
echo -e "${GREEN}📋 Diagnosis${NC}"
echo ""

if [ "$STATUS" == "implementing" ] && [ $CLAUDE_PROCS -eq 0 ]; then
    echo -e "${RED}PROBLEM IDENTIFIED:${NC}"
    echo "   Status is 'implementing' but no Claude process is running!"
    echo ""
    echo "   ROOT CAUSE:"
    echo "   The planner loop updated the status to 'implementing' but then"
    echo "   exited without actually starting Claude to do the implementation."
    echo ""
    echo -e "${GREEN}SOLUTION:${NC}"
    echo "   Run the nuclear fix to force implementation:"
    echo "   ./nuclear-fix.sh"

elif [ "$STATUS" == "approved" ] && [ $CLAUDE_PROCS -eq 0 ]; then
    echo -e "${YELLOW}Issue:${NC}"
    echo "   Status is 'approved' but implementation hasn't started."
    echo ""
    echo -e "${GREEN}SOLUTION:${NC}"
    echo "   Run: ./force-start-approved.sh"

elif [ "$STATUS" == "awaiting_review" ]; then
    echo -e "${YELLOW}Waiting State:${NC}"
    echo "   Proposals created, waiting for reviewer to approve."
    echo "   Check reviewer window: tmux attach -t agent_system_spec"
    echo "   Press Ctrl+b 1 to see reviewer"

elif [ $CLAUDE_PROCS -gt 0 ]; then
    echo -e "${GREEN}Looks OK:${NC}"
    echo "   Claude is running. Check if it's actively implementing:"

    if [ $RECENT_CHANGES -gt 0 ]; then
        echo "   ✓ Files are being modified - implementation is active!"
    else
        echo "   ⚠ No recent file changes - Claude might be stuck or thinking"
        echo "     Attach to tmux to see what it's doing:"
        echo "     tmux attach -t agent_system_spec"
    fi
else
    echo "   Check the details above to understand the current state."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
