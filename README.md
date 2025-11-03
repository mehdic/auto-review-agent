# 🤖 Autonomous Agent Coordination System

A complete system for running autonomous Claude Code agents that communicate with each other via tmux, allowing you to observe and intervene when needed.

## 🎯 What This Does

This system creates **two autonomous agents** that work together:

1. **Planner Agent** - Receives a task, analyzes it, creates multiple technical approaches with pros/cons
2. **Reviewer Agent** - Monitors for new proposals, evaluates them, chooses the best one, and approves implementation
3. **Planner Agent** - Receives approval and implements the chosen approach automatically

**You can watch everything happening in real-time and intervene at any point!**

## 📋 Prerequisites

Before starting, ensure you have:

- **tmux** - Terminal multiplexer
  ```bash
  # Ubuntu/Debian
  sudo apt install tmux
  
  # macOS
  brew install tmux
  ```

- **Claude Code** - Anthropic's CLI tool
  ```bash
  npm install -g claude
  ```

- **jq** - JSON processor (for monitoring)
  ```bash
  # Ubuntu/Debian
  sudo apt install jq
  
  # macOS
  brew install jq
  ```

- **Claude API Access** - Either:
  - Claude Pro subscription ($20/month)
  - Claude Max subscription ($200/month) - Recommended for heavy use
  - Or API key for pay-per-use

## 🚀 Quick Start

### Step 1: Clone or Download This System

```bash
cd ~/
git clone <this-repo> agent-coordination-system
cd agent-coordination-system
chmod +x *.sh
```

### Step 2: Initialize Your Project

```bash
./setup.sh /path/to/your/project
```

This creates the coordination directory structure in your project:
```
your-project/
└── coordination/
    ├── task_proposals.json
    ├── active_work_registry.json
    ├── completed_work_log.json
    ├── planned_work_queue.json
    ├── messages/
    │   ├── planner_to_reviewer.json
    │   └── reviewer_to_planner.json
    ├── agent_locks/
    └── logs/
        ├── notifications.log
        └── agent_activity.log
```

### Step 3: Launch the Agents

```bash
./launch-agents.sh /path/to/your/project "Create a REST API for user authentication"
```

This will:
- Start a tmux session with 4 windows
- Launch the Planner agent
- Launch the Reviewer agent
- Set up monitoring dashboard
- Set up live log viewer

### Step 4: Watch Them Work!

The system automatically attaches you to the tmux session. You'll see:

- **Window 0 (planner)** - The planner agent creating proposals
- **Window 1 (reviewer)** - The reviewer agent monitoring and evaluating
- **Window 2 (monitor)** - Real-time coordination dashboard
- **Window 3 (logs)** - Live activity logs

## 🎮 Tmux Controls

### Navigate Between Windows
- `Ctrl+b 0` - Switch to Planner agent
- `Ctrl+b 1` - Switch to Reviewer agent
- `Ctrl+b 2` - Switch to Monitor dashboard
- `Ctrl+b 3` - Switch to Logs
- `Ctrl+b n` - Next window
- `Ctrl+b p` - Previous window

### Other Controls
- `Ctrl+b d` - Detach (agents keep running in background)
- `Ctrl+b z` - Zoom into current pane (toggle)
- `Ctrl+b [` - Enter scroll mode (use arrow keys, press `q` to exit)

### Reattach Later
```bash
tmux attach -t agent_system
```

## 🛑 Stopping the System

```bash
./stop-agents.sh
```

This gracefully stops all agents and closes the tmux session.

## 🔧 How It Works

### The Autonomous Workflow

1. **You give a task** to the Planner agent:
   ```
   "Create a REST API for user authentication"
   ```

2. **Planner analyzes** and creates 2-4 different approaches:
   - Approach 1: JWT-based authentication
   - Approach 2: Session-based authentication
   - Approach 3: OAuth2 integration
   
   Each with detailed pros, cons, effort estimates, and technical notes.

3. **Planner writes proposals** to `coordination/task_proposals.json`:
   ```json
   {
     "proposals": [...],
     "status": "awaiting_review",
     "planner_agent_id": "agent_123",
     "task_description": "Create a REST API..."
   }
   ```

4. **Reviewer monitors** the file every 30 seconds:
   - Sees `status: "awaiting_review"`
   - **Immediately springs into action!**

5. **Reviewer evaluates** each proposal:
   - Technical soundness
   - Risk assessment
   - Effort vs benefit
   - Project fit

6. **Reviewer chooses best approach** and approves:
   ```json
   {
     "status": "approved",
     "chosen_approach": "approach_1",
     "reviewer_notes": "JWT selected for scalability",
     "instruction_to_planner": "Add rate limiting..."
   }
   ```

7. **Planner sees approval** (checking every 30 seconds):
   - Reads chosen approach
   - Reads reviewer instructions
   - **Starts implementing immediately!**

8. **Planner implements** the solution:
   - Updates `active_work_registry.json` with progress
   - Logs updates every 5-10 minutes
   - Commits code
   - Marks work complete

9. **Reviewer verifies** completion:
   - Checks completed work log
   - Reviews implementation (optional)
   - System ready for next task!

### Communication Channels

Agents communicate through **shared JSON files**:

```
Planner → Reviewer:
  - coordination/task_proposals.json (main proposals)
  - coordination/messages/planner_to_reviewer.json (messages)
  - coordination/logs/notifications.log (activity log)

Reviewer → Planner:
  - coordination/task_proposals.json (approval/instructions)
  - coordination/messages/reviewer_to_planner.json (messages)
  - coordination/logs/notifications.log (activity log)
```

Both agents check these files **every 30 seconds** and react automatically.

## 👀 Monitoring

### Live Dashboard

Window 2 shows real-time status:
- Current proposal status
- Active work by each agent
- Completed tasks
- Unread messages
- Recent activity log

### Log Viewer

Window 3 shows live notifications:
```
[2024-01-15T10:35:00Z] PLANNER: Created 3 proposals - JWT, Session, OAuth
[2024-01-15T10:36:00Z] REVIEWER: Received proposals for review
[2024-01-15T10:38:00Z] REVIEWER: Selected JWT approach for simplicity
[2024-01-15T10:39:00Z] REVIEWER: Approval sent with security enhancements
[2024-01-15T10:40:00Z] PLANNER: Received approval for JWT approach
[2024-01-15T10:45:00Z] PLANNER: Starting implementation
[2024-01-15T11:30:00Z] PLANNER: Implementation complete
```

### Manual Monitoring

You can also watch files directly:
```bash
# Watch proposals file
watch -n 2 "cat /your/project/coordination/task_proposals.json | jq ."

# Watch notifications
tail -f /your/project/coordination/logs/notifications.log

# Watch messages
watch -n 2 "cat /your/project/coordination/messages/planner_to_reviewer.json | jq ."
```

## 🎯 Intervening

You can intervene at any time!

### Method 1: Direct Agent Interaction

1. Switch to the agent's window:
   ```
   Ctrl+b 0  (for Planner)
   Ctrl+b 1  (for Reviewer)
   ```

2. Type your message directly:
   ```
   "Wait! Don't implement that yet. I need to review the security implications first."
   ```

3. Press Enter

The agent will respond to you and pause until you give further instructions.

### Method 2: Modify Coordination Files

You can also directly edit the coordination files:

```bash
# In another terminal
vim /your/project/coordination/task_proposals.json

# Change status to "blocked" or add notes
# Agents will see this on their next check (within 30 seconds)
```

### Method 3: Stop and Restart

```bash
# Stop everything
./stop-agents.sh

# Review the coordination files
cat /your/project/coordination/task_proposals.json

# Restart with modifications
./launch-agents.sh /your/project "Continue with the JWT approach"
```

## 🔍 Example Session

Here's what a complete autonomous session looks like:

```bash
# 1. Setup
./setup.sh ~/my-app
./launch-agents.sh ~/my-app "Add user authentication to the API"

# 2. Watch Planner (Window 0)
# You see: Creating proposals... analyzing best practices... 
# Writes 3 approaches to task_proposals.json

# 3. Switch to Monitor (Window 2)
Ctrl+b 2
# See: Status: awaiting_review, 3 proposals created

# 4. Switch to Reviewer (Window 1)
Ctrl+b 1
# You see: "Received proposals... evaluating... JWT selected for..."
# Updates task_proposals.json with approval

# 5. Switch back to Planner (Window 0)
Ctrl+b 0
# You see: "Approval received! Implementing JWT approach..."
# Starts coding autonomously

# 6. Watch Logs (Window 3)
Ctrl+b 3
# See live updates of everything happening

# 7. (Optional) Intervene
Ctrl+b 0
# Type: "Add two-factor authentication support as well"
# Planner adjusts and continues

# 8. Wait for completion
# Monitor shows: Status: completed

# 9. Review the code
# Switch to your normal terminal and check the changes

# 10. Done!
./stop-agents.sh
```

## 🎨 Customization

### Modify Agent Behavior

Edit the prompt files:
- `prompts/planner_agent.txt` - Change how planner analyzes tasks
- `prompts/reviewer_agent.txt` - Change review criteria

### Adjust Monitoring Frequency

In the prompt files, change the monitoring interval:
```
Every 30 seconds, check coordination/task_proposals.json
```
Change `30 seconds` to whatever you prefer.

### Add More Agents

You can add a third agent (e.g., a QA tester):

1. Create `prompts/tester_agent.txt`
2. Modify `launch-agents.sh` to add another window
3. Have the tester monitor `completed_work_log.json`
4. Tester can review and send feedback via messages

### Change Model

By default, agents use Claude Sonnet. To change:
```bash
# In launch-agents.sh, modify the claude command:
claude --model claude-opus-4
```

## 🐛 Troubleshooting

### Agents Not Starting

**Problem:** Claude Code fails to start
**Solution:** Make sure you're authenticated:
```bash
claude auth login
```

### Agents Not Communicating

**Problem:** Status stays "awaiting_review" forever
**Solution:** 
1. Check logs: `tail coordination/logs/notifications.log`
2. Verify JSON files are valid: `jq . coordination/task_proposals.json`
3. Check reviewer is actually running: Switch to window 1

### Permission Errors

**Problem:** Claude keeps asking for permissions
**Solution:** Use danger mode (only if you trust your setup):
```bash
# In launch-agents.sh, modify:
claude --project . --dangerously-skip-permissions
```

### Tmux Not Found

**Problem:** `tmux: command not found`
**Solution:** Install tmux:
```bash
# Ubuntu/Debian
sudo apt install tmux

# macOS
brew install tmux
```

### Can't See Agent Output

**Problem:** Tmux windows are blank
**Solution:**
1. Make sure prompts loaded: `ls -la prompts/`
2. Check Claude is installed: `which claude`
3. Try attaching: `tmux attach -t agent_system`

## 📚 Advanced Usage

### Run Multiple Projects Simultaneously

```bash
# Project 1
./launch-agents.sh ~/project1 "Add search feature" 

# Detach: Ctrl+b d

# Project 2 (will create new session)
# Edit launch-agents.sh to use different SESSION_NAME first
./launch-agents.sh ~/project2 "Fix payment bug"
```

### Integration with Git Worktrees

For better isolation:
```bash
# Create worktrees for each agent
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b

# Launch agents in separate worktrees
./launch-agents.sh ../project-feature-a "Implement feature A"
# Detach
./launch-agents.sh ../project-feature-b "Implement feature B"
```

### Scheduled Autonomous Runs

Use cron to run agents on a schedule:
```bash
# Add to crontab (crontab -e)
0 */6 * * * cd /path/to/agent-system && ./launch-agents.sh /path/to/project "Fix linting errors" >> /tmp/agent-cron.log 2>&1
```

### Export Session History

```bash
# Capture all activity
tmux capture-pane -pt agent_system:planner -S - > planner-history.txt
tmux capture-pane -pt agent_system:reviewer -S - > reviewer-history.txt
```

## 🔒 Security Considerations

1. **Trust Your Agents** - They have full access to your project files
2. **Use Danger Mode Carefully** - `--dangerously-skip-permissions` means no safety checks
3. **Review Completions** - Always review code before deploying
4. **Private Repositories** - Make sure coordination/ directory is in .gitignore
5. **API Keys** - Don't let agents write API keys to files

## 📖 Further Reading

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Multi-Agent Systems](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)

## 🤝 Contributing

Ideas for improvements:
- Add more agent roles (QA tester, documentation writer)
- Better error recovery
- Web-based monitoring dashboard
- Integration with project management tools
- Automatic git commit strategy

## 📝 License

MIT License - Use freely!

## 🎉 Credits

Built with:
- Claude Code by Anthropic
- tmux for terminal multiplexing
- jq for JSON processing

---

**Happy autonomous coding! 🚀**

Need help? Open an issue or check the troubleshooting section above.
