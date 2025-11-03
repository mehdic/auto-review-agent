#!/bin/bash
# Intelligent Agent System Auto-Fixer
# Exhausts all possible fixes before considering restart

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
AGENT_SYSTEM="${2:-/Users/mchaouachi/agent-system}"
LLM_BIN="${LLM_BIN:-codex}"
LLM_MODEL="${LLM_MODEL:-}"
if [[ -z "${LLM_ARGS:-}" && -n "${LLM_ARGS_AUTO:-}" ]]; then
    LLM_ARGS="$LLM_ARGS_AUTO"
fi
LLM_ARGS="${LLM_ARGS:-}"
export LLM_BIN LLM_MODEL LLM_ARGS
LLM_SH="$AGENT_SYSTEM/scripts/llm.sh"
if ! command -v "$LLM_BIN" &> /dev/null; then
    echo -e "${RED}Missing LLM CLI: $LLM_BIN${NC}"
    exit 1
fi
if [ ! -x "$LLM_SH" ]; then
    echo -e "${RED}Missing LLM shim at $LLM_SH${NC}"
    exit 1
fi
LLM_SH_ESCAPED=$(printf '%q' "$LLM_SH")
LLM_REPL_CMD="$LLM_SH_ESCAPED repl"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"
REGISTRY_FILE="$PROJECT_PATH/coordination/active_work_registry.json"
LOG_DIR="$PROJECT_PATH/coordination/logs"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 Agent System Auto-Fixer Starting...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$LOG_DIR"
FIX_LOG="$LOG_DIR/autofix_$(date +%Y%m%d_%H%M%S).log"

log_action() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$FIX_LOG"
}

check_file_exists() {
    if [ ! -f "$1" ]; then
        log_action "ERROR: File not found: $1"
        echo '{}' > "$1"
        log_action "Created empty file: $1"
        return 1
    fi
    return 0
}

get_json_value() {
    python3 -c "import json,sys; d=json.load(open('$1')); print(d.get('$2', 'null'))" 2>/dev/null || echo "null"
}

update_json_field() {
    local file=$1
    local field=$2
    local value=$3
    
    python3 -c "
import json
try:
    with open('$file', 'r') as f:
        data = json.load(f)
    data['$field'] = '$value'
    with open('$file', 'w') as f:
        json.dump(data, f, indent=2)
    print('OK')
except Exception as e:
    print(f'ERROR: {e}')
"
}

check_tmux_window() {
    local window=$1
    tmux capture-pane -t agent_system_spec:$window -p 2>/dev/null | tail -5
}

send_to_window() {
    local window=$1
    local command=$2
    tmux send-keys -t agent_system_spec:$window C-c 2>/dev/null
    sleep 1
    tmux send-keys -t agent_system_spec:$window "$command" Enter 2>/dev/null
}

echo -e "${YELLOW}Step 1: Checking System State${NC}"
echo "────────────────────────────────────────"

check_file_exists "$PROPOSALS_FILE"
check_file_exists "$REGISTRY_FILE"

STATUS=$(get_json_value "$PROPOSALS_FILE" "status")
CHOSEN=$(get_json_value "$PROPOSALS_FILE" "chosen_approach")
PROPOSALS_COUNT=$(python3 -c "import json; d=json.load(open('$PROPOSALS_FILE')); print(len(d.get('proposals', [])))" 2>/dev/null || echo "0")

log_action "Current status: $STATUS"
log_action "Chosen approach: $CHOSEN"
log_action "Proposals count: $PROPOSALS_COUNT"

if ! tmux has-session -t agent_system_spec 2>/dev/null; then
    log_action "ERROR: No tmux session found"
    echo -e "${RED}No active session. Run: ./launch-agents-from-spec.sh $PROJECT_PATH 999${NC}"
    exit 1
fi

PLANNER_STATE=$(check_tmux_window planner | tail -1)
REVIEWER_STATE=$(check_tmux_window reviewer | tail -1)

log_action "Planner state: $PLANNER_STATE"
log_action "Reviewer state: $REVIEWER_STATE"

echo ""
echo -e "${YELLOW}Step 2: Diagnosing Issues${NC}"
echo "────────────────────────────────────────"

ISSUES_FOUND=0
FIXES_TO_APPLY=""

if [ "$STATUS" == "null" ] || [ "$STATUS" == "idle" ] || [ "$PROPOSALS_COUNT" == "0" ]; then
    log_action "ISSUE: No proposals created"
    FIXES_TO_APPLY="$FIXES_TO_APPLY create_proposals"
    ((ISSUES_FOUND++))
    
elif [ "$STATUS" == "awaiting_review" ]; then
    if [[ "$REVIEWER_STATE" == *"Waiting"* ]] || [[ "$REVIEWER_STATE" == *"waiting"* ]]; then
        log_action "ISSUE: Reviewer not detecting proposals"
        FIXES_TO_APPLY="$FIXES_TO_APPLY trigger_reviewer"
    else
        log_action "ISSUE: Reviewer might be stuck"
        FIXES_TO_APPLY="$FIXES_TO_APPLY restart_reviewer"
    fi
    ((ISSUES_FOUND++))
    
elif [ "$STATUS" == "approved" ]; then
    if [ "$CHOSEN" == "null" ]; then
        log_action "ISSUE: Approved but no approach chosen"
        FIXES_TO_APPLY="$FIXES_TO_APPLY set_chosen_approach"
        ((ISSUES_FOUND++))
    fi
    
    if [[ "$PLANNER_STATE" == *"waiting"* ]] || [[ "$PLANNER_STATE" == *"Waiting"* ]]; then
        log_action "ISSUE: Planner not detecting approval"
        FIXES_TO_APPLY="$FIXES_TO_APPLY trigger_planner_implementation"
        ((ISSUES_FOUND++))
    elif [[ "$PLANNER_STATE" == *"$"* ]] || [[ "$PLANNER_STATE" == *"#"* ]]; then
        log_action "ISSUE: Planner script ended without implementing"
        FIXES_TO_APPLY="$FIXES_TO_APPLY start_implementation"
        ((ISSUES_FOUND++))
    fi
    
elif [ "$STATUS" == "implementing" ]; then
    log_action "Status shows implementing - checking if actually working..."
    RECENT_ACTIVITY=$(find "$PROJECT_PATH" -type f -name "*.java" -mmin -5 2>/dev/null | wc -l)
    if [ "$RECENT_ACTIVITY" -eq 0 ]; then
        log_action "ISSUE: No recent file changes despite implementing status"
        FIXES_TO_APPLY="$FIXES_TO_APPLY restart_implementation"
        ((ISSUES_FOUND++))
    fi
fi

if [[ "$PLANNER_STATE" == *"ERROR"* ]] || [[ "$PLANNER_STATE" == *"error"* ]]; then
    log_action "ISSUE: Planner has errors"
    FIXES_TO_APPLY="$FIXES_TO_APPLY fix_planner_error"
    ((ISSUES_FOUND++))
fi

if [[ "$REVIEWER_STATE" == *"ERROR"* ]] || [[ "$REVIEWER_STATE" == *"error"* ]]; then
    log_action "ISSUE: Reviewer has errors"
    FIXES_TO_APPLY="$FIXES_TO_APPLY fix_reviewer_error"
    ((ISSUES_FOUND++))
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No issues detected!${NC}"
    echo "System appears to be working correctly."
    echo "Current status: $STATUS"
    exit 0
fi

echo -e "${YELLOW}Found $ISSUES_FOUND issue(s). Applying fixes...${NC}"
echo ""
echo -e "${YELLOW}Step 3: Applying Fixes${NC}"
echo "────────────────────────────────────────"

apply_fix() {
    local fix_type=$1
    
    case $fix_type in
        create_proposals)
            log_action "FIX: Triggering proposal creation"
            send_to_window planner "$LLM_REPL_CMD"
            sleep 3
            send_to_window planner "Read $AGENT_SYSTEM/prompts/planner_agent_spec.txt and $PROJECT_PATH/specs/999-fix-remaining-tests/spec.md. Create proposals in $PROPOSALS_FILE with status: awaiting_review"
            sleep 10
            ;;
            
        trigger_reviewer)
            log_action "FIX: Triggering reviewer to check proposals"
            send_to_window reviewer "$LLM_REPL_CMD"
            sleep 3
            send_to_window reviewer "Read $PROPOSALS_FILE and evaluate the proposals. Choose the best approach and update the file with status: approved and chosen_approach"
            sleep 10
            ;;
            
        restart_reviewer)
            log_action "FIX: Restarting reviewer loop"
            send_to_window reviewer "$AGENT_SYSTEM/reviewer-loop.sh '$PROJECT_PATH' '$PROJECT_PATH/specs/999-fix-remaining-tests/spec.md' '999-fix-remaining-tests' '$AGENT_SYSTEM/prompts/reviewer_agent_spec.txt'"
            sleep 5
            ;;
            
        set_chosen_approach)
            log_action "FIX: Setting chosen_approach to approach_1"
            update_json_field "$PROPOSALS_FILE" "chosen_approach" "approach_1"
            update_json_field "$PROPOSALS_FILE" "reviewer_notes" "Auto-selected approach 1 for implementation"
            ;;
            
        trigger_planner_implementation)
            log_action "FIX: Triggering planner to start implementation"
            send_to_window planner "$LLM_REPL_CMD"
            sleep 3
            send_to_window planner "Read $PROPOSALS_FILE. The proposal is approved with chosen_approach. Implement the solution to fix 75 tests in $PROJECT_PATH. Work autonomously."
            sleep 5
            ;;
            
        start_implementation)
            log_action "FIX: Starting fresh implementation"
            send_to_window planner "cd $PROJECT_PATH && $LLM_REPL_CMD"
            sleep 3
            send_to_window planner "You are the implementation agent. Read the approved proposal at $PROPOSALS_FILE and implement approach_1 to fix 75 failing tests. Currently 108/183 pass. Work autonomously without asking permission."
            sleep 5
            ;;
            
        restart_implementation)
            log_action "FIX: Restarting stalled implementation"
            send_to_window planner "$LLM_REPL_CMD"
            sleep 3
            send_to_window planner "Continue fixing the remaining tests in $PROJECT_PATH. Check current test status with mvn test and continue from where you left off. Work autonomously."
            sleep 5
            ;;
            
        fix_planner_error)
            log_action "FIX: Clearing planner errors and restarting"
            send_to_window planner "clear"
            sleep 1
            send_to_window planner "cd $PROJECT_PATH && $LLM_REPL_CMD"
            sleep 3
            send_to_window planner "Check $PROPOSALS_FILE for current status and continue with appropriate action. If approved, implement. If not, create proposals."
            ;;
            
        fix_reviewer_error)
            log_action "FIX: Clearing reviewer errors and restarting"
            send_to_window reviewer "clear"
            sleep 1
            send_to_window reviewer "cd $PROJECT_PATH && $LLM_REPL_CMD"
            sleep 3
            send_to_window reviewer "Check $PROPOSALS_FILE. If status is awaiting_review, evaluate and approve. Otherwise wait for proposals."
            ;;
    esac
}

for fix in $FIXES_TO_APPLY; do
    echo -e "${BLUE}Applying fix: $fix${NC}"
    apply_fix $fix
    echo "Waiting for fix to take effect..."
    sleep 5
done

echo ""
echo -e "${YELLOW}Step 4: Verifying Fixes${NC}"
echo "────────────────────────────────────────"

sleep 10

NEW_STATUS=$(get_json_value "$PROPOSALS_FILE" "status")
NEW_PLANNER_STATE=$(check_tmux_window planner | tail -1)
NEW_REVIEWER_STATE=$(check_tmux_window reviewer | tail -1)

log_action "New status: $NEW_STATUS"
log_action "New planner state: $NEW_PLANNER_STATE"
log_action "New reviewer state: $NEW_REVIEWER_STATE"

FIXED=0
if [ "$STATUS" != "$NEW_STATUS" ]; then
    echo -e "${GREEN}✅ Status changed from $STATUS to $NEW_STATUS${NC}"
    FIXED=1
fi

if [[ "$NEW_PLANNER_STATE" != *"waiting"* ]] && [[ "$NEW_PLANNER_STATE" != *"Waiting"* ]]; then
    echo -e "${GREEN}✅ Planner is active${NC}"
    FIXED=1
fi

if [ $FIXED -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Fixes didn't resolve all issues. Checking for last resort options...${NC}"
    
    echo "Attempting forced state progression..."
    if [ "$STATUS" == "awaiting_review" ]; then
        log_action "LAST RESORT: Force approving proposals"
        python3 -c "
import json
with open('$PROPOSALS_FILE', 'r') as f:
    data = json.load(f)
data['status'] = 'approved'
data['chosen_approach'] = 'approach_1'
data['reviewer_notes'] = 'Auto-approved after manual intervention'
with open('$PROPOSALS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
        sleep 2
        send_to_window planner "$LLM_REPL_CMD"
        sleep 3
        send_to_window planner "The proposal has been approved. Read $PROPOSALS_FILE and implement approach_1 to fix 75 tests."
        
    elif [ "$STATUS" == "approved" ] && [ $ISSUES_FOUND -gt 0 ]; then
        echo -e "${RED}System stuck despite approval. Manual intervention required.${NC}"
        echo ""
        echo "Manual fix steps:"
        echo "1. tmux attach -t agent_system_spec"
        echo "2. Go to planner window (Ctrl+b 0)"
        echo "3. Start the LLM manually (./scripts/llm.sh repl) and paste implementation instructions"
        
        read -p "Do you want to restart the entire system? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_action "USER REQUESTED: Full system restart"
            tmux kill-session -t agent_system_spec
            sleep 2
            cd "$AGENT_SYSTEM"
            ./launch-agents-from-spec.sh "$PROJECT_PATH" 999
            echo -e "${GREEN}System restarted${NC}"
        fi
    fi
else
    echo -e "${GREEN}✅ Fixes applied successfully!${NC}"
fi

echo ""
echo -e "${BLUE}Summary${NC}"
echo "────────────────────────────────────────"
echo "Log file: $FIX_LOG"
echo "Current status: $(get_json_value "$PROPOSALS_FILE" "status")"
echo "Issues found: $ISSUES_FOUND"
echo "Fixes applied: $FIXES_TO_APPLY"
echo ""
echo "Monitor progress with: tmux attach -t agent_system_spec"
