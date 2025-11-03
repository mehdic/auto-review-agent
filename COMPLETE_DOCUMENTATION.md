# 📚 Agent System Complete Documentation

## 🚀 Quick Start (Copy & Paste Ready)

### 1. Start a New Task/Feature
```bash
# Create spec
mkdir -p /Users/mchaouachi/IdeaProjects/StockMonitor/specs/001-new-feature
echo "# Feature Specification: Your Feature
## Task
Description here
## Success Criteria  
- Requirement 1
- Requirement 2
## Implementation Notes
Work autonomously." > specs/001-new-feature/spec.md

# Launch
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 001
```

### 2. Start Fresh (Reset Everything)
```bash
# Clear all state
echo '{}' > /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json
rm -f /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/active_work_registry.json

# Start fresh
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 999
```

### 3. Resume Like We Did
```bash
# Just reattach to existing session
tmux attach -t agent_system_spec

# Or restart where left off
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 999
# Agents will continue from current state
```

### 4. Enable Chat History Logging
```bash
# Run the logging setup
chmod +x setup-logging.sh
./setup-logging.sh /Users/mchaouachi/IdeaProjects/StockMonitor

# Then your logs will be saved to:
# - /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/planner/
# - /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/reviewer/
# - /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/combined/agent_history.log

# View logs in real-time:
tail -f /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/combined/agent_history.log
```

---

## 📋 Your Typical Workflow

### For Test Fixing (Current Task)
```bash
# Check progress
tmux attach -t agent_system_spec
# Monitor shows proposals status
# Planner shows Claude working
# Reviewer shows approval process

# Check test results
cd /Users/mchaouachi/IdeaProjects/StockMonitor
mvn test | grep "Tests run"
```

### For New Features
1. Create spec in `specs/XXX-feature-name/spec.md`
2. Run `./launch-agents-from-spec.sh /path/to/project XXX`
3. Watch agents create proposals → approve → implement
4. Check logs if needed

### Quick Status Check
```bash
# See current state
cat /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json | python3 -m json.tool | grep status

# Statuses:
# "idle" - Nothing happening
# "awaiting_review" - Proposals created, waiting for reviewer
# "approved" - Ready to implement
# "implementing" - Work in progress
```

---

## 🎮 Tmux Cheat Sheet for Your Mac

| Action | Keys |
|--------|------|
| **Switch to Planner** | `Ctrl+b`, then `0` |
| **Switch to Reviewer** | `Ctrl+b`, then `1` |
| **Switch to Monitor** | `Ctrl+b`, then `2` |
| **Detach (keep running)** | `Ctrl+b`, then `d` |
| **Reattach** | `tmux attach -t agent_system_spec` |
| **Kill session** | `tmux kill-session -t agent_system_spec` |
| **Scroll up in window** | `Ctrl+b`, then `[`, then arrow keys |
| **Exit scroll mode** | `q` |

---

## 💡 Pro Tips

1. **Always include "Work autonomously"** in your specs
2. **Specs should be focused** - one task per spec
3. **Number your specs logically**:
   - 001-099: Features
   - 100-199: Bug fixes
   - 900-999: Tests/Maintenance
4. **Check logs first** when debugging
5. **Let agents finish** - don't interrupt unless stuck

---

## 📁 Directory Structure

```
/Users/mchaouachi/IdeaProjects/StockMonitor/
├── specs/
│   ├── 001-feature-name/
│   │   └── spec.md                    # Feature specification
│   ├── 002-another-feature/
│   │   └── spec.md
│   └── 999-fix-remaining-tests/
│       └── spec.md                    # Current test fixing task
└── coordination/
    ├── task_proposals.json            # Current proposals and status
    ├── active_work_registry.json      # Active agent work
    ├── messages/                      # Inter-agent messages
    └── logs/
        ├── planner/                   # Planner session logs
        ├── reviewer/                  # Reviewer session logs
        └── combined/
            ├── agent_history.log      # Complete history
            ├── claude_conversations.log # Claude interactions
            └── json_events.log        # State changes

/Users/mchaouachi/agent-system/
├── launch-agents-from-spec.sh         # Main launcher
├── planner-loop.sh                    # Planner agent script
├── reviewer-loop.sh                   # Reviewer agent script
├── monitor-loop.sh                    # Monitor script
├── setup-logging.sh                   # Logging setup
└── prompts/
    ├── planner_agent_spec.txt        # Planner instructions
    └── reviewer_agent_spec.txt       # Reviewer instructions
```

---

## 🔄 Complete Workflows

### A. Creating a New Feature from Scratch

```bash
# Step 1: Create the spec
mkdir -p /Users/mchaouachi/IdeaProjects/StockMonitor/specs/003-portfolio-api
cat > /Users/mchaouachi/IdeaProjects/StockMonitor/specs/003-portfolio-api/spec.md << 'EOF'
# Feature Specification: Portfolio REST API

## Task
Create REST API endpoints for portfolio management.

## Endpoints Required
- GET /api/portfolio - Get user portfolio
- POST /api/portfolio/add - Add stock to portfolio
- DELETE /api/portfolio/remove - Remove stock
- GET /api/portfolio/value - Calculate total value

## Success Criteria
- All endpoints return proper JSON
- Authentication required
- Response time < 100ms
- Unit tests for each endpoint

## Implementation Notes
Use existing StockService for prices. Work autonomously.
EOF

# Step 2: Clear any previous state (optional)
echo '{}' > /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json

# Step 3: Launch agents
cd /Users/mchaouachi/agent-system
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 003

# Step 4: Monitor progress
# Ctrl+b 2 for monitor window
# Or in new terminal:
watch -n 2 'cat /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json | grep status'

# Step 5: Check implementation
# Agents will create files in your project
ls -la /Users/mchaouachi/IdeaProjects/StockMonitor/src/
```

### B. Fix Failing Tests (Current Scenario)

```bash
# Step 1: Check current test status
cd /Users/mchaouachi/IdeaProjects/StockMonitor
mvn test | tee test_before.log
# Note: 108/183 passing

# Step 2: Reset if needed
echo '{}' > coordination/task_proposals.json

# Step 3: Launch test-fixing agents
cd /Users/mchaouachi/agent-system
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 999

# Step 4: Watch progress
tmux attach -t agent_system_spec
# Monitor window shows proposals status
# Planner shows test fixes being applied

# Step 5: Verify fixes
cd /Users/mchaouachi/IdeaProjects/StockMonitor
mvn test | tee test_after.log
diff test_before.log test_after.log
```

### C. Resume Interrupted Work

```bash
# Step 1: Check current state
cat /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json | python3 -m json.tool

# Step 2: Based on status, take action:

# If "idle" - start fresh:
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 999

# If "awaiting_review" - reviewer needs to work:
tmux attach -t agent_system_spec
# Go to reviewer window (Ctrl+b 1)
# If stuck, restart Claude there

# If "approved" - planner needs to implement:
tmux attach -t agent_system_spec
# Go to planner window (Ctrl+b 0)
# If stuck, restart Claude there

# If "implementing" - work in progress:
tmux attach -t agent_system_spec
# Just monitor, don't interrupt
```

---

## 🔍 Debugging Common Issues

### Issue: "Command too long"
```bash
# Already fixed! But if it appears again:
./fix-launch-script.sh
```

### Issue: Agents Not Creating Proposals
```bash
# Check planner window
tmux attach -t agent_system_spec
# Ctrl+b 0

# If Claude not running, start it:
tmux send-keys -t agent_system_spec:planner C-c
tmux send-keys -t agent_system_spec:planner "claude" Enter
# Wait 3 seconds
tmux send-keys -t agent_system_spec:planner "Read /Users/mchaouachi/agent-system/prompts/planner_agent_spec.txt and /Users/mchaouachi/IdeaProjects/StockMonitor/specs/999-fix-remaining-tests/spec.md. Create proposals in /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json with status: awaiting_review" Enter
```

### Issue: Reviewer Not Approving
```bash
# Check reviewer window
tmux attach -t agent_system_spec
# Ctrl+b 1

# If stuck, manually approve:
echo '{"status": "approved", "chosen_approach": "approach_1"}' > /tmp/approval.json
jq -s '.[0] * .[1]' /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json /tmp/approval.json > /tmp/merged.json
mv /tmp/merged.json /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json
```

### Issue: Claude Not Responding
```bash
# Test Claude
echo "Say hello" | claude

# If not working:
claude auth

# Or check CLI version:
which claude
claude --version
```

---

## 📊 Advanced Monitoring

### Real-Time Dashboard
```bash
# Create monitoring script
cat > monitor-dashboard.sh << 'EOF'
#!/bin/bash
while true; do
  clear
  echo "════════════════════════════════════════"
  echo "    AGENT SYSTEM DASHBOARD - $(date +%H:%M:%S)"
  echo "════════════════════════════════════════"
  
  # Status
  echo -n "Status: "
  grep -o '"status"[^,]*' /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json | cut -d'"' -f4
  
  # Test progress
  echo -n "Tests: "
  cd /Users/mchaouachi/IdeaProjects/StockMonitor && mvn test 2>/dev/null | grep "Tests run:" | tail -1
  
  # Agent activity
  echo ""
  echo "Recent Activity:"
  tail -3 /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/combined/agent_history.log 2>/dev/null
  
  sleep 5
done
EOF

chmod +x monitor-dashboard.sh
./monitor-dashboard.sh
```

### Log Analysis
```bash
# Find all proposals created
grep -h "proposals" /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/planner/* | less

# Find all approvals
grep -h "approved" /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/reviewer/* | less

# Extract Claude conversations
grep -A 20 -B 5 "claude" /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/combined/*.log > all_claude_chats.txt

# Search for errors
grep -i "error\|fail\|exception" /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/combined/*.log
```

---

## 📝 Spec Templates

### Feature Implementation
```markdown
# Feature Specification: [Feature Name]

## Task
[Clear description of what needs to be built]

## Requirements
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

## Success Criteria
- [Measurable outcome 1]
- [Measurable outcome 2]

## Technical Notes
[Any technical constraints or guidance]

## Implementation Notes
Work autonomously. Create all necessary files and tests.
```

### Bug Fix
```markdown
# Feature Specification: Fix [Issue]

## Issue
[Description of the bug]

## Current Behavior
[What happens now]

## Expected Behavior
[What should happen]

## Success Criteria
- Bug no longer occurs
- No regression in other features
- Tests added to prevent recurrence

## Implementation Notes
Work autonomously. Fix root cause, not symptoms.
```

### Performance Optimization
```markdown
# Feature Specification: Optimize [Component]

## Current Performance
[Current metrics]

## Target Performance
[Target metrics]

## Areas to Investigate
- [Area 1]
- [Area 2]

## Success Criteria
- Performance improved by X%
- No functionality regression
- Metrics logged

## Implementation Notes
Work autonomously. Profile before optimizing.
```

---

## 🎯 Quick Command Reference

```bash
# Launch agents
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor [SPEC_NUMBER]

# Attach to session
tmux attach -t agent_system_spec

# Reset everything
echo '{}' > /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json

# View status
cat /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json | grep status

# View logs
tail -f /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/logs/combined/agent_history.log

# Kill session
tmux kill-session -t agent_system_spec

# List specs
ls /Users/mchaouachi/IdeaProjects/StockMonitor/specs/

# Test the project
cd /Users/mchaouachi/IdeaProjects/StockMonitor && mvn test
```

---

## 💾 Backup Strategy

```bash
# Before major changes
cd /Users/mchaouachi/IdeaProjects
tar -czf StockMonitor_backup_$(date +%Y%m%d_%H%M%S).tar.gz StockMonitor/

# Backup just coordination state
cd /Users/mchaouachi/IdeaProjects/StockMonitor
tar -czf coordination_backup_$(date +%Y%m%d).tar.gz coordination/

# Backup logs
cd /Users/mchaouachi/IdeaProjects/StockMonitor/coordination
tar -czf logs_$(date +%Y%m%d).tar.gz logs/

# Git commit before agent changes
cd /Users/mchaouachi/IdeaProjects/StockMonitor
git add -A && git commit -m "Backup before agent task $(date)"
```

---

## 🔐 Safety Checks

```bash
# Dry run to see what agents would do
cat specs/999-fix-remaining-tests/spec.md
# Review spec before launching

# Monitor file changes
watch -n 1 'find /Users/mchaouachi/IdeaProjects/StockMonitor -type f -mmin -5 -ls'

# Check git diff regularly
cd /Users/mchaouachi/IdeaProjects/StockMonitor
git status
git diff
```

---

## 📈 Success Metrics

Track your agent system performance:

```bash
# Time to create proposals
START=$(date +%s)
./launch-agents-from-spec.sh /Users/mchaouachi/IdeaProjects/StockMonitor 001
# Wait for proposals...
END=$(date +%s)
echo "Proposals created in $((END-START)) seconds"

# Test improvement rate
BEFORE=$(mvn test | grep "Tests run" | awk '{print $5}')
# Run agents...
AFTER=$(mvn test | grep "Tests run" | awk '{print $5}')
echo "Tests fixed: $((AFTER-BEFORE))"

# Lines of code generated
git diff --stat
```

---

Remember: The system works best with clear, focused specs. Always include "Work autonomously" in your specifications!
