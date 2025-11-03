#!/bin/bash
# Direct Implementation Starter

echo "Forcing planner to implement approved proposal..."

tmux send-keys -t agent_system_spec:planner C-c 2>/dev/null
sleep 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLM_BIN="${LLM_BIN:-codex}"
LLM_MODEL="${LLM_MODEL:-}"
if [[ -z "${LLM_ARGS:-}" && -n "${LLM_ARGS_AUTO:-}" ]]; then
    LLM_ARGS="$LLM_ARGS_AUTO"
fi
LLM_ARGS="${LLM_ARGS:-}"
export LLM_BIN LLM_MODEL LLM_ARGS
LLM_SH="$SCRIPT_DIR/scripts/llm.sh"
LLM_SH_ESCAPED=$(printf '%q' "$LLM_SH")
if ! command -v "$LLM_BIN" &> /dev/null; then
    echo "Missing LLM CLI: $LLM_BIN" >&2
    exit 1
fi
if [ ! -x "$LLM_SH" ]; then
    echo "Missing LLM shim at $LLM_SH" >&2
    exit 1
fi
tmux send-keys -t agent_system_spec:planner "$LLM_SH_ESCAPED repl" Enter 2>/dev/null
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
