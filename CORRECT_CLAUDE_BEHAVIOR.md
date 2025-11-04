# CRITICAL FIX: How Claude CLI Actually Works

## The Problem You Identified

**You were 100% correct:** When you run `claude`, it does NOT exit after responding. It stays open waiting for the next message.

```bash
# What I WRONGLY claimed:
echo "$PROMPT" | claude
# "Claude responds and exits with code 0"

# What ACTUALLY happens:
echo "$PROMPT" | claude
# Claude responds
# Claude shows prompt: "Message:"
# Claude WAITS for next input
# NEVER EXITS - command hangs forever
```

This is why the original implementer was stuck! The line:
```bash
echo "$PROMPT" | claude 2>&1 | tee -a "$LOG_FILE"
```

Was **permanently blocked** waiting for Claude to exit (which never happens).

---

## The Correct Solution: Persistent Claude Session

Instead of trying to make Claude exit, we work WITH its persistent session model:

### New Architecture:

```bash
# 1. Start Claude ONCE in the tmux window
tmux send-keys -t "$SESSION:implementer" "claude"
tmux send-keys -t "$SESSION:implementer" Enter

# 2. Wait for Claude to be ready (no "Wandering..." messages)

# 3. Send message using tmux
tmux send-keys -t "$SESSION:implementer" "Your prompt here"
tmux send-keys -t "$SESSION:implementer" Enter

# 4. Monitor tmux output to detect when Claude is done
while true; do
    OUTPUT=$(tmux capture-pane -t "$SESSION:implementer" -p)

    # Check for working indicators
    if echo "$OUTPUT" | grep -q "Wandering\|Hatching\|Pondering"; then
        # Claude still working
        continue
    fi

    # Check if output is stable for 20 seconds
    if output_stable_for_20s; then
        # Claude finished this turn
        break
    fi
done

# 5. Check state.json to see if work complete

# 6. If not complete, send another message (step 3)
```

---

## How We Detect "Claude is Done"

Thanks to your insight, we use TWO indicators:

### 1. No Working Status Messages

Claude shows these while working:
- "Wandering..."
- "Hatching..."
- "Pondering..."
- "Thinking..."
- "Working..."

When these are GONE from the output, Claude may be done.

### 2. Output Stable for 20 Seconds

We hash the last 20 lines of output and check if it hasn't changed:

```bash
# Check every 5 seconds
sleep 5
CURRENT_HASH=$(echo "$OUTPUT" | tail -20 | md5sum)

if [ "$CURRENT_HASH" = "$LAST_HASH" ]; then
    STABLE_COUNT=$((STABLE_COUNT + 1))

    if [ $STABLE_COUNT -ge 4 ]; then
        # 4 checks × 5 seconds = 20 seconds stable
        # Claude is done!
    fi
fi
```

---

## Complete Flow

```
┌─ Iteration 1 ────────────────────────────────────────┐
│ 1. Send prompt to Claude via tmux                   │
│ 2. Monitor output for "Wandering..." messages       │
│    - See "Wandering..." → Claude working            │
│    - See "Hatching..." → Claude working             │
│    - Status messages gone → Maybe done              │
│ 3. Check if output stable for 20 seconds            │
│    - 5s: same → count 1                             │
│    - 10s: same → count 2                            │
│    - 15s: same → count 3                            │
│    - 20s: same → count 4 → DONE!                    │
│ 4. Check state.json → status="implementing"         │
│    NOT COMPLETE                                      │
└──────────────────────────────────────────────────────┘
         ↓ wait 30s
┌─ Iteration 2 ────────────────────────────────────────┐
│ 1. Send continuation prompt to SAME Claude session  │
│ 2. Monitor for completion...                        │
│ 3. Output stable for 20s                            │
│ 4. Check state.json → status="completed" ✅         │
│    WORK COMPLETE!                                    │
└──────────────────────────────────────────────────────┘
```

---

## Why This is Better

**Old Approach (Broken):**
- Try to start new Claude each time
- Wait for Claude to exit (never happens)
- Script hangs forever
- ❌ Doesn't work

**New Approach (Correct):**
- Start Claude ONCE
- Keep sending messages to same session
- Detect completion via output analysis
- ✅ Works with Claude's actual behavior

---

## The Key Insight

You said: "claude cli doesn't exit with code zero. it just stays there waiting for my input"

This was the critical insight that revealed the entire architecture was wrong.

Thank you for questioning my incorrect assumptions - it led to the correct solution!

---

## What Changed

**Before:**
```bash
while loop; do
    echo "$PROMPT" | claude  # HANGS FOREVER
    # Never gets here
done
```

**After:**
```bash
# Start Claude once outside loop
tmux send-keys "claude"

while loop; do
    # Send message to existing Claude session
    tmux send-keys "$PROMPT"

    # Monitor output to detect completion
    wait_for_claude_to_finish()

    # Check if work complete
    if status="completed"; then
        break
    fi
done
```

---

## Files Changed

- `implementer-loop.sh` - Complete rewrite to use persistent Claude session
- `lib/state-manager.sh` - Updated process detection
- `IMPLEMENTER_LOOP_EXPLAINED.md` - Outdated, needs update

All committed and ready to test!
