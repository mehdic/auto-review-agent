#!/bin/bash
# Start Here - Agent System Central Command Center
# This script provides a menu-driven interface to all agent system scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default paths (can be overridden)
DEFAULT_PROJECT="/Users/mchaouachi/IdeaProjects/StockMonitor"
DEFAULT_AGENT_SYSTEM="/Users/mchaouachi/agent-system"

clear

show_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           ${BOLD}AGENT SYSTEM COMMAND CENTER${NC}${CYAN}                         ║${NC}"
    echo -e "${CYAN}║                  Start Here Menu                               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}SETUP & INITIALIZATION${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}1)${NC}  Setup Project          - Initialize coordination directory and files"
    echo -e "  ${BOLD}2)${NC}  Quick Start           - Automated setup wizard for new users"
    echo -e "  ${BOLD}3)${NC}  Create Test Spec      - Generate spec for fixing failing tests"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}LAUNCH AGENTS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}4)${NC}  Launch From Spec      - Start agents with specific spec file"
    echo -e "  ${BOLD}5)${NC}  Launch Standard       - Start agents without spec"
    echo -e "  ${BOLD}6)${NC}  Launch Strict Mode    - Start agents with strict validation"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}MONITORING & DEBUGGING${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}7)${NC}  Check Progress        - Full progress report with recommendations"
    echo -e "  ${BOLD}8)${NC}  Monitor System        - Live monitoring dashboard"
    echo -e "  ${BOLD}9)${NC}  Agent Manager         - Quick status/fix/restart tool"
    echo -e "  ${BOLD}10)${NC} View Logs            - Interactive log viewer"
    echo -e "  ${BOLD}11)${NC} Setup Logging        - Enable comprehensive chat logging"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}FIXING & RECOVERY${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}12)${NC} Auto Fix             - Intelligent issue diagnosis and fixing"
    echo -e "  ${BOLD}13)${NC} Force Implementation - Force planner to start implementing"
    echo -e "  ${BOLD}14)${NC} Start Implementation - Simple implementation starter"
    echo -e "  ${BOLD}15)${NC} Force Proposals      - Force creation of proposals"
    echo -e "  ${BOLD}16)${NC} Fix Launch Script    - Fix command too long errors"
    echo -e "  ${BOLD}17)${NC} Apply File Fix       - Fix file-based approach issues"
    echo -e "  ${BOLD}18)${NC} Stop Agents          - Kill all agent sessions"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}UTILITIES${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}19)${NC} View Documentation   - Show available documentation"
    echo -e "  ${BOLD}20)${NC} Show File Paths      - Display current configuration"
    echo -e "  ${BOLD}21)${NC} Run Custom Command   - Execute any script with parameters"
    echo ""
    echo -e "  ${BOLD}0)${NC}  Exit"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

get_project_path() {
    read -p "Enter project path [${DEFAULT_PROJECT}]: " project
    project="${project:-$DEFAULT_PROJECT}"
    echo "$project"
}

get_spec_number() {
    echo "Available specs:"
    if [ -d "$1/specs" ]; then
        ls -d "$1/specs"/*/ 2>/dev/null | while read dir; do
            echo "  - $(basename "$dir")"
        done
    fi
    read -p "Enter spec number (e.g., 999): " spec
    echo "$spec"
}

execute_script() {
    local script=$1
    shift
    local params="$@"
    
    if [ -f "$script" ]; then
        echo -e "${GREEN}Executing: $script $params${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        chmod +x "$script" 2>/dev/null
        "$script" $params
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Script completed.${NC}"
    else
        echo -e "${RED}Script not found: $script${NC}"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

show_documentation() {
    echo -e "${CYAN}Available Documentation:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local docs=(
        "COMPLETE_DOCUMENTATION.md:Complete system documentation"
        "AGENT_SYSTEM_GUIDE VERY IMPORTANT MAIN DOC.md:Main agent system guide"
        "QUICK_REFERENCE.md:Quick command reference"
        "QUICK_REFERENCE2.md:Additional quick reference"
        "README.md:General readme"
        "SPEC_BASED_WORKFLOW.md:Spec-based workflow guide"
        "STRICT_MODE_GUIDE.md:Strict mode documentation"
    )
    
    for doc in "${docs[@]}"; do
        IFS=':' read -r filename description <<< "$doc"
        if [ -f "$filename" ]; then
            echo -e "  ${GREEN}✓${NC} $filename"
            echo "    └─ $description"
        fi
    done
    echo ""
    read -p "Enter doc name to view (or press Enter to skip): " doc
    if [ -n "$doc" ] && [ -f "$doc" ]; then
        less "$doc"
    fi
}

show_paths() {
    echo -e "${CYAN}Current Configuration:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "Project Path:      ${GREEN}$DEFAULT_PROJECT${NC}"
    echo -e "Agent System:      ${GREEN}$DEFAULT_AGENT_SYSTEM${NC}"
    echo -e "Specs Directory:   ${GREEN}$DEFAULT_PROJECT/specs${NC}"
    echo -e "Coordination:      ${GREEN}$DEFAULT_PROJECT/coordination${NC}"
    echo -e "Logs:             ${GREEN}$DEFAULT_PROJECT/coordination/logs${NC}"
    echo ""
    echo -e "${CYAN}Active Sessions:${NC}"
    tmux ls 2>/dev/null || echo "  No tmux sessions running"
    echo ""
    echo -e "${CYAN}Current Status:${NC}"
    if [ -f "$DEFAULT_PROJECT/coordination/task_proposals.json" ]; then
        status=$(python3 -c "import json; print(json.load(open('$DEFAULT_PROJECT/coordination/task_proposals.json')).get('status', 'unknown'))" 2>/dev/null || echo "error")
        echo -e "  Task Status: ${GREEN}$status${NC}"
    else
        echo "  Task Status: No proposals file"
    fi
    echo ""
}

run_custom() {
    echo -e "${CYAN}Available Scripts:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ls -1 *.sh 2>/dev/null | while read script; do
        echo "  - $script"
    done
    echo ""
    read -p "Enter script name: " script
    if [ -f "$script" ]; then
        read -p "Enter parameters (or press Enter for none): " params
        execute_script "$script" $params
    else
        echo -e "${RED}Script not found: $script${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Main loop
while true; do
    clear
    show_header
    show_menu
    
    echo ""
    read -p "Select option [0-21]: " choice
    echo ""
    
    case $choice in
        1)  # Setup Project
            project=$(get_project_path)
            execute_script "./setup.sh" "$project"
            ;;
            
        2)  # Quick Start
            execute_script "./QUICKSTART.sh"
            ;;
            
        3)  # Create Test Spec
            execute_script "./CREATE_TEST_SPEC.sh"
            ;;
            
        4)  # Launch From Spec
            project=$(get_project_path)
            spec=$(get_spec_number "$project")
            execute_script "./launch-agents-from-spec.sh" "$project" "$spec"
            ;;
            
        5)  # Launch Standard
            project=$(get_project_path)
            execute_script "./launch-agents.sh" "$project"
            ;;
            
        6)  # Launch Strict Mode
            project=$(get_project_path)
            execute_script "./launch-agents-strict.sh" "$project"
            ;;
            
        7)  # Check Progress
            execute_script "./check-agent-progress.sh" "$DEFAULT_PROJECT"
            ;;
            
        8)  # Monitor System
            execute_script "./monitor.sh" "$DEFAULT_PROJECT"
            ;;
            
        9)  # Agent Manager
            echo -e "${CYAN}Agent Manager Commands:${NC}"
            echo "  check - Check status"
            echo "  fix   - Auto-fix issues"
            echo "  restart - Restart system"
            echo "  status - Quick status"
            read -p "Enter command [check]: " cmd
            cmd="${cmd:-check}"
            execute_script "./agent-manager.sh" "$cmd"
            ;;
            
        10) # View Logs
            execute_script "./view-logs.sh" "$DEFAULT_PROJECT"
            ;;
            
        11) # Setup Logging
            project=$(get_project_path)
            execute_script "./setup-logging.sh" "$project"
            ;;
            
        12) # Auto Fix
            project=$(get_project_path)
            execute_script "./agent-autofix.sh" "$project"
            ;;
            
        13) # Force Implementation
            execute_script "./force-implementation.sh"
            ;;
            
        14) # Start Implementation
            execute_script "./start-implementation.sh"
            ;;
            
        15) # Force Proposals
            execute_script "./force-proposals.sh"
            ;;
            
        16) # Fix Launch Script
            execute_script "./fix-launch-script.sh"
            ;;
            
        17) # Apply File Fix
            execute_script "./apply-file-fix.sh"
            ;;
            
        18) # Stop Agents
            execute_script "./stop-agents.sh"
            ;;
            
        19) # View Documentation
            show_documentation
            ;;
            
        20) # Show File Paths
            show_paths
            read -p "Press Enter to continue..."
            ;;
            
        21) # Run Custom Command
            run_custom
            ;;
            
        0)  # Exit
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
            
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
