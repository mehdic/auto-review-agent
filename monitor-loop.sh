#!/bin/bash
# Monitor script for agent system

PROJECT_PATH="$1"

# Colors
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 MONITOR - Task System Status${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

while true; do
  clear
  echo -e "${BLUE}📊 MONITOR - Task System Status${NC}"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "=== Active Work ==="
  if [ -f "$PROJECT_PATH/coordination/active_work_registry.json" ]; then
    cat "$PROJECT_PATH/coordination/active_work_registry.json" | python3 -m json.tool 2>/dev/null || cat "$PROJECT_PATH/coordination/active_work_registry.json"
  else
    echo '{"agents": {}}'
  fi
  echo ""
  echo "=== Task Proposals Status ==="
  if [ -f "$PROJECT_PATH/coordination/task_proposals.json" ]; then
    cat "$PROJECT_PATH/coordination/task_proposals.json" | python3 -m json.tool | head -20 2>/dev/null || cat "$PROJECT_PATH/coordination/task_proposals.json" | head -20
  else
    echo '{"proposals": [], "status": "idle"}'
  fi
  echo ""
  echo "=== Recent Logs ==="
  if [ -f "$PROJECT_PATH/coordination/logs/notifications.log" ]; then
    tail -n 10 "$PROJECT_PATH/coordination/logs/notifications.log"
  else
    echo "No logs yet..."
  fi
  echo ""
  echo "Press Ctrl+C to stop monitoring"
  sleep 2
done
