# Fix for Stuck Planner Implementation

## Problem
The planner/reviewer approved "approach_2" but implementation never started. The status shows "implementing" but no Claude process is running.

## Root Cause
The `planner-loop.sh` script has a bug where it:
1. Updates status to "implementing"
2. Exits the loop
3. Never actually starts Claude to do the implementation

## Quick Fix (Choose One Method)

### Method 1: Direct Implementation (RECOMMENDED)
Simplest approach - just starts implementation:

```bash
cd /Users/mchaouachi/agent-system
./direct-implement.sh
```

This bypasses all state checking and directly starts Claude with the implementation task.

---

### Method 2: Nuclear Fix
For when you need to force everything regardless of state:

```bash
cd /Users/mchaouachi/agent-system
./nuclear-fix.sh
```

This will:
- Check and kill any stuck processes
- Work with existing tmux session or create new
- Force implementation to start

---

### Method 3: Diagnose First
To understand what's wrong before fixing:

```bash
cd /Users/mchaouachi/agent-system
./diagnose-stuck.sh
```

This shows:
- Proposals file status
- Running processes
- Tmux session state
- Recent file changes
- Specific diagnosis and solution

---

## Verification

After running any fix, verify implementation is working:

### 1. Check Claude is running
```bash
ps aux | grep claude | grep -v grep
```
Should show at least one claude process.

### 2. Check for file changes
```bash
find /Users/mchaouachi/IdeaProjects/StockMonitor/src -name "*.java" -mmin -5 | head
```
Should show recently modified Java files (after a minute or two).

### 3. Monitor logs
```bash
tail -f /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/notifications.log
```

### 4. Watch test progress
```bash
cd /Users/mchaouachi/IdeaProjects/StockMonitor
watch -n 60 'mvn test 2>&1 | grep -E "Tests run|BUILD"'
```

---

## If Still Stuck

If none of the above work:

1. **Kill everything and restart:**
   ```bash
   # Kill tmux session
   tmux kill-session -t agent_system_spec

   # Kill any Claude processes
   pkill -f claude

   # Start fresh with direct implementation
   ./direct-implement.sh
   ```

2. **Manual Claude session:**
   ```bash
   cd /Users/mchaouachi/IdeaProjects/StockMonitor
   claude
   ```

   Then paste:
   ```
   Read the proposals file: coordination/task_proposals.json

   Implement the approved approach (approach_2) to fix all 75 failing tests.
   Currently 108/183 tests pass. Goal is 183/183 passing.

   Start by running mvn test to see failures, then fix systematically.
   Work autonomously without asking permission.
   ```

---

## Permanent Fix

To prevent this in the future, replace the planner loop:

```bash
cd /Users/mchaouachi/agent-system
cp planner-loop-fixed.sh planner-loop.sh
```

The fixed version properly continues to implementation after detecting approval.

---

## Understanding the Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `diagnose-stuck.sh` | Analyze current state | First step to understand problem |
| `direct-implement.sh` | Start implementation now | Quickest fix, bypasses all checks |
| `nuclear-fix.sh` | Force implementation | When direct-implement doesn't work |
| `force-start-approved.sh` | Start if status=approved | Only works if status is exactly "approved" |
| `force-implementation.sh` | Tmux-based force start | Only if tmux session exists |

---

## Why This Happened

The original `planner-loop.sh` (lines 18-28) has this logic:

```bash
# Check if we need to create proposals
if [ ! -f "$PROJECT_PATH/coordination/task_proposals.json" ] ||
   ! grep -q '"awaiting_review"' "$PROJECT_PATH/coordination/task_proposals.json" 2>/dev/null; then
    # Create proposals
fi

# Wait for approval (lines 30-39)
# Implementation (lines 41-43)
```

The problem: If the file exists and doesn't contain "awaiting_review", it skips ALL of the code including the wait-for-approval and implementation sections. So when status is "implementing", the entire script is skipped!

The fix (`planner-loop-fixed.sh`) properly checks each phase:
1. Create proposals if needed
2. Wait for approval
3. Actually run implementation

---

## Expected Behavior After Fix

1. Claude starts and reads the proposals file
2. Shows it's running `mvn test` to see failures
3. Starts modifying Java files to fix tests
4. Periodically re-runs mvn test to check progress
5. Continues through all workstreams until 183/183 tests pass

Progress should be visible in:
- Modified Java files (find command)
- Log entries being added
- Test count improving (mvn test output)
