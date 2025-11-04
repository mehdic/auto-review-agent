# How Implementer Loop Actually Works

## Your Correct Observation:
> "claude exits when done (exit code 0) - that never happens, because claude would just finish processing and display a message, that message need to be captured and analysed to determine if claude has finished"

You're RIGHT. Let me explain what ACTUALLY happens:

---

## What Happens When You Run `claude`

```bash
echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"
```

### Step-by-Step Timeline:

**1. Claude CLI Starts**
- `claude` process spawns
- Reads the prompt from stdin
- Sends it to Claude API

**2. Claude Responds**
- Response streams to stdout in real-time
- You see: "Let me read the tasks file..."
- Then: "I'll start with task 1..."
- Then: Tool use to read files
- Then: More text
- Then: Tool use to edit files
- Then: "Task 1 complete, moving to task 2..."
- ... (continues for minutes/hours)

**3. Claude "Finishes"**
- Eventually Claude sends a message with NO tool calls
- This means: "I'm done with this turn, waiting for your next input"
- The `claude` CLI detects this and **exits with code 0**

**4. BUT...**
- Exit code 0 does NOT mean "all work is complete"
- It just means "I responded to your prompt"
- Claude might have said:
  - ✅ "All 183 tests now pass! Work complete!"
  - ❌ "I fixed task 1, now starting task 2..." (NOT DONE!)
  - ❌ "Can't fix this test, moving on..." (GAVE UP!)

---

## So How Does implementer-loop.sh Know if Work is Complete?

### Method 1: State File (Current Implementation)

```bash
# After claude exits
STATUS=$(read_state "$STATE_FILE" "status" "unknown")

if [ "$STATUS" = "completed" ]; then
    # Claude wrote status="completed" to state.json
    # This means it believes all work is done
    exit 0
fi

# Status is NOT "completed"
# This means more work remains
# Wait 30 seconds and run Claude again
sleep 30
```

**How Claude Updates State:**
In the prompt, we tell Claude:
```
To update progress, modify $STATE_FILE directly.
When you complete ALL tasks, set status to "completed".
```

So Claude will:
1. Read tasks.md
2. Work on tasks
3. Update state.json: `{"status": "implementing", "completed_tasks": ["task1"], ...}`
4. Continue working
5. When done: update state.json: `{"status": "completed", ...}`
6. Exit its turn

**The Loop:**
```
Iteration 1:
  Run Claude → Works for 5 minutes → Exits ("done with turn")
  Check state.json → status="implementing" → NOT COMPLETE
  Sleep 30s

Iteration 2:
  Run Claude again → "Continue from where I left off" → Works for 5 minutes → Exits
  Check state.json → status="implementing" → NOT COMPLETE
  Sleep 30s

Iteration 3:
  Run Claude again → Finishes final task → Writes status="completed" → Exits
  Check state.json → status="completed" → WORK IS COMPLETE!
  Exit loop
```

---

## Method 2: Output Analysis (What You're Suggesting)

**Alternative approach:**
```bash
# Capture Claude's output
OUTPUT=$(echo "$PROMPT" | claude 2>&1)

# Analyze the output to determine completion
if echo "$OUTPUT" | grep -q "All tasks complete" ||
   echo "$OUTPUT" | grep -q "183/183 tests passing" ||
   echo "$OUTPUT" | grep -q "Work is finished"; then
    # Claude SAID it's done
    exit 0
fi

# Not done, run again
```

**Problem with this:**
- Fragile pattern matching
- Claude might say "all tasks complete" but actually missed something
- Hard to distinguish "I'm summarizing progress" from "I'm truly done"

**Benefit:**
- Don't rely on Claude remembering to update state.json
- More explicit signal from Claude

---

## Current Implementation (Hybrid Approach)

The current implementer-loop.sh actually does BOTH:

### 1. State File Check (Primary)
```bash
STATUS=$(read_state "$STATE_FILE" "status" "unknown")
if [ "$STATUS" = "completed" ]; then
    exit 0
fi
```

### 2. Output Captured and Logged
```bash
echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"
```
- Everything Claude says goes to `coordination/logs/implementer.log`
- Watchdog reads this log
- Watchdog can detect if Claude is giving up or stuck

### 3. Watchdog Analysis (Secondary)
```bash
# In watchdog-loop.sh
IMPLEMENTER_OUTPUT=$(tmux capture-pane -t "$SESSION_NAME:implementer" -p -S -100)

# Check if giving up
if is_giving_up "$IMPLEMENTER_OUTPUT"; then
    # Intervene with reviewer feedback
fi

# Check if completed
STATUS=$(read_state "$STATE_FILE" "status" "unknown")
if [ "$STATUS" = "completed" ]; then
    # Verify by checking test results or other criteria
    exit 0
fi
```

---

## Why This Design?

### Problem: Claude Code Sessions Are Stateless
- Each time you run `claude`, it's a fresh session
- Claude doesn't "remember" what it did last iteration
- The prompt has to tell it where to continue

### Solution: State File as Memory
```bash
PROMPT="You are an autonomous implementer...

Start with the first uncompleted task (check $STATE_FILE for progress).
ITERATION: $ITERATION
Previous status: $(read_state "$STATE_FILE" "status" "unknown")"
```

- Claude reads state.json to see what's done
- Works on next task
- Updates state.json before exiting its turn
- Next iteration picks up from there

---

## The Full Cycle Visualized

```
┌─────────────────────────────────────────────────────────┐
│  Iteration 1                                            │
│                                                         │
│  implementer-loop.sh: Starts Claude with prompt        │
│          ↓                                              │
│  Claude: Reads tasks.md and state.json                 │
│          "Last completed: none, starting task 1"       │
│          ↓                                              │
│  Claude: Works on task 1 for 3 minutes                 │
│          Uses tools: Read, Edit, Write, Bash           │
│          ↓                                              │
│  Claude: Updates state.json                            │
│          {"status": "implementing",                     │
│           "completed_tasks": ["task1"],                │
│           "current_task": "task2"}                     │
│          ↓                                              │
│  Claude: Sends final message (no more tool calls)      │
│          "Task 1 complete, will continue in next turn" │
│          ↓                                              │
│  claude CLI: Exits with code 0                         │
│          ↓                                              │
│  implementer-loop.sh:                                  │
│      Check state.json → status="implementing"          │
│      NOT DONE → Sleep 30s → Start Iteration 2          │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│  Iteration 2                                            │
│                                                         │
│  implementer-loop.sh: Starts Claude again              │
│          ↓                                              │
│  Claude: Reads state.json                              │
│          "Last completed: task1, continuing with task2"│
│          ↓                                              │
│  Claude: Works on task 2 for 5 minutes                 │
│          ↓                                              │
│  Claude: Updates state.json                            │
│          {"status": "implementing",                     │
│           "completed_tasks": ["task1", "task2"],       │
│           "current_task": "task3"}                     │
│          ↓                                              │
│  Claude: Exits with code 0                             │
│          ↓                                              │
│  implementer-loop.sh:                                  │
│      Check state.json → status="implementing"          │
│      NOT DONE → Sleep 30s → Start Iteration 3          │
└─────────────────────────────────────────────────────────┘
              ↓
              ... (continues) ...
              ↓
┌─────────────────────────────────────────────────────────┐
│  Iteration 47                                           │
│                                                         │
│  Claude: Finishes final test                           │
│          "All 183 tests now passing!"                  │
│          ↓                                              │
│  Claude: Updates state.json                            │
│          {"status": "completed",  ← CHANGED!           │
│           "completed_tasks": ["task1"..."task200"],    │
│           "total_tasks": 200}                          │
│          ↓                                              │
│  Claude: Exits with code 0                             │
│          ↓                                              │
│  implementer-loop.sh:                                  │
│      Check state.json → status="completed"             │
│      DONE! → Exit loop with success                    │
└─────────────────────────────────────────────────────────┘
```

---

## Watchdog's Role During This

**While implementer loops:**

```
Every 30 seconds, watchdog checks:
  1. Is implementer-loop.sh still running?
  2. Capture last 100 lines of implementer output
  3. Check for patterns:
     - Giving up? → Send reviewer feedback
     - Asking questions? → Auto-respond
     - Errors? → Send encouragement
     - Idle too long? → Send nudge
  4. Check state.json status
  5. If status="completed" → Verify and exit
```

**The watchdog sees everything Claude outputs** via `tmux capture-pane`, so it can intervene even if Claude hasn't updated state.json correctly.

---

## Your Concern Addressed

> "claude exits when done (exit code 0) - that never happens"

**Clarification:**
- `claude` CLI **always** exits with code 0 after responding (unless error)
- This happens EVERY iteration (not just when work is complete)
- "Done" means "done with this turn", not "done with all work"

**How we know work is complete:**
1. **Primary:** Claude writes `status="completed"` to state.json
2. **Secondary:** Watchdog can verify (check test results, etc)
3. **Failsafe:** Max 1000 iterations, then stop

**If Claude forgets to update state.json:**
- Watchdog will see output: "All tasks complete!"
- Watchdog can manually mark state.json as completed
- OR watchdog can verify independently (run tests, check files)

---

## Could We Do Better?

**Option A: Explicit Completion Signal** (Your Suggestion)
```bash
OUTPUT=$(echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE")

# Look for explicit marker
if echo "$OUTPUT" | tail -5 | grep -q "===WORK_COMPLETE==="; then
    # Tell Claude to output this exact string when done
    exit 0
fi
```

**Option B: Verification Check**
```bash
# After claude exits, run actual verification
if ./run_tests.sh | grep -q "183 passed"; then
    # Tests actually pass, work is complete
    update_state "$STATE_FILE" "completed" "Verified: all tests pass"
    exit 0
fi
```

**Option C: Current Hybrid** (What we have)
- Trust state.json as primary signal
- Watchdog monitors as backup
- Max iterations as failsafe

---

## Bottom Line

**Implementer loop:**
1. Runs Claude with prompt (including iteration number and previous status)
2. Claude works until it reaches a natural stopping point ("turn is over")
3. Claude exits (ALWAYS exits, every iteration)
4. Loop checks state.json to see if Claude marked work as complete
5. If not complete, waits 30s and runs Claude again
6. Repeats until status="completed" or max iterations reached

**The key insight:** Each Claude invocation is ONE TURN in a multi-turn conversation. The state.json file is the memory that connects these turns into a continuous work session.

Is this the right approach, or would you prefer a different mechanism for determining completion?
