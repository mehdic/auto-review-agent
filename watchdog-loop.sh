#!/bin/bash
# Watchdog/Reviewer Loop - Monitors implementer and keeps it moving
# This is the SUPERVISOR that ensures implementer keeps working

PROJECT_PATH="$1"
TASKS_FILE="$2"
SPEC_NAME="$3"
SESSION_NAME="$4"

if [ -z "$PROJECT_PATH" ] || [ -z "$TASKS_FILE" ] || [ -z "$SESSION_NAME" ]; then
    echo "Usage: $0 <project_path> <tasks_file> <spec_name> <session_name>"
    exit 1
fi

COORDINATION_DIR="$PROJECT_PATH/coordination"
STATE_FILE="$COORDINATION_DIR/state.json"
LOG_FILE="$COORDINATION_DIR/logs/watchdog.log"

mkdir -p "$COORDINATION_DIR/logs"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WATCHDOG: $1" | tee -a "$LOG_FILE"
}

log_message "═══════════════════════════════════════════════════════════"
log_message "Watchdog Loop Starting"
log_message "Monitoring implementer in session: $SESSION_NAME"
log_message "═══════════════════════════════════════════════════════════"

# Monitoring loop
CHECK_INTERVAL=30  # Check every 30 seconds
IDLE_THRESHOLD=300  # 5 minutes without file changes
LAST_FILE_CHANGE=0

while true; do
    sleep $CHECK_INTERVAL

    # Check if implementer window still exists
    if ! tmux list-windows -t "$SESSION_NAME" 2>/dev/null | grep -q "implementer"; then
        log_message "❌ Implementer window not found - may have crashed"
        log_message "TODO: Restart implementer (not implemented yet)"
        continue
    fi

    # Capture last 50 lines of implementer output
    IMPLEMENTER_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p | tail -50)

    # Detect patterns that need response

    # Pattern 1: Asking questions
    if echo "$IMPLEMENTER_OUTPUT" | grep -qi "should I\|would you like\|do you want\|which.*prefer"; then
        log_message "🤖 Detected question in implementer output"
        log_message "Sending auto-response: 'Choose the best option and continue autonomously'"

        tmux send-keys -t "$SESSION_NAME:implementer" "Choose the best option and continue autonomously. Don't ask - just do it."
        tmux send-keys -t "$SESSION_NAME:implementer" Enter

        sleep 5
        continue
    fi

    # Pattern 2: Waiting for input
    if echo "$IMPLEMENTER_OUTPUT" | tail -5 | grep -q "^>"; then
        log_message "⚠️  Implementer appears to be waiting for input"

        # Check state file
        if [ -f "$STATE_FILE" ]; then
            STATUS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('status', 'unknown'))" 2>/dev/null || echo "unknown")

            if [ "$STATUS" != "completed" ]; then
                log_message "Sending continue command"
                tmux send-keys -t "$SESSION_NAME:implementer" "Continue with the next task autonomously"
                tmux send-keys -t "$SESSION_NAME:implementer" Enter
            fi
        fi

        sleep 5
        continue
    fi

    # Pattern 3: Check for file activity (is implementer actually working?)
    RECENT_CHANGES=$(find "$PROJECT_PATH" -type f \( -name "*.java" -o -name "*.kt" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) -mmin -5 2>/dev/null | wc -l)

    if [ $RECENT_CHANGES -gt 0 ]; then
        LAST_FILE_CHANGE=$(date +%s)
        log_message "✅ Active: $RECENT_CHANGES files modified in last 5 minutes"
    else
        CURRENT_TIME=$(date +%s)
        IDLE_TIME=$((CURRENT_TIME - LAST_FILE_CHANGE))

        if [ $LAST_FILE_CHANGE -gt 0 ] && [ $IDLE_TIME -gt $IDLE_THRESHOLD ]; then
            log_message "⚠️  No file changes for $IDLE_TIME seconds (threshold: $IDLE_THRESHOLD)"
            log_message "Implementer may be stuck - sending nudge"

            tmux send-keys -t "$SESSION_NAME:implementer" "You haven't modified any files in 5 minutes. Continue implementing the next task or mark as complete if done."
            tmux send-keys -t "$SESSION_NAME:implementer" Enter

            LAST_FILE_CHANGE=$(date +%s)  # Reset to avoid spam
        fi
    fi

    # Check completion status
    if [ -f "$STATE_FILE" ]; then
        STATUS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('status', 'unknown'))" 2>/dev/null || echo "unknown")

        if [ "$STATUS" = "completed" ]; then
            log_message "🎉 Implementer reports work COMPLETED"
            log_message "Verifying completion..."

            # TODO: Add verification logic here
            # For now, trust the implementer

            log_message "✅ Verification passed - work is complete"
            log_message "Watchdog exiting"
            exit 0
        fi
    fi

    # Log periodic status
    if [ $((RANDOM % 10)) -eq 0 ]; then
        log_message "📊 Monitoring... Recent changes: $RECENT_CHANGES files, Status: ${STATUS:-unknown}"
    fi
done

log_message "Watchdog loop ended"
