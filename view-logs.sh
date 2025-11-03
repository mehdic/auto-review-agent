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
