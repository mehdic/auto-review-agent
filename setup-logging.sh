#!/bin/bash
# Enhanced logging system for agent conversations

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
LOG_DIR="$PROJECT_PATH/coordination/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📝 Setting up enhanced logging...${NC}"

# Create log directory structure
mkdir -p "$LOG_DIR/planner"
mkdir -p "$LOG_DIR/reviewer"
mkdir -p "$LOG_DIR/combined"

# Create logging wrapper for planner
cat > "$LOG_DIR/log_planner.sh" << 'EOF'
#!/bin/bash
PROJECT_PATH="$1"
LOG_FILE="$PROJECT_PATH/coordination/logs/planner/session_$(date +%Y%m%d_%H%M%S).log"
COMBINED_LOG="$PROJECT_PATH/coordination/logs/combined/agent_history.log"

# Log header
{
  echo "═══════════════════════════════════════════════════════════════"
  echo "PLANNER SESSION STARTED: $(date)"
  echo "═══════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE" >> "$COMBINED_LOG"

# Run the actual planner with logging
$PROJECT_PATH/../agent-system/planner-loop.sh "$@" 2>&1 | while IFS= read -r line; do
  echo "[$(date +%H:%M:%S)] $line" | tee -a "$LOG_FILE" >> "$COMBINED_LOG"
done

# Log footer
{
  echo "═══════════════════════════════════════════════════════════════"
  echo "PLANNER SESSION ENDED: $(date)"
  echo "═══════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE" >> "$COMBINED_LOG"
EOF

# Create logging wrapper for reviewer
cat > "$LOG_DIR/log_reviewer.sh" << 'EOF'
#!/bin/bash
PROJECT_PATH="$1"
LOG_FILE="$PROJECT_PATH/coordination/logs/reviewer/session_$(date +%Y%m%d_%H%M%S).log"
COMBINED_LOG="$PROJECT_PATH/coordination/logs/combined/agent_history.log"

# Log header
{
  echo "═══════════════════════════════════════════════════════════════"
  echo "REVIEWER SESSION STARTED: $(date)"
  echo "═══════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE" >> "$COMBINED_LOG"

# Run the actual reviewer with logging
$PROJECT_PATH/../agent-system/reviewer-loop.sh "$@" 2>&1 | while IFS= read -r line; do
  echo "[$(date +%H:%M:%S)] $line" | tee -a "$LOG_FILE" >> "$COMBINED_LOG"
done

# Log footer
{
  echo "═══════════════════════════════════════════════════════════════"
  echo "REVIEWER SESSION ENDED: $(date)"
  echo "═══════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE" >> "$COMBINED_LOG"
EOF

chmod +x "$LOG_DIR/log_planner.sh" "$LOG_DIR/log_reviewer.sh"

# Create tmux logging capture script
cat > "$LOG_DIR/capture_tmux.sh" << 'EOF'
#!/bin/bash
# Capture tmux panes periodically

PROJECT_PATH="$1"
LOG_DIR="$PROJECT_PATH/coordination/logs"
LLM_BIN="${LLM_BIN:-codex}"
LLM_LABEL="${LLM_LABEL:-${LLM_BIN^^}}"
LLM_LOG_FILE="$LOG_DIR/combined/${LLM_BIN}_conversations.log"

while tmux has-session -t agent_system_spec 2>/dev/null; do
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)

  # Capture planner pane
  echo "=== PLANNER CAPTURE at $(date) ===" >> "$LOG_DIR/planner/captures.log"
  tmux capture-pane -t agent_system_spec:planner -p >> "$LOG_DIR/planner/captures.log"
  echo -e "\n---\n" >> "$LOG_DIR/planner/captures.log"

  # Capture reviewer pane
  echo "=== REVIEWER CAPTURE at $(date) ===" >> "$LOG_DIR/reviewer/captures.log"
  tmux capture-pane -t agent_system_spec:reviewer -p >> "$LOG_DIR/reviewer/captures.log"
  echo -e "\n---\n" >> "$LOG_DIR/reviewer/captures.log"

  # Extract LLM conversations
  if grep -q "$LLM_BIN" "$LOG_DIR/planner/captures.log"; then
    echo "=== PLANNER ${LLM_LABEL} INTERACTION at $(date) ===" >> "$LLM_LOG_FILE"
    tail -50 "$LOG_DIR/planner/captures.log" | grep -A 20 -B 5 "$LLM_BIN" >> "$LLM_LOG_FILE"
  fi

  if grep -q "$LLM_BIN" "$LOG_DIR/reviewer/captures.log"; then
    echo "=== REVIEWER ${LLM_LABEL} INTERACTION at $(date) ===" >> "$LLM_LOG_FILE"
    tail -50 "$LOG_DIR/reviewer/captures.log" | grep -A 20 -B 5 "$LLM_BIN" >> "$LLM_LOG_FILE"
  fi

  sleep 30
done
EOF

chmod +x "$LOG_DIR/capture_tmux.sh"

# Create log viewer script
cat > view-logs.sh << 'EOF'
#!/bin/bash
# Interactive log viewer

PROJECT_PATH="${1:-/Users/mchaouachi/IdeaProjects/StockMonitor}"
LOG_DIR="$PROJECT_PATH/coordination/logs"
LLM_BIN="${LLM_BIN:-codex}"
LLM_LABEL="${LLM_LABEL:-${LLM_BIN^^}}"
LLM_LOG_FILE="$LOG_DIR/combined/${LLM_BIN}_conversations.log"

while true; do
  clear
  echo "═══════════════════════════════════════════════════════════════"
  echo "                    AGENT LOGS VIEWER"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "Select log to view:"
  echo "1) Combined agent history"
  echo "2) Planner sessions"
  echo "3) Reviewer sessions"
  echo "4) ${LLM_LABEL} conversations"
  echo "5) Latest activity (tail -f)"
  echo "6) Search logs"
  echo "0) Exit"
  echo ""
  read -p "Choice: " choice

  case $choice in
    1)
      less "$LOG_DIR/combined/agent_history.log"
      ;;
    2)
      ls -lt "$LOG_DIR/planner/" | head -10
      read -p "Enter filename: " fname
      less "$LOG_DIR/planner/$fname"
      ;;
    3)
      ls -lt "$LOG_DIR/reviewer/" | head -10
      read -p "Enter filename: " fname
      less "$LOG_DIR/reviewer/$fname"
      ;;
    4)
      less "$LLM_LOG_FILE"
      ;;
    5)
      tail -f "$LOG_DIR/combined/agent_history.log"
      ;;
    6)
      read -p "Search term: " term
      grep -r "$term" "$LOG_DIR" | less
      ;;
    0)
      exit 0
      ;;
  esac

  echo ""
  read -p "Press Enter to continue..."
done
EOF

chmod +x view-logs.sh

# Create JSON event logger
cat > "$LOG_DIR/log_json_events.sh" << 'EOF'
#!/bin/bash
# Log JSON changes as events

PROJECT_PATH="$1"
LOG_FILE="$PROJECT_PATH/coordination/logs/combined/json_events.log"
PROPOSALS_FILE="$PROJECT_PATH/coordination/task_proposals.json"

# Store initial state
LAST_HASH=$(md5sum "$PROPOSALS_FILE" 2>/dev/null | cut -d' ' -f1)

while true; do
  if [ -f "$PROPOSALS_FILE" ]; then
    CURRENT_HASH=$(md5sum "$PROPOSALS_FILE" | cut -d' ' -f1)
    
    if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
      echo "═══ JSON CHANGE DETECTED: $(date) ═══" >> "$LOG_FILE"
      
      # Get status
      STATUS=$(grep -o '"status"[^,]*' "$PROPOSALS_FILE" | cut -d'"' -f4)
      echo "Status: $STATUS" >> "$LOG_FILE"
      
      # Log the full content
      echo "Content:" >> "$LOG_FILE"
      python3 -m json.tool "$PROPOSALS_FILE" >> "$LOG_FILE" 2>/dev/null || cat "$PROPOSALS_FILE" >> "$LOG_FILE"
      echo "═══════════════════════════════════════════════" >> "$LOG_FILE"
      
      LAST_HASH="$CURRENT_HASH"
      
      # Also update main log
      echo "[JSON_UPDATE] Status changed to: $STATUS at $(date)" >> "$PROJECT_PATH/coordination/logs/combined/agent_history.log"
    fi
  fi
  
  sleep 5
done
EOF

chmod +x "$LOG_DIR/log_json_events.sh"

# Start background loggers
echo -e "${GREEN}Starting background loggers...${NC}"

# Start tmux capture
"$LOG_DIR/capture_tmux.sh" "$PROJECT_PATH" &
CAPTURE_PID=$!

# Start JSON event logger
"$LOG_DIR/log_json_events.sh" "$PROJECT_PATH" &
JSON_PID=$!

echo -e "${GREEN}✅ Logging system active!${NC}"
echo ""
echo -e "${BLUE}Log Locations:${NC}"
echo "  📁 All logs: $LOG_DIR/"
echo "  📄 Combined: $LOG_DIR/combined/agent_history.log"
echo "  💬 LLM transcripts: $LOG_DIR/combined/${LLM_BIN:-codex}_conversations.log"
echo "  🔄 JSON: $LOG_DIR/combined/json_events.log"
echo ""
echo -e "${BLUE}View logs with:${NC}"
echo "  ./view-logs.sh $PROJECT_PATH"
echo ""
echo -e "${BLUE}Active loggers (PIDs):${NC}"
echo "  Tmux capture: $CAPTURE_PID"
echo "  JSON monitor: $JSON_PID"
echo ""
echo -e "${YELLOW}To stop logging:${NC}"
echo "  kill $CAPTURE_PID $JSON_PID"
echo ""
echo "Logs will accumulate in the background as agents work."
