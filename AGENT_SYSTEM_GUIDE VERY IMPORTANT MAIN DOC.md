# 📚 Agent System Complete Guide

## Quick Start Commands

```bash
# Start a new task
./launch-agents-from-spec.sh /path/to/project 001

# Resume existing work
./launch-agents-from-spec.sh /path/to/project 999

# View logs
tail -f /path/to/project/coordination/logs/agent_history.log

# Monitor status
tmux attach -t agent_system_spec
```

---

## 📋 Table of Contents

1. [Starting Fresh - New Feature Implementation](#1-starting-fresh---new-feature-implementation)
2. [Resuming Work - Continue Where You Left Off](#2-resuming-work---continue-where-you-left-off)  
3. [Test Fixing - Like We Did](#3-test-fixing---like-we-did)
4. [Chat History & Logging](#4-chat-history--logging)
5. [Creating Custom Tasks](#5-creating-custom-tasks)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Starting Fresh - New Feature Implementation

### Create a New Feature Spec

```bash
# 1. Create spec folder (use 3-digit numbers)
mkdir -p /path/to/project/specs/002-user-authentication

# 2. Create spec.md
cat > /path/to/project/specs/002-user-authentication/spec.md << 'EOF'
# Feature Specification: User Authentication

**Branch:** feature/user-auth
**Status:** In Development
**Created:** 2024-11-03

## User Scenarios & Testing

### User Stories
**P1: User Login**
- As a user, I need to log in with email/password
- Priority: P1 - Critical

### Acceptance Scenarios
**Scenario 1.1: Successful Login**
- **Given** valid credentials
- **When** user submits login form
- **Then** user is authenticated and redirected to dashboard

## Success Criteria
- SC-001: Authentication works with valid credentials
- SC-002: Invalid credentials show error
- SC-003: Session persists for 24 hours
- SC-004: Logout clears session

## Technical Requirements
- Use JWT tokens
- Hash passwords with bcrypt
- Implement rate limiting
- Add CSRF protection

## Implementation Notes
Work autonomously. Create all necessary files.
EOF
```

### Launch Agents for New Feature

```bash
# 3. Setup project (only first time)
./setup.sh /path/to/project

# 4. Launch agents
./launch-agents-from-spec.sh /path/to/project 002

# Agents will:
# - Read spec
# - Create implementation proposals
# - Get approval
# - Implement the feature
```

---

## 2. Resuming Work - Continue Where You Left Off

### Check Current Status

```bash
# See what's in progress
cat /path/to/project/coordination/task_proposals.json | python3 -m json.tool

# Check active work
cat /path/to/project/coordination/active_work_registry.json
```

### Resume Based on Status

#### If Status is "idle" or empty:
```bash
# Start fresh
echo '{}' > /path/to/project/coordination/task_proposals.json
./launch-agents-from-spec.sh /path/to/project 001
```

#### If Status is "awaiting_review":
```bash
# Reviewer needs to approve
./launch-agents-from-spec.sh /path/to/project 001
# Go to reviewer window (Ctrl+b 1)
# Claude should review and approve
```

#### If Status is "approved":
```bash
# Planner needs to implement
./launch-agents-from-spec.sh /path/to/project 001
# Planner will continue implementation
```

#### If Status is "implementing":
```bash
# Work in progress - just reconnect
tmux attach -t agent_system_spec
```

---

## 3. Test Fixing - Like We Did

### Setup Test Fixing Task

```bash
# 1. Create test-fixing spec
mkdir -p /path/to/project/specs/999-fix-remaining-tests

cat > /path/to/project/specs/999-fix-remaining-tests/spec.md << 'EOF'
# Feature Specification: Fix Remaining Tests

**Status:** In Development
**Current State:** 108/183 tests passing (59%)

## Task
Fix all remaining 75 tests to reach 100% test pass rate.

## Acceptance Criteria
- All 183 tests must pass
- No regression in currently passing tests
- Tests run in under 2 minutes
- Clean test output

## Implementation Notes
Work autonomously without asking permission between fixes.
Fix tests systematically: compilation errors first, then logic errors, then timing issues.
EOF

# 2. Launch agents
./launch-agents-from-spec.sh /path/to/project 999
```

### Monitor Test Progress

```bash
# In project directory
mvn test | tee test_results.log
# or
gradle test --info

# Check test count
grep "Tests run:" test_results.log
```

---

## 4. Chat History & Logging

### Enable Full Logging

Create this enhanced launcher with logging:

```bash
cat > launch-with-logging.sh << 'EOF'
#!/bin/bash
# Enhanced launcher with full chat logging

PROJECT_PATH="$1"
FEATURE_NUM="$2"
LOG_DIR="$PROJECT_PATH/coordination/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create log directory
mkdir -p "$LOG_DIR"

# Launch normal agents
./launch-agents-from-spec.sh "$PROJECT_PATH" "$FEATURE_NUM" &

# Start logging in background
(
  sleep 5
  while tmux has-session -t agent_system_spec 2>/dev/null; do
    # Capture planner output
    tmux capture-pane -t agent_system_spec:planner -p >> "$LOG_DIR/planner_$TIMESTAMP.log"
    echo "---[$(date)]---" >> "$LOG_DIR/planner_$TIMESTAMP.log"
    
    # Capture reviewer output
    tmux capture-pane -t agent_system_spec:reviewer -p >> "$LOG_DIR/reviewer_$TIMESTAMP.log"
    echo "---[$(date)]---" >> "$LOG_DIR/reviewer_$TIMESTAMP.log"
    
    # Merge into combined log
    echo "[PLANNER - $(date)]" >> "$LOG_DIR/agent_history.log"
    tail -20 "$LOG_DIR/planner_$TIMESTAMP.log" >> "$LOG_DIR/agent_history.log"
    echo "[REVIEWER - $(date)]" >> "$LOG_DIR/agent_history.log"
    tail -20 "$LOG_DIR/reviewer_$TIMESTAMP.log" >> "$LOG_DIR/agent_history.log"
    
    sleep 30
  done
) &

echo "📝 Logging to: $LOG_DIR/agent_history.log"
echo "📝 Individual logs: planner_$TIMESTAMP.log, reviewer_$TIMESTAMP.log"

wait
EOF

chmod +x launch-with-logging.sh

# Use it
./launch-with-logging.sh /path/to/project 001
```

### View Logs in Real-Time

```bash
# Combined history
tail -f /path/to/project/coordination/logs/agent_history.log

# Planner only
tail -f /path/to/project/coordination/logs/planner_*.log

# Reviewer only  
tail -f /path/to/project/coordination/logs/reviewer_*.log

# Everything
watch -n 2 'tail -30 /path/to/project/coordination/logs/*.log'
```

### Extract Claude Conversations

```bash
# Get all Claude inputs/outputs
grep -A 10 -B 2 "claude" /path/to/project/coordination/logs/*.log > claude_conversations.txt

# Get proposals created
grep -A 50 "proposals" /path/to/project/coordination/logs/*.log > proposals_history.txt

# Get approvals
grep -A 20 "approved" /path/to/project/coordination/logs/*.log > approvals_history.txt
```

---

## 5. Creating Custom Tasks

### Task Templates

#### Backend API Task
```bash
cat > specs/003-rest-api/spec.md << 'EOF'
# Feature Specification: REST API for Products

## Task
Create CRUD REST API endpoints for products.

## Endpoints Required
- GET /api/products - List all
- GET /api/products/:id - Get one
- POST /api/products - Create
- PUT /api/products/:id - Update
- DELETE /api/products/:id - Delete

## Success Criteria
- All endpoints return proper status codes
- Input validation on POST/PUT
- Error handling for missing resources
- Unit tests for each endpoint

## Implementation Notes
Use existing database schema. Add OpenAPI documentation.
Work autonomously.
EOF
```

#### Bug Fix Task
```bash
cat > specs/004-fix-memory-leak/spec.md << 'EOF'
# Feature Specification: Fix Memory Leak

## Issue
Application memory usage grows continuously, reaching 4GB after 24 hours.

## Investigation Notes
- Happens in production only
- Related to WebSocket connections
- Memory profiler shows retained objects in ConnectionPool

## Success Criteria
- Memory stays under 1GB for 48 hours
- No WebSocket connections leaked
- Performance not degraded

## Implementation Notes
Check connection cleanup, event listener removal, and connection pool limits.
Work autonomously.
EOF
```

#### Database Migration Task
```bash
cat > specs/005-db-migration/spec.md << 'EOF'
# Feature Specification: Add User Preferences Table

## Task
Create database migration for user preferences.

## Schema Required
CREATE TABLE user_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  theme VARCHAR(20) DEFAULT 'light',
  notifications_enabled BOOLEAN DEFAULT true,
  language VARCHAR(10) DEFAULT 'en',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

## Success Criteria
- Migration runs without errors
- Rollback script included
- Existing users get default preferences
- Foreign key constraints work

## Implementation Notes
Use project's migration tool. Test rollback. Work autonomously.
EOF
```

---

## 6. Troubleshooting

### Common Issues & Fixes

#### Agents Not Creating Proposals
```bash
# Reset and restart
echo '{}' > /path/to/project/coordination/task_proposals.json
rm -f /path/to/project/coordination/active_work_registry.json
./launch-agents-from-spec.sh /path/to/project 001
```

#### Reviewer Not Detecting Proposals
```bash
# Manually trigger review
tmux send-keys -t agent_system_spec:reviewer C-c  # Stop current
tmux send-keys -t agent_system_spec:reviewer "claude" Enter
# Wait for load then paste:
# Read proposals at /path/to/project/coordination/task_proposals.json
# Approve best one with status: approved
```

#### Planner Stuck Waiting
```bash
# Check if approved
cat /path/to/project/coordination/task_proposals.json | grep status

# If not approved, manually approve
sed -i '' 's/"awaiting_review"/"approved"/' /path/to/project/coordination/task_proposals.json
sed -i '' 's/"proposals"/"proposals","chosen_approach":"approach_1"/' /path/to/project/coordination/task_proposals.json
```

#### Session Disconnected
```bash
# Reconnect
tmux attach -t agent_system_spec

# Or list all sessions
tmux ls

# Kill and restart if needed
tmux kill-session -t agent_system_spec
./launch-agents-from-spec.sh /path/to/project 001
```

---

## 📊 Monitoring Dashboard

Create a monitoring script:

```bash
cat > monitor-agents.sh << 'EOF'
#!/bin/bash
while true; do
  clear
  echo "═══════════════════════════════════════════════════"
  echo "            AGENT SYSTEM DASHBOARD"
  echo "═══════════════════════════════════════════════════"
  echo ""
  echo "📁 PROJECT: $1"
  echo "📅 TIME: $(date)"
  echo ""
  echo "─── CURRENT STATUS ────────────────────────────────"
  grep -o '"status"[^,]*' "$1/coordination/task_proposals.json" 2>/dev/null || echo "Status: No proposals"
  echo ""
  echo "─── PROPOSALS COUNT ───────────────────────────────"
  grep -c '"id"' "$1/coordination/task_proposals.json" 2>/dev/null || echo "0"
  echo ""
  echo "─── LAST ACTIVITY ─────────────────────────────────"
  tail -3 "$1/coordination/logs/notifications.log" 2>/dev/null || echo "No activity"
  echo ""
  echo "─── AGENT STATUS ──────────────────────────────────"
  if tmux has-session -t agent_system_spec 2>/dev/null; then
    echo "✅ Agents RUNNING"
    echo "   Planner:  $(tmux capture-pane -t agent_system_spec:planner -p | tail -1)"
    echo "   Reviewer: $(tmux capture-pane -t agent_system_spec:reviewer -p | tail -1)"
  else
    echo "❌ Agents NOT RUNNING"
  fi
  echo ""
  echo "Press Ctrl+C to exit"
  sleep 5
done
EOF

chmod +x monitor-agents.sh
./monitor-agents.sh /path/to/project
```

---

## 🎯 Quick Reference Card

| Task | Command |
|------|---------|
| **New Feature** | `./launch-agents-from-spec.sh /project 001` |
| **Continue Work** | `tmux attach -t agent_system_spec` |
| **Fix Tests** | `./launch-agents-from-spec.sh /project 999` |
| **View Logs** | `tail -f /project/coordination/logs/agent_history.log` |
| **Check Status** | `cat /project/coordination/task_proposals.json \| jq .status` |
| **Reset All** | `echo '{}' > /project/coordination/task_proposals.json` |
| **Kill Agents** | `tmux kill-session -t agent_system_spec` |
| **Monitor** | `./monitor-agents.sh /project` |

---

## 💡 Pro Tips

1. **Always check logs first when debugging**
   ```bash
   tail -50 /project/coordination/logs/*.log
   ```

2. **Use meaningful spec numbers**
   - 001-099: Features
   - 100-199: Enhancements  
   - 200-299: Refactoring
   - 900-999: Fixes/Tests

3. **Keep specs focused**
   - One feature per spec
   - Clear acceptance criteria
   - Always include "Work autonomously"

4. **Monitor resource usage**
   ```bash
   htop  # Watch CPU/RAM while agents run
   ```

5. **Backup before major changes**
   ```bash
   cp -r /project /project.backup.$(date +%Y%m%d)
   ```

Need help? Check tmux windows: `Ctrl+b 0` (planner), `Ctrl+b 1` (reviewer), `Ctrl+b 2` (monitor)
