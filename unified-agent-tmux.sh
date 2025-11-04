#!/bin/bash
# UNIFIED AGENT - TMUX VERSION
# Uses tmux to show Claude UI while automating the initial prompt

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
SESSION_NAME="unified_agent_${FEATURE_NAME}"

mkdir -p "$COORDINATION_DIR/logs"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "🚀 UNIFIED AGENT (TMUX) Starting for $FEATURE_NAME"
log_message "Project: $PROJECT_PATH"
log_message "Spec: $SPEC_FILE"
log_message "Session: $SESSION_NAME"

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  UNIFIED AGENT - TMUX MODE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "This will:"
echo "  1. Create a tmux session with Claude"
echo "  2. Automatically send the task instructions to Claude"
echo "  3. You see the full Claude UI"
echo "  4. You can interact/monitor as needed"
echo ""
echo "To attach: tmux attach -t $SESSION_NAME"
echo "To detach: Ctrl+b d"
echo ""
echo "Starting in 3 seconds..."
sleep 3

# Create tmux session and start Claude
log_message "Creating tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_PATH"

# Start Claude in the session
log_message "Starting Claude in tmux"
tmux send-keys -t "$SESSION_NAME" "claude" Enter
sleep 5  # Wait for Claude to start

# Send the instructions
log_message "Sending task instructions to Claude"

PROMPT="Read the specification: $SPEC_FILE

You are a UNIFIED autonomous agent. Complete this task through these phases:

PHASE 1: PLANNING (5-10 min)
- Run mvn test to see current state (should be ~109/183 passing)
- Read and understand the spec
- Create 2-3 implementation approaches
- Write to: $PROPOSALS_FILE
- Set status: \"planning\"

PHASE 2: SELECTION (2-5 min)
- Evaluate your approaches
- Select the best one
- Update status: \"approved\"
- Add chosen_approach and implementation plan

PHASE 3: IMPLEMENTATION (30-90 min)
- Update status: \"implementing\"
- Execute your plan systematically
- Fix tests according to your approach
- Work autonomously - don't ask permission
- Run mvn test frequently
- Continue until 183/183 tests pass

PHASE 4: VERIFICATION (5 min)
- Confirm all success criteria met
- Update status: \"completed\"

CRITICAL:
- Be autonomous - make decisions, don't ask
- Current: 109/183 tests | Goal: 183/183 tests
- ALL phases in ONE session
- Don't stop until Definition of Done is met

Start with Phase 1 now."

# Send the prompt to Claude
tmux send-keys -t "$SESSION_NAME" "$PROMPT" Enter

log_message "Instructions sent to Claude"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ Claude is now running!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "To watch Claude work:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo "While attached:"
echo "  - Watch Claude work through all 4 phases"
echo "  - Interact if needed"
echo "  - Detach with: Ctrl+b d"
echo ""
echo "Monitor progress in another terminal:"
echo "  watch -n 10 'cat $PROPOSALS_FILE | jq .status'"
echo "  tail -f $LOG_FILE"
echo ""
echo "When done, check status:"
echo "  cat $PROPOSALS_FILE | jq .status"
echo ""
log_message "Session ready. Attach with: tmux attach -t $SESSION_NAME"
log_message "Claude is working. Monitor the session to see progress."

# Optional: Auto-attach
read -p "Attach to session now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_message "Attaching to session (Ctrl+b d to detach)"
    tmux attach -t "$SESSION_NAME"
fi

echo ""
echo "Script complete. Claude is still running in tmux session: $SESSION_NAME"
echo "Attach anytime with: tmux attach -t $SESSION_NAME"
