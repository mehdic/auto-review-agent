#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

if [ -z "$1" ]; then
    echo "Usage: ./monitor.sh /path/to/project"
    exit 1
fi

PROJECT_PATH="$1"

# Check if coordination directory exists
if [ ! -d "$PROJECT_PATH/coordination" ]; then
    echo "Coordination directory not found!"
    exit 1
fi

cd "$PROJECT_PATH"

# Function to get JSON value safely
get_json_value() {
    local file=$1
    local key=$2
    if [ -f "$file" ]; then
        jq -r "$key // \"N/A\"" "$file" 2>/dev/null || echo "N/A"
    else
        echo "N/A"
    fi
}

# Function to count array items
count_json_array() {
    local file=$1
    local key=$2
    if [ -f "$file" ]; then
        jq "$key | length" "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

while true; do
    clear
    
    echo -e "${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}       ${BOLD}${CYAN}🤖 AUTONOMOUS AGENT COORDINATION DASHBOARD 🤖${NC}          ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Task Proposals Status
    echo -e "${BOLD}${YELLOW}📋 TASK PROPOSALS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    TASK_FILE="coordination/task_proposals.json"
    if [ -f "$TASK_FILE" ]; then
        STATUS=$(get_json_value "$TASK_FILE" ".status")
        TASK_DESC=$(get_json_value "$TASK_FILE" ".task_description")
        PLANNER_ID=$(get_json_value "$TASK_FILE" ".planner_agent_id")
        REVIEWER_ID=$(get_json_value "$TASK_FILE" ".reviewer_agent_id")
        CHOSEN=$(get_json_value "$TASK_FILE" ".chosen_approach")
        PROPOSAL_COUNT=$(count_json_array "$TASK_FILE" ".proposals")
        
        # Color code status
        if [ "$STATUS" = "empty" ]; then
            STATUS_COLOR="${BLUE}"
            STATUS_ICON="⏳"
        elif [ "$STATUS" = "awaiting_review" ]; then
            STATUS_COLOR="${YELLOW}"
            STATUS_ICON="⏰"
        elif [ "$STATUS" = "approved" ]; then
            STATUS_COLOR="${GREEN}"
            STATUS_ICON="✅"
        elif [ "$STATUS" = "needs_revision" ]; then
            STATUS_COLOR="${RED}"
            STATUS_ICON="🔄"
        elif [ "$STATUS" = "blocked" ]; then
            STATUS_COLOR="${RED}"
            STATUS_ICON="🚫"
        else
            STATUS_COLOR="${NC}"
            STATUS_ICON="❓"
        fi
        
        echo -e "  ${STATUS_ICON} Status: ${STATUS_COLOR}${BOLD}${STATUS}${NC}"
        
        if [ "$TASK_DESC" != "N/A" ] && [ "$TASK_DESC" != "null" ]; then
            echo -e "  📝 Task: ${CYAN}${TASK_DESC}${NC}"
        fi
        
        if [ "$PROPOSAL_COUNT" != "0" ]; then
            echo -e "  💡 Proposals: ${MAGENTA}${PROPOSAL_COUNT}${NC}"
        fi
        
        if [ "$PLANNER_ID" != "N/A" ] && [ "$PLANNER_ID" != "null" ]; then
            echo -e "  🎯 Planner: ${planner_ID}"
        fi
        
        if [ "$CHOSEN" != "N/A" ] && [ "$CHOSEN" != "null" ]; then
            echo -e "  ✨ Chosen: ${GREEN}${BOLD}${CHOSEN}${NC}"
        fi
        
        if [ "$REVIEWER_ID" != "N/A" ] && [ "$REVIEWER_ID" != "null" ]; then
            echo -e "  ✅ Reviewer: ${REVIEWER_ID}"
        fi
        
        # Show proposals if they exist
        if [ "$PROPOSAL_COUNT" != "0" ] && [ "$PROPOSAL_COUNT" != "N/A" ]; then
            echo -e "\n  ${BOLD}Available Approaches:${NC}"
            for i in $(seq 0 $((PROPOSAL_COUNT - 1))); do
                PROP_ID=$(get_json_value "$TASK_FILE" ".proposals[$i].id")
                PROP_TITLE=$(get_json_value "$TASK_FILE" ".proposals[$i].title")
                PROP_EFFORT=$(get_json_value "$TASK_FILE" ".proposals[$i].estimated_effort")
                
                if [ "$PROP_ID" = "$CHOSEN" ]; then
                    echo -e "    ${GREEN}▶${NC} ${BOLD}$PROP_ID${NC}: $PROP_TITLE ${CYAN}($PROP_EFFORT)${NC}"
                else
                    echo -e "      $PROP_ID: $PROP_TITLE ${CYAN}($PROP_EFFORT)${NC}"
                fi
            done
        fi
    else
        echo -e "  ${YELLOW}⚠️  No task proposals file found${NC}"
    fi
    
    echo ""
    
    # Active Work Registry
    echo -e "${BOLD}${YELLOW}🔧 ACTIVE WORK${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    ACTIVE_FILE="coordination/active_work_registry.json"
    if [ -f "$ACTIVE_FILE" ]; then
        AGENT_COUNT=$(jq '.agents | length' "$ACTIVE_FILE" 2>/dev/null || echo "0")
        
        if [ "$AGENT_COUNT" = "0" ]; then
            echo -e "  ${BLUE}⏳ No agents currently working${NC}"
        else
            jq -r '.agents | to_entries[] | "  🤖 \(.key):\n     Role: \(.value.role)\n     Status: \(.value.status)\n     Working on: \(.value.working_on // "N/A")"' "$ACTIVE_FILE" 2>/dev/null || echo "  Unable to parse active work"
        fi
    else
        echo -e "  ${YELLOW}⚠️  No active work file found${NC}"
    fi
    
    echo ""
    
    # Completed Work
    echo -e "${BOLD}${YELLOW}✨ COMPLETED WORK${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    COMPLETED_FILE="coordination/completed_work_log.json"
    if [ -f "$COMPLETED_FILE" ]; then
        COMPLETED_COUNT=$(get_json_value "$COMPLETED_FILE" ".total_completed")
        
        if [ "$COMPLETED_COUNT" = "0" ] || [ "$COMPLETED_COUNT" = "N/A" ]; then
            echo -e "  ${BLUE}📝 No completed tasks yet${NC}"
        else
            echo -e "  ${GREEN}✅ Total completed: ${BOLD}${COMPLETED_COUNT}${NC}"
            echo -e "\n  ${BOLD}Recent completions:${NC}"
            jq -r '.completed_tasks[-3:] | reverse[] | "  ✓ \(.task_id): \(.summary // "N/A")\n    Completed: \(.completed_at // "N/A")"' "$COMPLETED_FILE" 2>/dev/null || echo "  Unable to parse completed work"
        fi
    else
        echo -e "  ${YELLOW}⚠️  No completed work file found${NC}"
    fi
    
    echo ""
    
    # Messages
    echo -e "${BOLD}${YELLOW}💬 AGENT MESSAGES${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    P2R_FILE="coordination/messages/planner_to_reviewer.json"
    R2P_FILE="coordination/messages/reviewer_to_planner.json"
    
    P2R_UNREAD=$(get_json_value "$P2R_FILE" ".unread_count")
    R2P_UNREAD=$(get_json_value "$R2P_FILE" ".unread_count")
    
    echo -e "  📨 Planner → Reviewer: ${CYAN}${P2R_UNREAD} unread${NC}"
    echo -e "  📨 Reviewer → Planner: ${CYAN}${R2P_UNREAD} unread${NC}"
    
    # Show latest message if exists
    LATEST_MSG=$(jq -r '.messages[-1] | "  📬 Latest: [\(.from)] \(.subject) (\(.timestamp // "N/A"))"' "$P2R_FILE" 2>/dev/null)
    if [ "$LATEST_MSG" != "  📬 Latest: [null] null (N/A)" ]; then
        echo -e "\n${LATEST_MSG}"
    fi
    
    echo ""
    
    # Recent Logs
    echo -e "${BOLD}${YELLOW}📝 RECENT ACTIVITY (last 5 entries)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    NOTIF_LOG="coordination/logs/notifications.log"
    if [ -f "$NOTIF_LOG" ]; then
        tail -5 "$NOTIF_LOG" | while IFS= read -r line; do
            if [[ $line == *"PLANNER"* ]]; then
                echo -e "  ${CYAN}🎯 $line${NC}"
            elif [[ $line == *"REVIEWER"* ]]; then
                echo -e "  ${GREEN}✅ $line${NC}"
            else
                echo -e "  $line"
            fi
        done
    else
        echo -e "  ${BLUE}No activity logged yet${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📊 Refreshing every 2 seconds... Press Ctrl+C to exit${NC}"
    
    sleep 2
done
