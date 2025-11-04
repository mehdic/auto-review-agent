#!/bin/bash
# UNIFIED AGENT - INTERACTIVE VERSION
# Shows Claude UI with instructions pre-filled, you press enter to start

PROJECT_PATH="$1"
SPEC_FILE="$2"
FEATURE_NAME="$3"

if [ -z "$PROJECT_PATH" ] || [ -z "$SPEC_FILE" ]; then
    echo "Usage: $0 <project_path> <spec_file> <feature_name>"
    exit 1
fi

COORDINATION_DIR="$PROJECT_PATH/coordination"
PROPOSALS_FILE="$COORDINATION_DIR/task_proposals.json"
LOG_FILE="$COORDINATION_DIR/logs/unified_agent.log"

mkdir -p "$COORDINATION_DIR/logs"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "🚀 UNIFIED AGENT (INTERACTIVE) Starting for $FEATURE_NAME"
log_message "Project: $PROJECT_PATH"
log_message "Spec: $SPEC_FILE"

cd "$PROJECT_PATH"

# Create the prompt that will be shown to user
PROMPT_TEXT="Read the specification file: $SPEC_FILE

You are a UNIFIED autonomous agent responsible for completing this entire task.

Your workflow:

**PHASE 1: PLANNING**
- Read and understand the specification
- Analyze current state (run tests to see current failures)
- Create 2-3 different implementation approaches
- Write proposals to: $PROPOSALS_FILE
- Format: {\"status\": \"planning\", \"proposals\": [...]}

**PHASE 2: REVIEW & SELECTION**
- Evaluate your own proposals objectively
- Select the best approach
- Update JSON: {\"status\": \"approved\", \"chosen_approach\": \"...\"}

**PHASE 3: IMPLEMENTATION**
- Execute your chosen approach systematically
- Update status to \"implementing\"
- Fix tests, implement features, etc.
- Work autonomously - make decisions and move forward
- Run tests frequently to verify progress
- Continue until ALL success criteria are met

**PHASE 4: VERIFICATION**
- Verify all items in \"Definition of Done\" are satisfied
- Update JSON: {\"status\": \"completed\"}

CRITICAL INSTRUCTIONS:
- You are AUTONOMOUS - don't ask permission, just do it
- When you have choices, pick the most reasonable option
- Continue until the job is DONE
- Work through ALL phases in this ONE session

Current state: 109/183 tests passing
Goal: 183/183 tests passing (all in spec's Definition of Done)

Start with Phase 1: Run tests and create proposals."

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  INTERACTIVE UNIFIED AGENT"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Instructions have been prepared."
echo ""
echo "Next steps:"
echo "  1. Claude will start with the prompt ready"
echo "  2. You'll see the full instructions in the chat"
echo "  3. Just press ENTER to start (or edit if needed)"
echo "  4. Watch Claude work through all 4 phases"
echo "  5. You can interact/guide at any time"
echo ""
echo "Starting Claude in 3 seconds..."
echo ""
sleep 3

# Start Claude with the prompt as the first message
# This way user sees the UI and can press enter or modify
echo "$PROMPT_TEXT" | claude

log_message "Claude session ended"

# Check final status
if [ -f "$PROPOSALS_FILE" ]; then
    STATUS=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('status', 'unknown'))" 2>/dev/null || echo "unknown")
    log_message "Final status: $STATUS"

    if [ "$STATUS" = "completed" ]; then
        log_message "🎉 Task completed successfully!"
        exit 0
    else
        log_message "⚠️  Task not completed. Status: $STATUS"
        exit 1
    fi
else
    log_message "⚠️  No proposals file created"
    exit 1
fi
