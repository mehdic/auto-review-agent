# 📦 COMPLETE AUTONOMOUS AGENT SYSTEM - PACKAGE CONTENTS

## 🎯 What You Have

A complete, ready-to-use system for running autonomous Claude Code agents that:
- ✅ Communicate with each other via shared files
- ✅ Work completely autonomously (no human intervention needed)
- ✅ Can be monitored in real-time via tmux
- ✅ Allow you to intervene at any moment
- ✅ Log all activities for transparency

## 📁 Directory Structure

```
agent-coordination-system/
├── setup.sh                    # Initialize a project with coordination system
├── launch-agents.sh            # Start the agents in tmux
├── stop-agents.sh              # Stop all agents gracefully
├── monitor.sh                  # Real-time monitoring dashboard
├── QUICKSTART.sh               # Quick start guide (run this for help!)
├── README.md                   # Complete documentation
├── EXAMPLE_TASKS.md            # Example tasks to try
└── prompts/
    ├── planner_agent.txt       # Planner agent prompt/instructions
    └── reviewer_agent.txt      # Reviewer agent prompt/instructions

After running setup.sh, your project will have:

your-project/
└── coordination/
    ├── task_proposals.json           # Main communication file
    ├── active_work_registry.json     # What agents are doing now
    ├── completed_work_log.json       # History of completed work
    ├── planned_work_queue.json       # Upcoming work queue
    ├── messages/
    │   ├── planner_to_reviewer.json  # Messages from planner
    │   └── reviewer_to_planner.json  # Messages from reviewer
    ├── agent_locks/                  # Lock files (for future use)
    └── logs/
        ├── notifications.log         # All agent activity
        └── agent_activity.log        # Detailed activity log
```

## 🚀 Files Explained

### Core Scripts

**setup.sh**
- Run once per project
- Creates coordination directory structure
- Initializes all JSON files
- Takes ~5 seconds

**launch-agents.sh**
- Starts both agents in tmux
- Opens 4 windows: planner, reviewer, monitor, logs
- Automatically attaches you to the session
- Pass it your project path and task description

**stop-agents.sh**
- Gracefully stops all agents
- Closes tmux session
- Preserves all coordination files

**monitor.sh**
- Real-time dashboard of agent activity
- Shows task status, active work, completed tasks
- Refreshes every 2 seconds
- Used by launch-agents.sh automatically

**QUICKSTART.sh**
- Display this to see quick commands
- Just run: ./QUICKSTART.sh
- Shows complete workflow example

### Documentation

**README.md** (13KB)
- Complete documentation
- How everything works
- Troubleshooting guide
- Advanced usage patterns
- Security considerations

**EXAMPLE_TASKS.md** (5KB)
- 14 example tasks you can try
- Categorized by complexity
- Expected agent behavior for each
- Tips for testing

**THIS FILE** (you're reading it!)
- Package contents overview
- Quick reference guide

### Agent Prompts

**prompts/planner_agent.txt** (8KB)
- Complete instructions for the planner agent
- How to analyze tasks
- How to create proposals
- How to implement chosen approach
- Communication protocol
- Logging requirements

**prompts/reviewer_agent.txt** (11KB)
- Complete instructions for the reviewer agent
- How to monitor for new proposals
- Evaluation criteria
- Decision-making guidelines
- How to approve with instructions
- Follow-up protocol

## 🎮 How to Use (Ultra-Quick)

```bash
# 1. One-time setup per project
./setup.sh /path/to/your/project

# 2. Launch agents with a task
./launch-agents.sh /path/to/your/project "Create user authentication API"

# 3. Watch them work!
# Ctrl+b 0 = Planner
# Ctrl+b 1 = Reviewer
# Ctrl+b 2 = Monitor
# Ctrl+b 3 = Logs

# 4. Intervene if needed
# Switch to agent window and type directly

# 5. When done
./stop-agents.sh
```

## 🔑 Key Features

### 1. Autonomous Operation
- Agents work completely independently
- No "should I proceed?" questions
- Planner creates proposals automatically
- Reviewer approves automatically
- Planner implements automatically

### 2. Real-time Monitoring
- See everything happening live
- Dashboard shows current status
- Logs show all activity
- Messages between agents visible

### 3. Human Intervention
- Jump in at any moment
- Type directly to agents
- Modify coordination files
- Stop/restart as needed

### 4. Transparency
- All decisions logged
- All communication visible
- Complete audit trail
- Easy to review what happened

## 📊 Agent Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         USER                                │
│                          │                                  │
│                          ▼                                  │
│                    "Create REST API"                        │
│                          │                                  │
└──────────────────────────┼──────────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
            ▼                             ▼
     ┌─────────────┐              ┌─────────────┐
     │   PLANNER   │              │  REVIEWER   │
     │    AGENT    │              │    AGENT    │
     └──────┬──────┘              └──────┬──────┘
            │                            │
            │  1. Create proposals       │
            ├───────────────────────────>│
            │    (via JSON files)        │
            │                            │
            │                      2. Evaluate
            │                            │
            │  3. Receive approval       │
            │<───────────────────────────┤
            │    (via JSON files)        │
            │                            │
      4. Implement                       │
            │                            │
            │  5. Notify completion      │
            ├───────────────────────────>│
            │    (via JSON files)        │
            │                            │
            │                      6. Verify
            │                            │
            ▼                            ▼
     ┌────────────────────────────────────────┐
     │       PROJECT FILES UPDATED            │
     │    (Code, Tests, Documentation)        │
     └────────────────────────────────────────┘
```

## 🕐 Typical Timeline

```
T+0:00  User gives task to Planner
T+0:05  Planner creates 3 proposals
T+0:06  Planner writes to task_proposals.json
T+0:07  Status → "awaiting_review"
T+0:30  Reviewer checks file (every 30s)
T+0:35  Reviewer evaluates all proposals
T+0:40  Reviewer chooses best one
T+0:41  Status → "approved"
T+1:00  Planner checks file (every 30s)
T+1:05  Planner starts implementation
T+2:00  Planner completes work
T+2:01  Status → "completed"
```

## 📋 Checklist: Did You...?

Before first use:
- [ ] Install tmux (`sudo apt install tmux` or `brew install tmux`)
- [ ] Install jq (`sudo apt install jq` or `brew install jq`)
- [ ] Install Claude Code (`npm install -g claude`)
- [ ] Authenticate Claude (`claude auth login`)
- [ ] Make scripts executable (`chmod +x *.sh`)

For each project:
- [ ] Run setup.sh on your project directory
- [ ] Verify coordination/ directory was created
- [ ] Check that JSON files were initialized

For each session:
- [ ] Run launch-agents.sh with project path and task
- [ ] Verify both agents started (check windows 0 and 1)
- [ ] Monitor dashboard is running (window 2)
- [ ] Logs are flowing (window 3)

## 🎓 Learning Path

**Day 1: Learn the basics**
1. Read QUICKSTART.sh
2. Try simple task: "Add input validation"
3. Watch agents communicate
4. Practice tmux navigation

**Day 2: Understand the system**
1. Read README.md sections: How It Works, Monitoring
2. Try medium task: "Implement search feature"
3. Try intervening mid-task
4. Review coordination files manually

**Day 3: Master the workflow**
1. Read full README.md
2. Try complex task: "Add real-time chat"
3. Customize agent prompts
4. Add third agent (optional)

**Day 4+: Advanced usage**
1. Multiple projects simultaneously
2. Integration with git worktrees
3. Custom monitoring setup
4. Automated scheduled runs

## 🐛 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Agents don't start | Run `claude auth login` |
| No communication | Wait 30 seconds (agents check every 30s) |
| Permission errors | Add `--dangerously-skip-permissions` to claude commands |
| Tmux not found | Install: `apt install tmux` or `brew install tmux` |
| JSON parse errors | Check file validity: `jq . file.json` |
| Agents seem stuck | Check logs: `tail coordination/logs/notifications.log` |

## 💡 Pro Tips

1. **Keep logs window visible** - Ctrl+b 3 shows everything happening
2. **Use monitor for big picture** - Ctrl+b 2 for high-level status
3. **Start simple** - Try easy tasks first to learn the flow
4. **Review coordination files** - They're the "source of truth"
5. **Intervene early** - Don't wait until agents go too far off track
6. **Detach liberally** - Ctrl+b d lets agents work while you do other things
7. **Check both agents** - Sometimes one is waiting for the other

## 🎯 Next Steps

Ready to start? Here's your action plan:

**Right now (5 minutes):**
```bash
./QUICKSTART.sh              # Read the quick guide
./setup.sh ~/test-project    # Setup a test project
```

**First test (10 minutes):**
```bash
./launch-agents.sh ~/test-project "Add input validation to login"
# Watch what happens!
# Try switching between windows
# Try intervening
./stop-agents.sh
```

**Real work (ongoing):**
```bash
./setup.sh /path/to/real/project
./launch-agents.sh /path/to/real/project "Your actual task"
# Let them work while you monitor
```

## 📞 Support

- **Quick help**: Run `./QUICKSTART.sh`
- **Documentation**: Read `README.md`
- **Examples**: Check `EXAMPLE_TASKS.md`
- **Troubleshooting**: See README.md → Troubleshooting section

## ✨ What Makes This Special

Unlike other multi-agent systems:
- ✅ **No API to configure** - Works with your Claude subscription
- ✅ **No complex setup** - Two scripts and you're running
- ✅ **Complete visibility** - See everything in real-time
- ✅ **Human in the loop** - Intervene anytime
- ✅ **Production ready** - Actually works on real projects
- ✅ **Well documented** - You're reading proof!

## 🚀 Ready?

```bash
# Let's go!
./setup.sh /your/project
./launch-agents.sh /your/project "Your task description"

# Watch the magic happen! ✨
```

---

**Built with ❤️ for autonomous development**

Questions? Read the README.md
Need help? Check QUICKSTART.sh
Want ideas? See EXAMPLE_TASKS.md

Happy coding! 🎉
