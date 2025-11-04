#!/bin/bash
# UNIFIED AGENT LOOP - Single Claude session does everything
# No more separate planner/reviewer - one agent does it all!

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

log_message "🚀 UNIFIED AGENT Starting for $FEATURE_NAME"
log_message "Project: $PROJECT_PATH"
log_message "Spec: $SPEC_FILE"
log_message "═══════════════════════════════════════════════════════════"

cd "$PROJECT_PATH"

# Create unified instructions
cat > "$COORDINATION_DIR/unified_instructions.txt" << 'INSTRUCTIONS'
You are a UNIFIED autonomous agent responsible for completing the entire task.

Your responsibilities:
1. READ and UNDERSTAND the specification
2. CREATE multiple implementation approaches
3. EVALUATE and SELECT the best approach
4. IMPLEMENT the chosen approach systematically
5. VERIFY completion against success criteria
6. CONTINUE until ALL criteria are met

═══════════════════════════════════════════════════════════

PHASE 1: PLANNING

Read the specification file to understand requirements.
Analyze current state and identify what needs to be done.
Create 2-3 different implementation approaches.

Write your proposals to: PROPOSALS_FILE_PLACEHOLDER

Format:
{
  "status": "planning",
  "proposals": [
    {
      "name": "approach_1",
      "description": "...",
      "steps": [...],
      "estimated_time": "..."
    }
  ]
}

═══════════════════════════════════════════════════════════

PHASE 2: REVIEW & SELECTION

Evaluate your own proposals objectively.
Consider: completeness, risk, time, complexity.

Select the best approach and add to the JSON:
{
  "status": "approved",
  "chosen_approach": "approach_X",
  "rationale": "why you chose this approach",
  "implementation_plan": {
    "step_1": "...",
    "step_2": "..."
  }
}

═══════════════════════════════════════════════════════════

PHASE 3: IMPLEMENTATION

Execute your chosen approach systematically:
- Follow your implementation plan step by step
- Work autonomously - don't ask permission
- Make decisions and move forward
- Fix tests, implement features, etc.
- Run tests frequently to verify progress
- Update progress in JSON file

Update status to "implementing" at start.

═══════════════════════════════════════════════════════════

PHASE 4: VERIFICATION

Check against the specification's "Definition of Done":
- Run all tests
- Verify all success criteria met
- Confirm no regressions

When COMPLETE, update JSON:
{
  "status": "completed",
  "completed_at": "timestamp",
  "final_state": "all 183 tests passing" (or whatever the goal was)
}

═══════════════════════════════════════════════════════════

CRITICAL INSTRUCTIONS:

1. You are AUTONOMOUS - don't ask for permission, just do it
2. When you have a choice, pick the most reasonable option
3. Document your decisions in the JSON file
4. Continue until the job is DONE
5. If stuck, try alternative approaches
6. Work through ALL phases in ONE session

The specification file is at: SPEC_FILE_PLACEHOLDER

Begin now with Phase 1: Planning
INSTRUCTIONS

# Replace placeholders
sed -i.bak "s|PROPOSALS_FILE_PLACEHOLDER|$PROPOSALS_FILE|g" "$COORDINATION_DIR/unified_instructions.txt"
sed -i.bak "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$COORDINATION_DIR/unified_instructions.txt"
rm -f "$COORDINATION_DIR/unified_instructions.txt.bak"

log_message ""
log_message "📋 Instructions prepared at: $COORDINATION_DIR/unified_instructions.txt"
log_message ""
log_message "═══════════════════════════════════════════════════════════"
log_message "Starting Claude in UNIFIED mode..."
log_message "Claude will:"
log_message "  1. Plan approaches"
log_message "  2. Review and select best approach"
log_message "  3. Implement systematically"
log_message "  4. Continue until completion"
log_message "═══════════════════════════════════════════════════════════"
log_message ""
echo ""
echo "Starting Claude in 3 seconds..."
echo "You'll see the full Claude UI and can monitor/interact as needed."
echo ""
sleep 3

# Start Claude with the unified instructions
echo "Sending instructions to Claude..."
echo ""

# Send the instructions file to Claude
cat "$COORDINATION_DIR/unified_instructions.txt" | claude

log_message ""
log_message "Claude session ended"
log_message "═══════════════════════════════════════════════════════════"

# Check final status
if [ -f "$PROPOSALS_FILE" ]; then
    STATUS=$(python3 -c "import json; print(json.load(open('$PROPOSALS_FILE')).get('status', 'unknown'))" 2>/dev/null || echo "unknown")
    log_message "Final status: $STATUS"

    if [ "$STATUS" = "completed" ]; then
        log_message "🎉 Task completed successfully!"
        exit 0
    else
        log_message "⚠️  Task not completed. Status: $STATUS"
        log_message "Check $PROPOSALS_FILE for details"
        exit 1
    fi
else
    log_message "⚠️  No proposals file created"
    exit 1
fi
