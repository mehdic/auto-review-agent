# V1 vs V2 Comparison - Communication Fixes

## Executive Summary

**V1 (Original)**: Has 20+ communication failure scenarios identified in audit
**V2 (Fixed)**: Addresses all CRITICAL and HIGH severity issues

## What Was Fixed

### ✅ CRITICAL Issue #1: State File Race Conditions

**V1 Problem:**
```bash
# V1: No file locking, overwrites all fields
python3 << EOF
state = {}
try:
    with open('$STATE_FILE', 'r') as f:
        state = json.load(f)
except:
    state = {}

state['status'] = '$status'
state['last_update'] = datetime.now().isoformat()
state['message'] = '$message'

with open('$STATE_FILE', 'w') as f:
    json.dump(state, f, indent=2)
EOF
```

**Issues:**
- No file locking → Read during write = corrupt JSON
- Overwrites Claude's additions (current_task, completed_tasks, etc.)
- Catches all exceptions silently → Hides real errors

**V2 Solution:**
```bash
# V2: Uses fcntl locking, atomic writes, preserves fields
import fcntl

# Lock while reading
with open('$state_file', 'r') as f:
    fcntl.flock(f.fileno(), fcntl.LOCK_SH)
    state = json.load(f)
    fcntl.flock(f.fileno(), fcntl.LOCK_UN)

# Update only specific fields, preserve others
state['status'] = '$status'
state['last_update'] = datetime.now().isoformat()
state['message'] = '''$message'''

# Atomic write: temp file + rename
with open('$temp_file', 'w') as f:
    json.dump(state, f, indent=2)
    f.flush()
    os.fsync(f.fileno())

os.rename('$temp_file', '$state_file')  # Atomic!
```

**Benefits:**
- ✅ File locking prevents corruption
- ✅ Atomic write (temp + rename) prevents partial reads
- ✅ Preserves Claude's custom fields
- ✅ Retry logic (3 attempts) for transient failures

---

### ✅ CRITICAL Issue #2: No Claude Process Detection

**V1 Problem:**
```bash
# Only checks if window exists
if ! tmux list-windows -t "$SESSION_NAME" 2>/dev/null | grep -q "implementer"; then
    log_message "❌ Implementer window not found"
    # ... but no action taken!
fi
```

**Issues:**
- Window could exist but Claude crashed → false positive
- No restart logic (just TODO comment)
- System dies permanently on crash

**V2 Solution:**
```bash
# V2: Actually checks if Claude process is running
is_claude_running() {
    local session_name="$1"
    local window_name="$2"

    # Check window exists
    if ! tmux list-windows -t "$session_name" 2>/dev/null | grep -q "$window_name"; then
        return 1
    fi

    # Get pane PID
    local pane_pid=$(tmux list-panes -t "$session_name:$window_name" -F "#{pane_pid}" 2>/dev/null | head -1)

    if [ -z "$pane_pid" ]; then
        return 1
    fi

    # Check if Claude process exists under this pane
    pgrep -P "$pane_pid" "claude" >/dev/null 2>&1
    return $?
}

# Use it in watchdog
if ! is_claude_running "$SESSION_NAME" "implementer"; then
    log_message "❌ Claude process not running!"

    # Check if complete first
    STATUS=$(read_state "$STATE_FILE" "status" "unknown")
    if [ "$STATUS" = "completed" ]; then
        exit 0
    fi

    # Attempt restart (up to 3 times)
    if [ $RESTART_COUNT -lt $MAX_RESTARTS ]; then
        RESTART_COUNT=$((RESTART_COUNT + 1))
        # Send restart command to tmux window
        tmux send-keys -t "$SESSION_NAME:implementer" "$IMPLEMENTER_SCRIPT ..."
        tmux send-keys -t "$SESSION_NAME:implementer" Enter
    else
        log_message "💀 Max restarts reached"
        exit 1
    fi
fi
```

**Benefits:**
- ✅ Detects actual Claude crashes
- ✅ Auto-restarts up to 3 times
- ✅ Distinguishes crash from completion
- ✅ System can recover from failures

---

### ✅ CRITICAL Issue #3: Pattern Matching Too Fragile

**V1 Problem:**
```bash
# V1: Basic pattern, easy to miss questions
if echo "$IMPLEMENTER_OUTPUT" | grep -qi "should I\|would you like\|do you want\|which.*prefer"; then
    # respond
fi
```

**Issues:**
- Misses many question formats
- False positives (matches in code/comments)
- No context checking

**V2 Solution:**
```bash
# V2: Comprehensive patterns + context checking
is_asking_question() {
    local output="$1"

    # Only check last 20 lines (recent context)
    # More comprehensive patterns
    echo "$output" | tail -20 | grep -qiE "(should I|would you like|do you want|which.*prefer|what.*better|need.*input|please.*confirm|approve|permission|which option|select.*option|choose between|or would you|proceed\?|continue\?)"
}

# Plus added error detection
is_error_state() {
    local output="$1"
    echo "$output" | tail -20 | grep -qiE "(error:|exception|traceback|fatal|failed|unable to|cannot|could not|permission denied|command not found)"
}
```

**Benefits:**
- ✅ Catches more question formats
- ✅ Separate error detection
- ✅ Context-aware (only recent lines)
- ✅ Handles edge cases

---

### ✅ HIGH Issue #4: Idle Detection False Positives

**V1 Problem:**
```bash
# V1: Too aggressive (5 minutes), always triggers initially
IDLE_THRESHOLD=300  # 5 minutes
LAST_FILE_CHANGE=0  # Starts at 0!

# Later...
if [ $LAST_FILE_CHANGE -gt 0 ] && [ $IDLE_TIME -gt $IDLE_THRESHOLD ]; then
    # Nudge every time after 5 minutes
fi
```

**Issues:**
- 5 minutes too short for reading/planning
- Starts at 0 → triggers immediately
- No protection against spam nudges

**V2 Solution:**
```bash
# V2: More reasonable threshold, spam protection
IDLE_THRESHOLD=600  # 10 minutes (doubled!)
LAST_FILE_CHANGE=$(date +%s)  # Start at current time
LAST_IDLE_NUDGE=0  # Track last nudge time

# Later...
TIME_SINCE_LAST_NUDGE=$((CURRENT_TIME - LAST_IDLE_NUDGE))

if [ $IDLE_TIME -gt $IDLE_THRESHOLD ] && [ $TIME_SINCE_LAST_NUDGE -gt 300 ]; then
    # Check if actually stuck or just thinking
    if echo "$OUTPUT_TAIL" | grep -q "Thinking\|Processing\|Reading\|Analyzing"; then
        log_message "Claude is thinking - not nudging"
    else
        # Send nudge
        LAST_IDLE_NUDGE=$CURRENT_TIME  # Prevent spam
    fi
fi
```

**Benefits:**
- ✅ 10 minutes allows for legitimate reading/planning
- ✅ Detects "thinking" state → doesn't nudge
- ✅ Spam protection (5 min between nudges)
- ✅ Starts at current time → no immediate false alert

---

### ✅ HIGH Issue #5: Multiple Simultaneous Responses

**V1 Problem:**
```bash
# V1: No tracking of last response
if is_asking_question; then
    respond
    sleep 5
    continue
fi

# Next check in 25 seconds - if question still visible, respond AGAIN!
```

**Issues:**
- Question persists in buffer → re-detected
- Responds every 30 seconds if question stays visible
- Spams implementer with duplicate commands

**V2 Solution:**
```bash
# V2: Track last response time
LAST_QUESTION_RESPONSE=0

if is_asking_question "$IMPLEMENTER_OUTPUT"; then
    TIME_SINCE_LAST_RESPONSE=$((CURRENT_TIME - LAST_QUESTION_RESPONSE))

    if [ $TIME_SINCE_LAST_RESPONSE -lt 60 ]; then
        log_message "⏭️  Question detected but responded ${TIME_SINCE_LAST_RESPONSE}s ago - skipping"
    else
        # Send response
        LAST_QUESTION_RESPONSE=$CURRENT_TIME
    fi
fi
```

**Benefits:**
- ✅ Tracks last response time
- ✅ Won't respond twice within 60 seconds
- ✅ Prevents spam even if question persists
- ✅ Logs skipped responses for debugging

---

### ✅ HIGH Issue #6: Exit Code Not Handled

**V1 Problem:**
```bash
# V1: Logs but doesn't act on exit code
echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"
CLAUDE_EXIT_CODE=$?
log_message "Claude exited with code: $CLAUDE_EXIT_CODE"

# ... treats all exit codes the same!
```

**Issues:**
- Exit code 1 (error) treated same as 0 (success)
- Exit code 130 (Ctrl+C) treated same as 0
- Retries forever even on persistent errors

**V2 Solution:**
```bash
# V2: Different handling based on exit code
echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"
CLAUDE_EXIT_CODE=$?

if [ $CLAUDE_EXIT_CODE -eq 0 ]; then
    log_message "✅ Claude exited cleanly"
    CONSECUTIVE_FAILURES=0

elif [ $CLAUDE_EXIT_CODE -eq 130 ]; then
    log_message "⚠️  Claude interrupted (Ctrl+C)"
    update_state "$STATE_FILE" "interrupted" "User interrupted"
    exit 130  # Propagate interrupt

else
    log_message "❌ Claude exited with error code $CLAUDE_EXIT_CODE"
    CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))

    if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
        log_message "💀 Too many consecutive failures"
        update_state "$STATE_FILE" "failed" "Too many failures"
        exit 1
    fi
fi
```

**Benefits:**
- ✅ Respects Ctrl+C (clean shutdown)
- ✅ Tracks consecutive failures
- ✅ Gives up after 5 failures (not infinite loop)
- ✅ Better error messages

---

### ✅ MEDIUM Issue #7: Larger Capture Buffer

**V1 Problem:**
```bash
# V1: Only last 50 lines
IMPLEMENTER_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p | tail -50)
```

**V2 Solution:**
```bash
# V2: Last 100 lines with scroll-back
IMPLEMENTER_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p -S -100 2>/dev/null || echo "")
```

**Benefits:**
- ✅ More context (100 lines vs 50)
- ✅ Uses tmux scroll-back (`-S -100`)
- ✅ Fallback on error

---

### ✅ MEDIUM Issue #8: File Type Coverage

**V1 Problem:**
```bash
# V1: Only 5 file types
find ... -name "*.java" -o -name "*.kt" -o -name "*.py" -o -name "*.js" -o -name "*.ts"
```

**V2 Solution:**
```bash
# V2: 20+ file types
find ... -name "*.java" -o -name "*.kt" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \
    -o -name "*.tsx" -o -name "*.jsx" -o -name "*.go" -o -name "*.rs" -o -name "*.cpp" \
    -o -name "*.c" -o -name "*.h" -o -name "*.cs" -o -name "*.rb" -o -name "*.php" \
    -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.xml" -o -name "*.md"
```

**Benefits:**
- ✅ Detects work in more languages
- ✅ Includes config files (json, yaml, xml)
- ✅ Reduces false idle alerts

---

### ✅ MEDIUM Issue #9: Dependency Checking

**V1 Problem:**
- No checks for tmux, python3, jq
- Fails with cryptic errors if missing

**V2 Solution:**
```bash
check_dependencies() {
    local missing=()

    command -v tmux >/dev/null 2>&1 || missing+=("tmux")
    command -v python3 >/dev/null 2>&1 || missing+=("python3")
    command -v jq >/dev/null 2>&1 || missing+=("jq")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}ERROR: Missing required dependencies: ${missing[*]}${NC}"
        echo ""
        echo "Install them with:"
        echo "  Ubuntu/Debian: sudo apt install tmux python3 jq"
        echo "  macOS: brew install tmux python3 jq"
        exit 1
    fi
}
```

**Benefits:**
- ✅ Clear error messages
- ✅ Installation instructions
- ✅ Fails fast instead of cryptic errors

---

### ✅ MEDIUM Issue #10: Path Validation

**V1 Problem:**
```bash
cd "$PROJECT_PATH"  # No error checking!
```

**V2 Solution:**
```bash
# Validate all paths upfront
if [ ! -d "$PROJECT_PATH" ]; then
    echo "ERROR: Project path does not exist: $PROJECT_PATH"
    exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
    echo "ERROR: Tasks file not found: $TASKS_FILE"
    exit 1
fi

# cd with error checking
if ! cd "$PROJECT_PATH"; then
    log_message "ERROR: Failed to cd to $PROJECT_PATH"
    update_state "$STATE_FILE" "error" "Failed to access project directory"
    exit 1
fi
```

**Benefits:**
- ✅ Fails fast with clear errors
- ✅ Validates all paths upfront
- ✅ Checks cd success

---

## Summary Table

| Issue | Severity | V1 Status | V2 Status |
|-------|----------|-----------|-----------|
| State file race condition | CRITICAL | ❌ Broken | ✅ Fixed (locking + atomic) |
| State file format mismatch | CRITICAL | ❌ Broken | ✅ Fixed (preserves fields) |
| No Claude process detection | CRITICAL | ❌ Missing | ✅ Fixed (with auto-restart) |
| Pattern matching fragile | CRITICAL | ❌ Basic | ✅ Fixed (comprehensive) |
| Idle detection false positives | HIGH | ❌ Too aggressive | ✅ Fixed (10min + thinking detect) |
| Multiple simultaneous responses | HIGH | ❌ Spams | ✅ Fixed (60s cooldown) |
| Exit code not handled | HIGH | ❌ Ignored | ✅ Fixed (failure tracking) |
| File change detection narrow | HIGH | ❌ 5 types | ✅ Fixed (20+ types) |
| Duplicate responses | MEDIUM | ❌ Possible | ✅ Fixed (timestamp tracking) |
| Capture buffer too small | MEDIUM | ❌ 50 lines | ✅ Fixed (100 lines + scrollback) |
| Dependency checking | LOW | ❌ Missing | ✅ Fixed (with install hints) |
| Path validation | LOW | ❌ No checks | ✅ Fixed (validates all paths) |

---

## Which Version Should You Use?

### Use V1 if:
- You want to test the basic concept
- You're okay with potential communication failures
- You'll be monitoring closely and can intervene

### Use V2 if:
- You have 200+ tasks and need reliability
- You want autonomous operation without babysitting
- You need proper error handling and recovery
- You want to run overnight/unattended

---

## File Mapping

**V1 Files:**
- `implementer-loop.sh` (original)
- `watchdog-loop.sh` (original)
- `launch-autonomous.sh` (original)

**V2 Files:**
- `implementer-loop-v2.sh` (fixed)
- `watchdog-loop-v2.sh` (fixed)
- `launch-autonomous-v2.sh` (fixed)
- `lib/state-manager.sh` (new helper library)

**Shared:**
- `lib/find-spec.sh` (works with both)
- `start-here.sh` (can launch either version)

---

## Migration Path

1. **Test V2 first:**
   ```bash
   ./launch-autonomous-v2.sh /path/to/project 001
   ```

2. **Compare behavior:**
   - Watch both implementations
   - Check logs for differences
   - Verify communication reliability

3. **Once confident, update start-here.sh:**
   - Make V2 the default
   - Keep V1 as fallback option

4. **Eventually remove V1:**
   - After sufficient V2 testing
   - Document any edge cases
   - Archive V1 for reference
