#!/bin/bash
# Interactive log viewer with auto-setup

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
LOG_DIR="$PROJECT_PATH/coordination/logs"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${YELLOW}Log directory not found. Creating it now...${NC}"
    mkdir -p "$LOG_DIR/combined"
    mkdir -p "$LOG_DIR/planner"
    mkdir -p "$LOG_DIR/reviewer"
    
    # Create initial log files
    echo "[$(date)] Logging system initialized" > "$LOG_DIR/combined/agent_history.log"
    echo "[$(date)] Claude conversations log created" > "$LOG_DIR/combined/claude_conversations.log"
    echo "[$(date)] JSON events log created" > "$LOG_DIR/combined/json_events.log"
    
    echo -e "${GREEN}✓ Log directories created${NC}"
    echo ""
fi

# Function to view log safely
view_log() {
    local log_file=$1
    if [ -f "$log_file" ]; then
        if [ -s "$log_file" ]; then
            less "$log_file"
        else
            echo -e "${YELLOW}Log file exists but is empty${NC}"
            echo "File: $log_file"
            echo ""
            echo "This is normal if:"
            echo "- Agents haven't been run yet"
            echo "- Logging was just enabled"
            echo "- No activity has occurred"
        fi
    else
        echo -e "${RED}Log file not found: $log_file${NC}"
        echo ""
        echo "Creating empty log file..."
        touch "$log_file"
        echo "[$(date)] Log file created" > "$log_file"
        echo -e "${GREEN}✓ Created: $log_file${NC}"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

# Function to list log files in directory
list_logs() {
    local dir=$1
    if [ -d "$dir" ]; then
        local count=$(ls -1 "$dir" 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            ls -lt "$dir" 2>/dev/null | head -10
            return 0
        else
            echo -e "${YELLOW}No log files in this directory yet${NC}"
            return 1
        fi
    else
        echo -e "${RED}Directory not found: $dir${NC}"
        return 1
    fi
}

# Main menu loop
while true; do
    clear
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    AGENT LOGS VIEWER"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo -e "${BLUE}Log Directory: $LOG_DIR${NC}"
    echo ""
    echo "Select log to view:"
    echo "1) Combined agent history"
    echo "2) Planner sessions"
    echo "3) Reviewer sessions"
    echo "4) Claude conversations"
    echo "5) JSON events"
    echo "6) Latest activity (tail -f)"
    echo "7) Search all logs"
    echo "8) Show log statistics"
    echo "9) Clear old logs (cleanup)"
    echo "0) Exit"
    echo ""
    read -p "Choice: " choice
    
    case $choice in
        1)
            view_log "$LOG_DIR/combined/agent_history.log"
            ;;
        2)
            echo -e "${BLUE}Planner session logs:${NC}"
            if list_logs "$LOG_DIR/planner/"; then
                read -p "Enter filename (or press Enter to skip): " fname
                if [ -n "$fname" ]; then
                    view_log "$LOG_DIR/planner/$fname"
                fi
            else
                read -p "Press Enter to continue..."
            fi
            ;;
        3)
            echo -e "${BLUE}Reviewer session logs:${NC}"
            if list_logs "$LOG_DIR/reviewer/"; then
                read -p "Enter filename (or press Enter to skip): " fname
                if [ -n "$fname" ]; then
                    view_log "$LOG_DIR/reviewer/$fname"
                fi
            else
                read -p "Press Enter to continue..."
            fi
            ;;
        4)
            view_log "$LOG_DIR/combined/claude_conversations.log"
            ;;
        5)
            view_log "$LOG_DIR/combined/json_events.log"
            ;;
        6)
            echo -e "${BLUE}Showing latest activity (Ctrl+C to stop):${NC}"
            echo ""
            if [ -f "$LOG_DIR/combined/agent_history.log" ]; then
                tail -f "$LOG_DIR/combined/agent_history.log"
            else
                echo -e "${YELLOW}No history log yet. Creating one...${NC}"
                touch "$LOG_DIR/combined/agent_history.log"
                echo "[$(date)] Waiting for activity..." > "$LOG_DIR/combined/agent_history.log"
                tail -f "$LOG_DIR/combined/agent_history.log"
            fi
            ;;
        7)
            read -p "Search term: " term
            if [ -n "$term" ]; then
                echo -e "${BLUE}Searching for '$term' in all logs...${NC}"
                echo ""
                if [ -d "$LOG_DIR" ]; then
                    grep -r "$term" "$LOG_DIR" 2>/dev/null | head -50
                    if [ $? -ne 0 ]; then
                        echo -e "${YELLOW}No matches found${NC}"
                    fi
                else
                    echo -e "${RED}Log directory not found${NC}"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        8)
            echo -e "${BLUE}Log Statistics:${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            if [ -d "$LOG_DIR" ]; then
                echo "Total log files: $(find "$LOG_DIR" -type f -name "*.log" 2>/dev/null | wc -l)"
                echo "Total size: $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
                echo ""
                echo "By directory:"
                for dir in combined planner reviewer; do
                    if [ -d "$LOG_DIR/$dir" ]; then
                        count=$(ls -1 "$LOG_DIR/$dir" 2>/dev/null | wc -l)
                        size=$(du -sh "$LOG_DIR/$dir" 2>/dev/null | cut -f1)
                        echo "  $dir: $count files, $size"
                    fi
                done
                echo ""
                if [ -f "$LOG_DIR/combined/agent_history.log" ]; then
                    lines=$(wc -l < "$LOG_DIR/combined/agent_history.log")
                    echo "History log lines: $lines"
                fi
            else
                echo -e "${RED}Log directory not found${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
        9)
            echo -e "${YELLOW}Clean up old logs?${NC}"
            echo "This will delete logs older than 7 days"
            read -p "Continue? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                if [ -d "$LOG_DIR" ]; then
                    find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null
                    echo -e "${GREEN}✓ Old logs cleaned${NC}"
                else
                    echo -e "${RED}Log directory not found${NC}"
                fi
            fi
            read -p "Press Enter to continue..."
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
