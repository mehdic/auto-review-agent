# Agent Loop Modes - Choose Your Experience

The agent system now offers two modes for running the loops:

## 🤖 Piped Mode (Current Default)

**Files:** `planner-loop.sh`, `reviewer-loop.sh`

### How It Works
- Writes prompts to temporary files
- Pipes to Claude: `cat prompt.txt | claude`
- Claude runs non-interactively
- Output shown directly in terminal

### ✅ Pros
- Fully automated
- Works reliably in tmux
- No manual intervention needed
- Clean output logs

### ❌ Cons
- Can't see Claude's nice UI
- Can't manually interact with Claude
- Just see text output
- No visual progress indicators

### When to Use
- When you want fully autonomous agents
- When you're not monitoring closely
- When you want clean logs
- Production/unattended runs

---

## 👤 Interactive Mode (New Option)

**Files:** `planner-loop-interactive.sh`, `reviewer-loop-interactive.sh`

### How It Works
- Shows instructions on screen
- Starts Claude interactively: `claude`
- You see the full Claude CLI UI
- You can manually interact if needed

### ✅ Pros
- See Claude's beautiful UI
- Can manually send messages
- Visual progress indicators
- Better for debugging
- Can intervene if needed

### ❌ Cons
- Requires manual action (read instructions, press enter in Claude)
- Less autonomous
- Can't truly run unattended
- Claude must exit properly for loop to continue

### When to Use
- When you want to see what's happening
- When you might want to intervene
- When debugging issues
- Learning/understanding the process

---

## 📊 Comparison

| Feature | Piped Mode | Interactive Mode |
|---------|------------|------------------|
| **Automation** | ✅ Fully automated | ⚠️ Requires watching |
| **Claude UI** | ❌ No UI | ✅ Full UI |
| **Manual Control** | ❌ Can't interact | ✅ Can interact |
| **Tmux Compatible** | ✅ Works great | ✅ Works great |
| **Unattended** | ✅ Yes | ❌ No |
| **Visual Feedback** | ⚠️ Text only | ✅ Rich UI |
| **Logging** | ✅ Clean logs | ⚠️ Mixed logs |

---

## 🔄 Switching Between Modes

### Option 1: Quick Switch (Symlink/Copy)

**Switch to Interactive Mode:**
```bash
cd /Users/mchaouachi/agent-system
cp planner-loop.sh planner-loop-piped.sh
cp reviewer-loop.sh reviewer-loop-piped.sh
cp planner-loop-interactive.sh planner-loop.sh
cp reviewer-loop-interactive.sh reviewer-loop.sh

# Restart agents
tmux kill-session -t agent_system_spec
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 999-fix-remaining-tests
```

**Switch Back to Piped Mode:**
```bash
cd /Users/mchaouachi/agent-system
cp planner-loop-piped.sh planner-loop.sh
cp reviewer-loop-piped.sh reviewer-loop.sh

# Restart agents
tmux kill-session -t agent_system_spec
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 999-fix-remaining-tests
```

---

### Option 2: Launch Script Modification

Modify `launch-agents-from-spec.sh` to accept a mode parameter:

```bash
# Future enhancement - not implemented yet
./launch-agents-from-spec.sh /path/to/project spec-name --mode interactive
./launch-agents-from-spec.sh /path/to/project spec-name --mode piped
```

---

## 🎯 Recommendation

### For First-Time Users: **Interactive Mode**
- See what's happening
- Understand the process
- Can intervene if needed
- Better learning experience

### For Production Use: **Piped Mode**
- Fully autonomous
- Can run unattended
- Clean logs
- More reliable

### For Debugging: **Interactive Mode**
- See Claude's reasoning
- Check for issues
- Manually correct if needed

---

## 🔍 Current Active Mode

To check which mode is active:

```bash
cd /Users/mchaouachi/agent-system

# Check if using piped mode
if grep -q "cat.*|.*claude" planner-loop.sh; then
    echo "Active Mode: PIPED (automated)"
elif grep -q "claude$" planner-loop.sh; then
    echo "Active Mode: INTERACTIVE (manual)"
else
    echo "Active Mode: UNKNOWN"
fi
```

---

## 💡 Hybrid Approach (Future)

Possible future enhancement: Start in interactive mode, but if no activity detected for X minutes, automatically switch to piped mode. Best of both worlds!

---

## 📝 Technical Details

### Piped Mode Implementation
```bash
# Create prompt file
cat > prompt.txt <<EOF
Instructions here...
EOF

# Pipe to claude
cat prompt.txt | claude 2>&1 | tee -a log.txt
```

### Interactive Mode Implementation
```bash
# Show instructions
echo "Instructions here..."
echo "Starting Claude in 3 seconds..."
sleep 3

# Start Claude interactively
claude

# Wait for Claude to exit, then continue loop
```

---

## 🐛 Troubleshooting

### Interactive Mode Issues

**Problem:** Claude doesn't start
- Check `which claude` works
- Verify Claude CLI installed
- Check PATH in tmux environment

**Problem:** Loop doesn't continue after Claude exits
- Make sure you exit Claude properly (not Ctrl+C)
- Check if proposals file was updated
- View logs to see what happened

### Piped Mode Issues

**Problem:** Raw mode error in tmux
- This should be fixed now
- Make sure using latest version
- Check using piped approach, not heredoc

**Problem:** No output visible
- Check logs: `tail -f /path/to/project/coordination/logs/notifications.log`
- Use monitor window: `tmux attach -t agent_system_spec` then `Ctrl+b 2`

---

## Summary

You now have **two options** for running the agent loops:

1. **Piped Mode** (current default): Fully automated, no UI, works unattended
2. **Interactive Mode** (new option): Full Claude UI, manual control, better for monitoring

Choose based on your needs! Switch anytime by copying the appropriate loop files.
