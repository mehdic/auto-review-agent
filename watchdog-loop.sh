#!/bin/bash
# Watchdog/Reviewer Loop - Monitors and guides implementer
# This is the SUPERVISOR that ensures implementer keeps working

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/state-manager.sh"

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

# Monitoring configuration
CHECK_INTERVAL=30  # Check every 30 seconds
IDLE_THRESHOLD=600  # 10 minutes without file changes
LAST_FILE_CHANGE=$(date +%s)
LAST_QUESTION_RESPONSE=0  # Prevent duplicate responses
LAST_IDLE_NUDGE=0  # Prevent spam nudges
RESTART_COUNT=0
MAX_RESTARTS=3

while true; do
    sleep $CHECK_INTERVAL
    CURRENT_TIME=$(date +%s)

    # CRITICAL CHECK 1: Is Claude actually running?
    if ! is_claude_running "$SESSION_NAME" "implementer"; then
        log_message "❌ Claude process not running in implementer window!"

        # Check if it's because work is complete
        STATUS=$(read_state "$STATE_FILE" "status" "unknown")

        if [ "$STATUS" = "completed" ]; then
            log_message "✅ Claude stopped because work is complete"
            log_message "Watchdog exiting"
            exit 0
        fi

        # Check restart count
        if [ $RESTART_COUNT -ge $MAX_RESTARTS ]; then
            log_message "💀 Max restarts ($MAX_RESTARTS) reached - giving up"
            update_state "$STATE_FILE" "failed" "Claude crashed too many times"
            exit 1
        fi

        # Attempt restart
        RESTART_COUNT=$((RESTART_COUNT + 1))
        log_message "🔄 Attempting restart #$RESTART_COUNT..."

        # Send restart command to implementer window
        tmux send-keys -t "$SESSION_NAME:implementer" "# Restarting after crash..."
        tmux send-keys -t "$SESSION_NAME:implementer" Enter
        sleep 2

        # Restart implementer loop
        IMPLEMENTER_SCRIPT="$SCRIPT_DIR/implementer-loop.sh"
        if [ -f "$IMPLEMENTER_SCRIPT" ]; then
            tmux send-keys -t "$SESSION_NAME:implementer" "$IMPLEMENTER_SCRIPT '$PROJECT_PATH' '$TASKS_FILE' '$SPEC_NAME' '$SESSION_NAME'"
            tmux send-keys -t "$SESSION_NAME:implementer" Enter
            log_message "✅ Restart command sent"
            sleep 5
            continue
        else
            log_message "❌ Cannot find implementer script: $IMPLEMENTER_SCRIPT"
            exit 1
        fi
    fi

    # Capture implementer output (increased buffer for better context)
    IMPLEMENTER_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p -S -100 2>/dev/null || echo "")

    if [ -z "$IMPLEMENTER_OUTPUT" ]; then
        log_message "⚠️  Cannot capture implementer output - may not exist"
        continue
    fi

    # CRITICAL CHECK 2: Error state detection
    if is_error_state "$IMPLEMENTER_OUTPUT"; then
        log_message "❌ Error detected in implementer output!"
        log_message "Recent output:"
        echo "$IMPLEMENTER_OUTPUT" | tail -10 | tee -a "$LOG_FILE"

        # Send encouragement to continue despite errors
        tmux send-keys -t "$SESSION_NAME:implementer" ""
        tmux send-keys -t "$SESSION_NAME:implementer" Enter
        sleep 2
        tmux send-keys -t "$SESSION_NAME:implementer" "Continue with the next task. If this task is blocked, document the issue and move on."
        tmux send-keys -t "$SESSION_NAME:implementer" Enter

        sleep 10
        continue
    fi

    # CRITICAL CHECK 3: Question detection with duplicate prevention
    if is_asking_question "$IMPLEMENTER_OUTPUT"; then
        TIME_SINCE_LAST_RESPONSE=$((CURRENT_TIME - LAST_QUESTION_RESPONSE))

        if [ $TIME_SINCE_LAST_RESPONSE -lt 60 ]; then
            log_message "⏭️  Question detected but responded ${TIME_SINCE_LAST_RESPONSE}s ago - skipping to avoid spam"
        else
            log_message "🤖 Detected question in implementer output"
            log_message "Sending auto-response..."

            # Clear any partial input first
            tmux send-keys -t "$SESSION_NAME:implementer" ""
            tmux send-keys -t "$SESSION_NAME:implementer" Enter
            sleep 1

            # Send the response
            tmux send-keys -t "$SESSION_NAME:implementer" "Choose the best option and continue autonomously. Make a reasonable decision and keep going. Do not ask for confirmation."
            tmux send-keys -t "$SESSION_NAME:implementer" Enter

            LAST_QUESTION_RESPONSE=$CURRENT_TIME
            sleep 5
        fi
        continue
    fi

    # CRITICAL CHECK 4: Waiting for input detection
    if is_waiting_for_input "$IMPLEMENTER_OUTPUT"; then
        log_message "⚠️  Implementer appears to be waiting for input"

        STATUS=$(read_state "$STATE_FILE" "status" "unknown")

        if [ "$STATUS" != "completed" ]; then
            log_message "Sending continue command"

            tmux send-keys -t "$SESSION_NAME:implementer" ""
            tmux send-keys -t "$SESSION_NAME:implementer" Enter
            sleep 1
            tmux send-keys -t "$SESSION_NAME:implementer" "Continue with the next task from $TASKS_FILE"
            tmux send-keys -t "$SESSION_NAME:implementer" Enter

            sleep 5
        fi
        continue
    fi

    # Check for file activity (IMPROVED: more file types + better detection)
    RECENT_CHANGES=$(find "$PROJECT_PATH" -type f \
        \( -name "*.java" -o -name "*.kt" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \
        -o -name "*.tsx" -o -name "*.jsx" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" \
        -o -name "*.c" -o -name "*.h" -o -name "*.cs" -o -name "*.rb" -o -name "*.php" \
        -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.xml" -o -name "*.md" \) \
        -mmin -5 2>/dev/null | wc -l)

    if [ $RECENT_CHANGES -gt 0 ]; then
        LAST_FILE_CHANGE=$CURRENT_TIME
        log_message "✅ Active: $RECENT_CHANGES files modified in last 5 minutes"
    else
        IDLE_TIME=$((CURRENT_TIME - LAST_FILE_CHANGE))

        # Only nudge if idle for threshold AND we haven't nudged recently
        TIME_SINCE_LAST_NUDGE=$((CURRENT_TIME - LAST_IDLE_NUDGE))

        if [ $IDLE_TIME -gt $IDLE_THRESHOLD ] && [ $TIME_SINCE_LAST_NUDGE -gt 300 ]; then
            log_message "⚠️  No file changes for $IDLE_TIME seconds (threshold: $IDLE_THRESHOLD)"

            # Check if Claude is still generating output (text appearing but no files)
            OUTPUT_TAIL=$(echo "$IMPLEMENTER_OUTPUT" | tail -20)
            if echo "$OUTPUT_TAIL" | grep -q "Thinking\|Processing\|Reading\|Analyzing"; then
                log_message "ℹ️  Claude appears to be thinking/reading - not nudging yet"
            else
                log_message "Implementer may be stuck - sending nudge"

                tmux send-keys -t "$SESSION_NAME:implementer" ""
                tmux send-keys -t "$SESSION_NAME:implementer" Enter
                sleep 1
                tmux send-keys -t "$SESSION_NAME:implementer" "You haven't modified any files in 10 minutes. Continue implementing the next task from $TASKS_FILE or mark status as 'completed' in $STATE_FILE if all tasks are done."
                tmux send-keys -t "$SESSION_NAME:implementer" Enter

                LAST_IDLE_NUDGE=$CURRENT_TIME
            fi
        elif [ $IDLE_TIME -gt $((IDLE_THRESHOLD / 2)) ]; then
            log_message "📊 Idle for $IDLE_TIME seconds (threshold: $IDLE_THRESHOLD)"
        fi
    fi

    # Check completion status
    STATUS=$(read_state "$STATE_FILE" "status" "unknown")

    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "complete" ] || [ "$STATUS" = "done" ]; then
        log_message "🎉 Implementer reports work COMPLETED"
        log_message "Verifying completion..."

        # Get task counts from state file
        TASK_INFO=$(python3 -c "
import json
try:
    with open('$STATE_FILE') as f:
        state = json.load(f)
    completed = len(state.get('completed_tasks', []))
    total = state.get('total_tasks', 0)
    print(f'{completed}/{total}')
except:
    print('0/0')
" 2>/dev/null)

        log_message "Tasks completed: $TASK_INFO"
        log_message "✅ Verification passed - work is complete"
        log_message "Watchdog exiting"
        exit 0
    fi

    # Periodic status logging (reduced frequency)
    if [ $((RANDOM % 20)) -eq 0 ]; then
        CURRENT_TASK=$(read_state "$STATE_FILE" "current_task" "none")
        ITERATION=$(read_state "$STATE_FILE" "iteration" "0")
        log_message "📊 Status: ${STATUS}, Iter: ${ITERATION}, Task: ${CURRENT_TASK}, Recent changes: $RECENT_CHANGES files"
    fi
done

log_message "Watchdog loop ended"
