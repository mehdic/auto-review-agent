#!/bin/bash
# Tech Lead Dashboard Display Script
# Called by watch command in tmux window 1

COORDINATION_DIR="$1"

echo "═══════════════════════════════════════════════════════════"
echo "  TECH LEAD DASHBOARD"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Last 20 observations:"
echo "───────────────────────────────────────────────────────────"

if [ -f "$COORDINATION_DIR/logs/watchdog.log" ]; then
    tail -20 "$COORDINATION_DIR/logs/watchdog.log"
else
    echo "Waiting for tech lead to start..."
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Current Status:"
echo "───────────────────────────────────────────────────────────"

if [ -f "$COORDINATION_DIR/state.json" ]; then
    cat "$COORDINATION_DIR/state.json" | jq -r '.status, .message' 2>/dev/null || echo "Initializing..."
else
    echo "Initializing..."
fi

echo ""
echo "Press Ctrl-C to exit, Ctrl-b 0 for developer window"
