#!/bin/bash
# Check what's actually in each tmux window

echo "🔍 Checking tmux session: agent_system_spec"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if session exists
if ! tmux has-session -t agent_system_spec 2>/dev/null; then
    echo "❌ No tmux session 'agent_system_spec' found"
    echo ""
    echo "Sessions found:"
    tmux list-sessions 2>/dev/null || echo "  (none)"
    exit 1
fi

echo "✅ Session exists"
echo ""

# List windows
echo "Windows in session:"
tmux list-windows -t agent_system_spec
echo ""

# Check each window content
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 PLANNER WINDOW (0) - Last 20 lines:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tmux capture-pane -t agent_system_spec:0 -p | tail -20
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ REVIEWER WINDOW (1) - Last 20 lines:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tmux capture-pane -t agent_system_spec:1 -p | tail -20
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 MONITOR WINDOW (2) - Last 20 lines:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tmux capture-pane -t agent_system_spec:2 -p | tail -20
echo ""

# Check for Claude processes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Claude Processes Running:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ps aux | grep claude | grep -v grep | head -10
CLAUDE_COUNT=$(ps aux | grep claude | grep -v grep | wc -l)
if [ $CLAUDE_COUNT -eq 0 ]; then
    echo "❌ No Claude processes running!"
else
    echo ""
    echo "✅ Found $CLAUDE_COUNT Claude process(es)"
fi
echo ""

# Check logs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Recent Log Entries:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "/Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/notifications.log" ]; then
    tail -15 "/Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/notifications.log"
else
    echo "⚠️  No log file found"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 DIAGNOSIS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $CLAUDE_COUNT -gt 0 ]; then
    echo "✅ Agents appear to be running"
else
    echo "❌ Agents are NOT running - loops may have exited"
    echo ""
    echo "Possible causes:"
    echo "  1. Scripts finished/exited"
    echo "  2. Error during startup"
    echo "  3. Claude CLI not found in PATH"
    echo ""
    echo "Check the window contents above for errors"
fi
echo ""
