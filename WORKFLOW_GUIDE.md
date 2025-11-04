# Autonomous Implementer System - Complete Workflow Guide

## Quick Start

```bash
./start-here.sh
```

Then follow the interactive prompts!

---

## The 4 Operations Explained

### 1. **LAUNCH** - Start the Autonomous System

**What it does:**
- Creates a tmux session with 3 windows running simultaneously
- Window 0: **Implementer** (Claude Code working visibly)
- Window 1: **Watchdog** (Supervisor monitoring implementer)
- Window 2: **Monitor** (Live status dashboard)

**How to use:**
```bash
./start-here.sh
> Enter project path: [press Enter for current dir]
> Enter spec number: 001
> Select operation: 1

> Attach to session now? (y/n): y  # or n to run in background
```

**What you'll see:**
- Implementer window shows Claude Code UI with your tasks loading
- You can **watch it work in real-time**
- You can **type and interact** anytime (it's not piped!)
- It works autonomously but you maintain full control

**When to use:**
- Starting work on a new spec
- Restarting after making manual changes
- When you want to see the system in action

---

### 2. **MONITOR** - Attach to Running Session

**What it does:**
- Connects you to an already-running autonomous session
- Shows you the current state across all 3 windows
- Lets you observe and interact without interrupting the work

**How to use:**
```bash
./start-here.sh
> Enter project path: [same as before]
> Enter spec number: 001
> Select operation: 2
```

**Inside the session:**
```bash
# Switch between windows
Ctrl+b 0   # Implementer - watch Claude work
Ctrl+b 1   # Watchdog - see supervisor decisions
Ctrl+b 2   # Monitor - view current status

# Detach without stopping
Ctrl+b d   # Session keeps running in background

# Scroll back through history
Ctrl+b [   # Enter scroll mode
q          # Exit scroll mode
```

**When to use:**
- Checking progress on long-running tasks
- Debugging why something seems stuck
- Interacting with Claude if needed
- Reviewing what's been done so far

---

### 3. **VIEW LOGS** - Read Historical Output

**What it does:**
- Opens log files in a viewer (`less`)
- Shows timestamped history of all actions
- Includes both implementer and watchdog decisions

**How to use:**
```bash
./start-here.sh
> Select operation: 4  # Implementer logs
# OR
> Select operation: 5  # Watchdog logs
```

**What you'll see in implementer logs:**
```
[2025-11-04 14:30:15] IMPLEMENTER: Starting iteration 1
[2025-11-04 14:30:20] IMPLEMENTER: Starting Claude for implementation...
[2025-11-04 14:32:45] IMPLEMENTER: Claude exited with code: 0
[2025-11-04 14:32:46] IMPLEMENTER: Status: implementing
```

**What you'll see in watchdog logs:**
```
[2025-11-04 14:35:10] WATCHDOG: Active: 3 files modified in last 5 minutes
[2025-11-04 14:40:15] WATCHDOG: Detected question in implementer output
[2025-11-04 14:40:15] WATCHDOG: Sending auto-response: Choose best option
[2025-11-04 14:45:20] WATCHDOG: No file changes for 310 seconds
[2025-11-04 14:45:20] WATCHDOG: Implementer may be stuck - sending nudge
```

**When to use:**
- System finished and you want to review what happened
- Debugging issues or unexpected behavior
- Understanding decisions the implementer made
- Seeing how watchdog kept things moving

---

### 4. **STOP** - Shut Down the System

**What it does:**
- Cleanly kills the tmux session
- Stops both implementer and watchdog
- Preserves all logs for later review

**How to use:**
```bash
./start-here.sh
> Enter project path: [same as before]
> Enter spec number: 001
> Select operation: 3
```

**When to use:**
- Work is complete
- Need to make manual changes before continuing
- System is truly stuck and needs restart
- Switching to work on different spec

---

## Complete Workflow Examples

### Scenario 1: "I have 200+ tasks and want it to run autonomously"

```bash
# 1. Launch it
./start-here.sh
> Project path: [Enter]
> Spec number: 001
> Operation: 1
> Attach now? n   # Run in background

# 2. Go do something else for hours

# 3. Check in periodically
./start-here.sh
> Spec: 001
> Operation: 2   # Monitor
Ctrl+b 0         # See what it's working on
Ctrl+b 2         # Check status
Ctrl+b d         # Detach, let it continue

# 4. When done
./start-here.sh
> Spec: 001
> Operation: 4   # View logs to see everything it did
> Operation: 3   # Stop the system
```

---

### Scenario 2: "I want to watch it work"

```bash
# 1. Launch and attach
./start-here.sh
> Project path: [Enter]
> Spec number: 002
> Operation: 1
> Attach now? y   # Watch it work

# You'll see Claude Code UI working live!

# 2. Switch windows to see everything
Ctrl+b 1   # Check watchdog decisions
Ctrl+b 2   # See status updates
Ctrl+b 0   # Back to implementer

# 3. Detach when satisfied
Ctrl+b d
```

---

### Scenario 3: "It seems stuck, what's happening?"

```bash
# 1. Attach to running session
./start-here.sh
> Spec: 001
> Operation: 2

# 2. Check each window
Ctrl+b 0   # Is implementer still responding?
Ctrl+b 1   # Is watchdog sending nudges?
Ctrl+b 2   # What does status show?

# 3. Scroll back in implementer
Ctrl+b [   # Enter scroll mode
# Use arrow keys or Page Up/Down
q          # Exit scroll mode

# 4. If truly stuck, check logs
Ctrl+b d   # Detach first
./start-here.sh
> Operation: 4   # Read implementer logs
> Operation: 5   # Read watchdog logs

# 5. Restart if needed
./start-here.sh
> Operation: 3   # Stop
> Operation: 1   # Launch fresh
```

---

## How the System Keeps Working Autonomously

### Implementer Behavior
- Reads tasks.md continuously
- Works through tasks one by one
- Makes reasonable decisions without asking
- Updates state.json after each task
- Retries if Claude exits unexpectedly (max 1000 iterations)
- Exits only when status = "completed"

### Watchdog Behavior (every 30 seconds)
1. **Question Detection**: If implementer asks "Should I...?" → Auto-responds "Yes, continue"
2. **Input Detection**: If implementer waiting for input → Sends "Continue with next task"
3. **Idle Detection**: If no file changes for 5+ minutes → Sends nudge
4. **Completion Detection**: If state.json says "completed" → Exits successfully
5. **Crash Detection**: If implementer window gone → Logs error (TODO: auto-restart)

---

## State File Format

The system tracks progress in `coordination/state.json`:

```json
{
  "status": "implementing",
  "last_update": "2025-11-04T14:30:15",
  "message": "Iteration 5 - Working on tasks",
  "current_task": "Fix authentication bug",
  "completed_tasks": ["Setup project", "Install dependencies"],
  "total_tasks": 200
}
```

**Status values:**
- `initializing` - System starting up
- `implementing` - Actively working on tasks
- `retrying` - Claude exited, restarting
- `completed` - All tasks done
- `max_iterations` - Stopped after 1000 iterations

---

## Logs Location

All logs are in `<project>/coordination/logs/`:
- `implementer.log` - Everything the implementer does
- `watchdog.log` - Supervisor monitoring and decisions

You can also tail them in real-time:
```bash
tail -f ~/your-project/coordination/logs/implementer.log
tail -f ~/your-project/coordination/logs/watchdog.log
```

---

## Tmux Quick Reference

**Sessions:**
```bash
tmux ls                        # List all sessions
tmux attach -t <name>          # Attach to session
tmux kill-session -t <name>    # Kill session
```

**Inside tmux:**
```bash
Ctrl+b d       # Detach (session keeps running)
Ctrl+b 0/1/2   # Switch to window 0, 1, or 2
Ctrl+b [       # Scroll mode (q to exit)
Ctrl+b c       # Create new window
Ctrl+b ,       # Rename window
```

---

## Troubleshooting

### "Session not found"
- The system may have completed and exited
- Check logs to see what happened
- Launch a new session

### "Implementer keeps asking questions"
- Watchdog should auto-respond
- Check watchdog logs to see if it's detecting questions
- Attach and manually respond if needed

### "No file changes for 5+ minutes"
- Watchdog will send nudge automatically
- Attach to see what Claude is doing
- May be reading/planning (normal for large tasks)

### "Max iterations reached"
- System ran 1000 iterations without completing
- Check logs to see what's looping
- May need to fix tasks.md or state.json
- Relaunch after fixing

---

## Tips for Success

1. **Clear tasks.md**: Make tasks specific and actionable
2. **Let it run**: Don't interrupt unless necessary
3. **Check periodically**: Monitor every hour or so for long tasks
4. **Trust the watchdog**: It will keep things moving
5. **Read the logs**: They contain valuable debugging info
6. **Interact when needed**: You can always attach and help

---

## What Makes This Different from Old System

**OLD (Planner/Reviewer):**
- ❌ Separate processes, no shared context
- ❌ Piped mode, couldn't see UI
- ❌ Manual Enter press needed
- ❌ Would stop and ask questions constantly
- ❌ No automatic nudging when stuck

**NEW (Implementer/Watchdog):**
- ✅ Watchdog reads implementer output via tmux
- ✅ Visible Claude UI, can interact anytime
- ✅ Automatic Enter execution
- ✅ Auto-responds to questions
- ✅ Detects idle state and sends nudges
- ✅ Built for 200+ tasks
