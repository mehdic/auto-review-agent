# Communication Audit - Potential Failure Scenarios

## Communication Path 1: Watchdog reads Implementer output via `tmux capture-pane`

### Current Implementation:
```bash
IMPLEMENTER_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p | tail -50)
```

### Potential Issues:

❌ **Issue 1.1: Output scrolling past buffer**
- Only captures last 50 lines
- If important question is on line 51+, it's missed
- If Claude generates lots of output quickly, question disappears

❌ **Issue 1.2: Pattern matching is fragile**
```bash
grep -qi "should I\|would you like\|do you want\|which.*prefer"
```
- Claude might ask differently: "What would be better?" "Need input on..."
- Pattern might match false positives in code/comments
- Multi-line questions might not be detected

❌ **Issue 1.3: Timing issues**
- Checks every 30 seconds
- Question could appear and disappear between checks
- Or persist and get responded to multiple times

❌ **Issue 1.4: Tmux pane buffer limits**
- Default tmux history is 2000 lines
- If implementer generates tons of output, history gets truncated
- Can't go back to see what happened

---

## Communication Path 2: Watchdog sends commands via `tmux send-keys`

### Current Implementation:
```bash
tmux send-keys -t "$SESSION_NAME:implementer" "Choose the best option..."
tmux send-keys -t "$SESSION_NAME:implementer" Enter
```

### Potential Issues:

❌ **Issue 2.1: Interrupting Claude mid-generation**
- If Claude is actively generating output, send-keys might interrupt
- Could inject text into wrong context
- Might break Claude's current operation

❌ **Issue 2.2: Command queue race**
- Multiple send-keys in quick succession
- Not clear if they queue or can interfere with each other

❌ **Issue 2.3: No confirmation of receipt**
- Fire and forget - no way to know if command was received
- No way to know if it had desired effect

❌ **Issue 2.4: Session/window name mismatch**
- If session name has special characters
- If window was renamed manually
- send-keys would fail silently

---

## Communication Path 3: State file (JSON) sharing

### Current Implementation:

**Implementer writes:**
```python
state['status'] = '$status'
state['last_update'] = datetime.now().isoformat()
state['message'] = '$message'
```

**Watchdog reads:**
```bash
STATUS=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('status', 'unknown'))")
```

### Potential Issues:

❌ **Issue 3.1: Race condition - read during write**
- No file locking
- Watchdog might read while implementer is writing
- json.load() could fail with corrupt/incomplete JSON
- Error is silenced (|| echo "unknown")

❌ **Issue 3.2: File format mismatch**
- Implementer only writes 3 fields (status, last_update, message)
- Prompt tells Claude to write more fields (current_task, completed_tasks, total_tasks)
- update_state() function will OVERWRITE Claude's additions
- Progress tracking will be lost

❌ **Issue 3.3: Status value assumptions**
- Code checks for exact string "completed"
- What if Claude writes "complete", "finished", "done"?
- Case sensitivity issues

❌ **Issue 3.4: Python availability**
- No check if python3 is installed
- Script will break silently if missing

❌ **Issue 3.5: Error handling in Python**
```python
try:
    with open('$STATE_FILE', 'r') as f:
        state = json.load(f)
except:
    state = {}
```
- Catches ALL exceptions (bad practice)
- Hides real issues (permissions, disk full, corrupt JSON)

---

## Communication Path 4: Monitor window showing state

### Current Implementation:
```bash
watch -n 5 'cat "$PROJECT_PATH/coordination/state.json" 2>/dev/null | jq . || echo "Waiting..."'
```

### Potential Issues:

❌ **Issue 4.1: jq dependency**
- Not checking if jq is installed
- Will show error instead of graceful fallback

❌ **Issue 4.2: Path with spaces**
- Even though quoted, watch command might not handle spaces properly
- Could fail silently

---

## Cross-Cutting Issues

❌ **Issue 5.1: Idle detection too aggressive**
```bash
IDLE_THRESHOLD=300  # 5 minutes
LAST_FILE_CHANGE=$(date +%s)
```
- If Claude is reading/analyzing/planning (legitimate work)
- No file changes for 5+ minutes triggers nudge
- Could interrupt important thinking time
- False positives will be common

❌ **Issue 5.2: File change detection pattern**
```bash
find "$PROJECT_PATH" -type f \( -name "*.java" -o -name "*.kt" ... \) -mmin -5
```
- Only looks for specific file types
- What if project uses different languages? (.go, .rs, .cpp, .c#)
- What if legitimate work is modifying config files?
- What if work involves deleting files (find won't see deletions)?

❌ **Issue 5.3: No Claude process detection**
- Checks if window exists: ✓
- Checks if Claude is actually running: ❌
- Window could exist but Claude crashed/exited
- Would wait forever with no action

❌ **Issue 5.4: Log file growth unbounded**
- tee -a appends forever
- No log rotation
- Could fill disk on long runs

❌ **Issue 5.5: No validation that tasks.md exists**
- Scripts assume TASKS_FILE exists and is readable
- Could fail with cryptic error if file missing/moved

❌ **Issue 5.6: Prompt injection in variables**
```bash
PROMPT="You are an autonomous implementer working on: $SPEC_NAME
```
- If SPEC_NAME contains special characters or newlines
- Could break the prompt or inject unintended instructions

❌ **Issue 5.7: Directory change assumption**
```bash
cd "$PROJECT_PATH"
```
- No error checking if cd fails
- All subsequent paths would be wrong

❌ **Issue 5.8: Multiple simultaneous responses**
- Question detected → respond → sleep 5 → continue
- Next check in 25 seconds
- If question still visible, respond again
- Could spam implementer with duplicate commands

❌ **Issue 5.9: Exit code assumptions**
```bash
CLAUDE_EXIT_CODE=$?
log_message "Claude exited with code: $CLAUDE_EXIT_CODE"
```
- Logs it but doesn't act on it
- Exit code 1 (error) treated same as 0 (success)
- Could retry forever on persistent errors

❌ **Issue 5.10: Tmux not installed**
- No check if tmux is available
- Will fail with cryptic error

---

## Critical Missing Features

❌ **No verification of completion**
- Watchdog trusts status="completed" blindly
- Should verify against tasks.md or run checks
- Could mark complete prematurely

❌ **No restart logic**
- Watchdog detects crash but doesn't restart
- Has TODO comment but not implemented
- System dies permanently on crash

❌ **No deadlock detection**
- If both windows get stuck waiting for each other
- No circuit breaker
- No timeout for "no progress"

❌ **No duplicate session prevention**
- Creates new session with timestamp
- Old sessions with same spec could still be running
- Will conflict/interfere with each other

---

## Severity Assessment

**CRITICAL (Will definitely break):**
- State file race condition (3.1)
- State file format mismatch (3.2)
- No Claude process detection (5.3)
- Pattern matching fragility (1.2)

**HIGH (Likely to cause issues):**
- Idle detection false positives (5.1)
- Multiple simultaneous responses (5.8)
- Exit code not handled (5.9)
- File change detection too narrow (5.2)

**MEDIUM (Could cause issues in some scenarios):**
- Output scrolling past buffer (1.1)
- Send-keys interruption (2.1)
- Timing issues (1.3)
- No completion verification (Missing)

**LOW (Edge cases):**
- Dependency checks (4.1, 5.10)
- Log growth (5.4)
- Path handling (4.2, 5.6, 5.7)
