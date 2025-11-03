#!/bin/bash
# Direct Implementation Starter

echo "Forcing planner to implement approved proposal..."

tmux send-keys -t agent_system_spec:planner C-c 2>/dev/null
sleep 1

tmux send-keys -t agent_system_spec:planner "claude" Enter 2>/dev/null
sleep 4

tmux send-keys -t agent_system_spec:planner "Read /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json which shows approved status with approach_1.

Implement the Infrastructure-First Strategy to fix 75 failing tests.

Current: 108/183 tests passing
Goal: 183/183 tests passing

Start with Phase 1 from the approved proposal. Run mvn test first to see failures. Fix tests systematically. Work autonomously.

Begin now." Enter 2>/dev/null

echo "✅ Command sent. Check planner window in 10 seconds."
echo "Run: tmux attach -t agent_system_spec"
echo "Then: Ctrl+b 0"
