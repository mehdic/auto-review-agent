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

    # Check if session still exists (exit gracefully if user killed it)
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        log_message "Session $SESSION_NAME no longer exists - exiting gracefully"
        exit 0
    fi

    # CRITICAL CHECK 1: Is implementer-loop.sh still running?
    if ! is_implementer_alive "$SESSION_NAME" "implementer"; then
        log_message "❌ Implementer loop crashed or exited!"

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

        # Check what crashed: Claude in window or background loop?
        # Get pane PID and check if Claude is running
        PANE_PID=$(tmux list-panes -t "$SESSION_NAME:implementer" -F "#{pane_pid}" 2>/dev/null | head -1)
        CLAUDE_RUNNING=1
        if [ -n "$PANE_PID" ]; then
            pgrep -P "$PANE_PID" "claude" >/dev/null 2>&1 && CLAUDE_RUNNING=0
        fi

        # If Claude crashed, restart it in the window
        if [ $CLAUDE_RUNNING -ne 0 ]; then
            log_message "Claude process crashed, restarting in window..."
            tmux send-keys -t "$SESSION_NAME:implementer" -X cancel  # Clear any pending input
            tmux send-keys -t "$SESSION_NAME:implementer" "" Enter
            sleep 1
            tmux send-keys -t "$SESSION_NAME:implementer" "cd '$PROJECT_PATH' && claude"
            tmux send-keys -t "$SESSION_NAME:implementer" Enter
            sleep 3
        fi

        # Restart background implementer loop
        IMPLEMENTER_SCRIPT="$SCRIPT_DIR/implementer-loop.sh"
        if [ -f "$IMPLEMENTER_SCRIPT" ]; then
            # Kill old instance if it exists and WAIT for it to die
            if [ -f "$PROJECT_PATH/coordination/implementer.pid" ]; then
                OLD_PID=$(cat "$PROJECT_PATH/coordination/implementer.pid" 2>/dev/null)
                if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
                    log_message "Killing old implementer process (PID: $OLD_PID)"
                    kill -15 "$OLD_PID" 2>/dev/null  # Try SIGTERM first

                    # Wait up to 5 seconds for graceful exit
                    for i in {1..10}; do
                        if ! kill -0 "$OLD_PID" 2>/dev/null; then
                            log_message "Old process exited gracefully"
                            break
                        fi
                        sleep 0.5
                    done

                    # If still alive, force kill
                    if kill -0 "$OLD_PID" 2>/dev/null; then
                        log_message "Force killing stubborn process"
                        kill -9 "$OLD_PID" 2>/dev/null || true
                        sleep 1
                    fi
                fi
            fi

            # Start new background process
            nohup "$IMPLEMENTER_SCRIPT" "$PROJECT_PATH" "$TASKS_FILE" "$SPEC_NAME" "$SESSION_NAME" \
                > "$PROJECT_PATH/coordination/logs/implementer-loop.log" 2>&1 &
            NEW_PID=$!
            echo "$NEW_PID" > "$PROJECT_PATH/coordination/implementer.pid"
            log_message "✅ Restart complete (background PID: $NEW_PID)"
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

    # CRITICAL CHECK 3: Giving up / Skipping detection
    if is_giving_up "$IMPLEMENTER_OUTPUT"; then
        log_message "⚠️  Implementer appears to be giving up on a task!"

        # Extract what they're giving up on
        BLOCKED_TASK=$(extract_blocked_task "$IMPLEMENTER_OUTPUT")
        log_message "Blocked task: $BLOCKED_TASK"

        # Check retry count for this pattern
        RETRY_KEY=$(echo "$BLOCKED_TASK" | md5sum | cut -d' ' -f1)
        RETRY_FILE="$COORDINATION_DIR/retries_$RETRY_KEY.txt"

        if [ ! -f "$RETRY_FILE" ]; then
            echo "0" > "$RETRY_FILE"
        fi

        RETRY_COUNT=$(cat "$RETRY_FILE")
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "$RETRY_COUNT" > "$RETRY_FILE"

        log_message "This is retry attempt #$RETRY_COUNT for this task"

        if [ $RETRY_COUNT -le 3 ]; then
            log_message "🔍 Generating reviewer feedback with solutions..."

            # Generate analysis and solutions using Claude
            REVIEW_PROMPT="You are a tech lead analyzing why a developer got stuck.

CONTEXT AND MAIN GOAL:
Our main goal is to complete each and every task specified in the tasks.md file, all while respecting the plan.md and the spec.md file. Nothing should break the constitution defined in the constitution.md file.

The developer has been working on this tasks.md file, so you should monitor their progress in each call. Maybe also check the changelog to see if some things are missing or are already done. You need to confirm and review the developer's task. Also provide solutions and ultrathink when needed to propose possible fixes that haven't been tried before. Keep a log file called proposed-solutions.md in the agents folder for each problem and solution you proposed.

Developer's last output (what they're stuck on):
\`\`\`
$IMPLEMENTER_OUTPUT
\`\`\`

Your job:
1. Identify the SPECIFIC technical problem (don't just restate what they said)
2. Provide 3-5 CONCRETE solutions the implementer should try
3. Be SPECIFIC with file paths, function names, exact commands
4. Format as actionable steps they can execute immediately

Respond in this format:
PROBLEM: [one sentence diagnosis]

SOLUTIONS TO TRY:
1. [Specific action with exact details]
2. [Another specific action]
3. [etc]

EXAMPLE APPROACHES:
- [Reference similar patterns in the codebase if relevant]
- [Suggest debugging commands to get more info]

IMPORTANT: When you finish your response, make sure the very last word you write is exactly: BAZINGA"

            REVIEWER_FEEDBACK=$(echo "$REVIEW_PROMPT" | claude --max-tokens 1000 2>/dev/null | tail -n +2)

            log_message "📝 Tech lead feedback generated"
            echo "$REVIEWER_FEEDBACK" | tee -a "$LOG_FILE"

            # Send feedback to developer
            tmux send-keys -t "$SESSION_NAME:implementer" ""
            tmux send-keys -t "$SESSION_NAME:implementer" Enter
            sleep 2

            # Send line-by-line with -- to prevent flag interpretation
            FEEDBACK_MESSAGE="TECH LEAD FEEDBACK (Attempt $RETRY_COUNT/3): Your tech lead has analyzed your situation. Here are specific solutions to try:

$REVIEWER_FEEDBACK

DO NOT SKIP THIS TASK. Try each solution systematically. Report results after each attempt."

            echo "$FEEDBACK_MESSAGE" | while IFS= read -r line; do
                tmux send-keys -t "$SESSION_NAME:implementer" -- "$line"
                tmux send-keys -t "$SESSION_NAME:implementer" Enter
                sleep 0.05
            done
            tmux send-keys -t "$SESSION_NAME:implementer" Enter

            sleep 10
        elif [ $RETRY_COUNT -eq 4 ]; then
            log_message "🧠 ENABLING ULTRATHINK MODE (3 retries exhausted)"

            # Enable extended thinking for deep analysis
            tmux send-keys -t "$SESSION_NAME:implementer" ""
            tmux send-keys -t "$SESSION_NAME:implementer" Enter
            sleep 2

            # Send line-by-line with -- to prevent flag interpretation
            ULTRATHINK_MESSAGE="ULTRATHINK MODE ENABLED: You have exhausted 3 retry attempts. Use extended thinking to deeply analyze this problem. Think step-by-step about:
1. Root cause analysis - what is the REAL underlying issue?
2. Have you checked ALL relevant files, configs, dependencies?
3. Are there hidden assumptions you're making?
4. What debugging output do you need to see?
5. Break the problem into the smallest possible pieces

Use <Thinking> tags to show your deep analysis. Then implement the solution. This is attempt 4 - we MUST solve this."

            echo "$ULTRATHINK_MESSAGE" | while IFS= read -r line; do
                tmux send-keys -t "$SESSION_NAME:implementer" -- "$line"
                tmux send-keys -t "$SESSION_NAME:implementer" Enter
                sleep 0.05
            done
            tmux send-keys -t "$SESSION_NAME:implementer" Enter

            sleep 15
        else
            log_message "💀 Max retries (4) exceeded for this task"
            log_message "Escalating to user intervention required"
            update_state "$STATE_FILE" "blocked" "Task requires manual intervention after 4 attempts: $BLOCKED_TASK"
        fi

        continue
    fi

    # CRITICAL CHECK 4: Question detection with duplicate prevention
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
