# Critical Fixes: Process Detection + Retry Mechanism + 100% Completion

## Issue #1: Claude Process Detection Was WRONG ❌

### Your Question:
> "when you say it will check if claude process is running, what do you mean? the claude code session is closed, or claude code finished working and returned?"

### The Problem I Had:

The old code was checking for the `claude` **process**, which is WRONG because:

```bash
# In implementer-loop.sh:
echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"  # This spawns 'claude' temporarily
```

**Timeline of what actually happens:**
1. `implementer-loop.sh` (bash script) starts in tmux
2. It spawns `claude` process
3. `claude` reads prompt → calls API → streams response → **EXITS** (exit code 0)
4. `implementer-loop.sh` continues running, waits 30 seconds
5. Loops back and starts `claude` again

**The old detection:**
```bash
# OLD - WRONG!
is_claude_running() {
    pgrep -P "$pane_pid" "claude" >/dev/null  # Looks for 'claude' process
}
```

This returns FALSE when:
- ✅ **Claude crashed** (good)
- ❌ **Claude finished normally** and implementer-loop.sh is in the 30s sleep (FALSE ALARM!)

So the watchdog would think Claude crashed when it's actually just between iterations!

### The Fix ✅

Check if `implementer-loop.sh` **script** is running, not the temporary `claude` process:

```bash
# NEW - CORRECT!
is_implementer_alive() {
    # Checks if implementer-loop.sh (the persistent bash script) is running
    pgrep -P "$pane_pid" -f "implementer-loop.sh" >/dev/null
}
```

**Now it correctly detects:**
- ✅ If `implementer-loop.sh` crashes/exits → restart
- ✅ If `implementer-loop.sh` is running but between Claude calls → do nothing (normal)

**Answer:** It checks if the **implementer-loop.sh bash script** is still running, NOT if Claude Code UI is open or if a specific Claude API call is active.

---

## Issue #2: You Want 100% Completion, No Excuses ✅

### Your Statement:
> "i dont care about what kind of tests are fixed and what are not, i want all tests and tasks and every other thing in the todo list to be finished properly. i want 100% success and proper implementation."

### The Problem:

The old prompt was too soft:
```bash
# OLD prompt:
"Work autonomously - when you face choices, pick the best option and continue"
```

Claude interpreted this as "I can skip hard stuff."

### The Fix ✅

**New prompt is explicit and unforgiving:**

```bash
CRITICAL REQUIREMENTS - 100% COMPLETION:
- You MUST complete EVERY task in the tasks.md file
- You MUST fix EVERY failing test until ALL tests pass
- DO NOT skip any task for any reason ("requires features", "too complex", etc)
- DO NOT mark work as complete until 100% success is achieved
- If you encounter a problem, you MUST solve it, not skip it
- There is a reviewer watching who will send you solutions if you get stuck
- Partial completion ("I fixed 4 out of 71") is NOT acceptable

ANTI-PATTERNS (DO NOT DO THESE):
- ❌ "I'll skip this test because it requires feature X"
- ❌ "Moving on to the next task" (without finishing current one)
- ❌ "This is too complex for me to handle"
- ❌ "Leaving this as TODO for later"
- ❌ "I can't fix this" (you can, keep trying)

SUCCESS CRITERIA:
- ALL tests passing (183/183, not 116/183)
- ALL tasks completed
- No skipped items
- No TODO/FIXME comments
- status="completed" in $STATE_FILE
```

---

## Issue #3: Retry Mechanism with Reviewer Feedback + Ultrathink ✅

### Your Requirement:
> "a lot of times claude code would skip a test, because it faces a problem, the reviewer should provide possible causes and solutions to fix the situation, and the implementer should pursue those paths until exhaustion. if a problem persists after 3 rounds, then ultrathink should be passed on to the implementer"

### How It Works Now:

**Watchdog constantly monitors implementer output for "giving up" patterns:**

```bash
is_giving_up() {
    # Detects patterns like:
    # - "skipping", "skip this", "moving on"
    # - "can't fix", "unable to fix", "too complex"
    # - "requires additional work", "will need"
    # - "leaving for later", "TODO", "FIXME"
    # - "not possible", "blocked by", "requires feature"
}
```

**When giving up is detected:**

### Attempt 1-3: Reviewer Provides Solutions

```bash
if [ $RETRY_COUNT -le 3 ]; then
    # Watchdog calls Claude AS A REVIEWER to analyze the problem
    REVIEW_PROMPT="You are a senior code reviewer analyzing why an implementer got stuck.

Implementer's last output (what they're stuck on):
\`\`\`
$IMPLEMENTER_OUTPUT  # The actual output where they gave up
\`\`\`

Your job:
1. Identify the SPECIFIC technical problem
2. Provide 3-5 CONCRETE solutions the implementer should try
3. Be SPECIFIC with file paths, function names, exact commands
4. Format as actionable steps they can execute immediately"

    # Get reviewer feedback
    REVIEWER_FEEDBACK=$(echo "$REVIEW_PROMPT" | claude --max-tokens 1000)

    # Send it back to implementer
    tmux send-keys -t "$SESSION_NAME:implementer" "
REVIEWER FEEDBACK (Attempt $RETRY_COUNT/3):
$REVIEWER_FEEDBACK

DO NOT SKIP THIS TASK. Try each solution systematically."
fi
```

**What the implementer sees:**
```
REVIEWER FEEDBACK (Attempt 1/3): The reviewer has analyzed your situation. Here are specific solutions to try:

PROBLEM: Test failing because WebSocket connection not properly configured in test environment

SOLUTIONS TO TRY:
1. Check if config/environments/test.rb has `config.action_cable.url = "ws://localhost:3000/cable"` - add if missing
2. Ensure test/test_helper.rb includes `ActionCable.server.config.disable_request_forgery_protection = true`
3. Run `rake db:test:prepare` to ensure test database schema is current
4. Add explicit WebSocket connection in the failing test setup: `ActionCable.server.restart`

EXAMPLE APPROACHES:
- See how it's handled in test/channels/universe_channel_test.rb
- Run test with verbose output: `rails test path/to/test.rb -v` to see actual error

DO NOT SKIP THIS TASK. Try each solution systematically. Report results after each attempt.
```

### Attempt 4: Ultrathink Mode

```bash
elif [ $RETRY_COUNT -eq 4 ]; then
    log_message "🧠 ENABLING ULTRATHINK MODE (3 retries exhausted)"

    tmux send-keys -t "$SESSION_NAME:implementer" "
ULTRATHINK MODE ENABLED: You have exhausted 3 retry attempts. Use extended thinking to deeply analyze this problem. Think step-by-step about:
1. Root cause analysis - what is the REAL underlying issue?
2. Have you checked ALL relevant files, configs, dependencies?
3. Are there hidden assumptions you're making?
4. What debugging output do you need to see?
5. Break the problem into the smallest possible pieces

Use <Thinking> tags to show your deep analysis. Then implement the solution. This is attempt 4 - we MUST solve this."
fi
```

### Attempt 5+: Escalate to Human

```bash
else
    log_message "💀 Max retries (4) exceeded for this task"
    update_state "$STATE_FILE" "blocked" "Task requires manual intervention after 4 attempts: $BLOCKED_TASK"
fi
```

**You'll see in watchdog logs:**
```
[2025-11-04 15:30:00] WATCHDOG: ⚠️  Implementer appears to be giving up on a task!
[2025-11-04 15:30:00] WATCHDOG: Blocked task: Skipping test: UniverseChannelTest#test_should_broadcast_universe_updates
[2025-11-04 15:30:00] WATCHDOG: This is retry attempt #1 for this task
[2025-11-04 15:30:01] WATCHDOG: 🔍 Generating reviewer feedback with solutions...
[2025-11-04 15:30:05] WATCHDOG: 📝 Reviewer feedback generated
```

---

## How Retry Tracking Works

**Per-task retry counts:**
```bash
# Each blocked task gets a unique ID (hash of the task description)
RETRY_KEY=$(echo "$BLOCKED_TASK" | md5sum | cut -d' ' -f1)
RETRY_FILE="$COORDINATION_DIR/retries_$RETRY_KEY.txt"

# Stored in: coordination/retries_abc123.txt
# Contains: 1, 2, 3, or 4 (the attempt number)
```

**So if implementer skips:**
- Test A → Gets retry 1/3
- Test B → Gets retry 1/3 (separate counter)
- Test A again → Gets retry 2/3 (same task, increments)
- Test A again → Gets retry 3/3
- Test A again → Gets ULTRATHINK MODE
- Test A again → BLOCKED (manual intervention)

---

## Complete Flow Diagram

```
Implementer runs → Encounters problem → Says "can't fix this"
                                              ↓
Watchdog detects "giving up" pattern ← Monitors output every 30s
                                              ↓
                                    Check retry count for this task
                                              ↓
                        ┌─────────────────────┴─────────────────────┐
                        ↓                                             ↓
                Retry 1-3                                    Retry 4
                        ↓                                             ↓
        Generate reviewer feedback                    Enable ULTRATHINK MODE
        with specific solutions                      (extended thinking)
                        ↓                                             ↓
        Send back to implementer                     Deep root cause analysis
        "Try these specific things"                   with <Thinking> tags
                        ↓                                             ↓
        Implementer tries solutions                  Implementer deeply analyzes
                        ↓                                             ↓
                        └─────────────────────┬─────────────────────┘
                                              ↓
                                       Still stuck?
                                              ↓
                                    Mark as BLOCKED
                                    Alert user for manual help
```

---

## Summary of All Fixes

| Issue | Old Behavior | New Behavior |
|-------|-------------|--------------|
| **Process Detection** | Checked for `claude` process (wrong) | Checks for `implementer-loop.sh` script (correct) |
| **Giving Up** | No detection, Claude skips freely | Detects 10+ "giving up" patterns immediately |
| **Retry Logic** | None - skip means skip forever | 3 retries with reviewer feedback, then ultrathink |
| **Completion** | "Work autonomously" (vague) | "100% completion required, NO SKIPPING" (explicit) |
| **Reviewer** | Passive (only approves) | Active (generates specific solutions when stuck) |
| **Escalation** | None | After 4 attempts → manual intervention required |

---

## What You'll See in Practice

**Scenario: Test fails, implementer tries to skip**

**Implementer output:**
```
❌ UniverseChannelTest#test_should_broadcast_universe_updates - FAILED
Connection refused on WebSocket

I've tried checking the config but this requires additional WebSocket infrastructure work.
Moving on to the next test...
```

**Watchdog immediately responds:**
```
[15:30:00] WATCHDOG: ⚠️  Implementer appears to be giving up on a task!
[15:30:00] WATCHDOG: Blocked task: Moving on to the next test...
[15:30:00] WATCHDOG: This is retry attempt #1 for this task
[15:30:01] WATCHDOG: 🔍 Generating reviewer feedback with solutions...
[15:30:05] WATCHDOG: 📝 Reviewer feedback generated
```

**Implementer receives:**
```
REVIEWER FEEDBACK (Attempt 1/3): [specific solutions as shown above]
DO NOT SKIP THIS TASK. Try each solution systematically.
```

**Implementer tries the solutions, reports results, continues until success or 4th attempt.**

---

## Files Changed

- `lib/state-manager.sh` - Fixed process detection, added giving-up detection
- `watchdog-loop.sh` - Added retry logic with reviewer feedback + ultrathink
- `implementer-loop.sh` - Updated prompt to enforce 100% completion

Ready to commit and test!
