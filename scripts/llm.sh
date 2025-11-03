#!/usr/bin/env bash
set -euo pipefail

: "${LLM_BIN:=claude}"
: "${LLM_MODEL:=}"
: "${LLM_ARGS:=}"

if [[ $# -lt 1 ]]; then
  echo "Usage: llm.sh {chat|repl} [args...]" >&2
  exit 2
fi

cmd="$1"; shift || true

# shellcheck disable=SC2206
LLM_ARGS_ARRAY=($LLM_ARGS)

case "${LLM_BIN}" in
  claude)
    case "$cmd" in
      chat)
        exec claude -p ${LLM_MODEL:+--model "$LLM_MODEL"} "${LLM_ARGS_ARRAY[@]}" "$@"
        ;;
      repl)
        exec claude "${LLM_ARGS_ARRAY[@]}" "$@"
        ;;
      *)
        echo "Usage: llm.sh {chat|repl}" >&2
        exit 2
        ;;
    esac
    ;;
  codex)
    case "$cmd" in
      chat)
        exec codex exec ${LLM_MODEL:+--model "$LLM_MODEL"} "${LLM_ARGS_ARRAY[@]}" -- "$@"
        ;;
      repl)
        exec codex "${LLM_ARGS_ARRAY[@]}" "$@"
        ;;
      *)
        echo "Usage: llm.sh {chat|repl}" >&2
        exit 2
        ;;
    esac
    ;;
  *)
    echo "Unknown LLM_BIN=$LLM_BIN" >&2
    exit 2
    ;;
esac
