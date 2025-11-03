# 🎯 STEP-BY-STEP: Strict Mode with Task Lists & Session Resumption

This is your complete guide for setting up the STRICT MODE system where:
- ✅ Planner resumes sessions and continues from task lists
- ✅ Reviewer enforces ALL tests (TDD, unit, integration, contract, e2e)
- ✅ Reviewer insists on complete implementation
- ✅ No skipping, no laziness, everything must work

---

## 📥 PHASE 1: Download New Files (2 minutes)

You need these NEW strict mode files:

### Download These:

1. [**launch-agents-strict.sh**](computer:///mnt/user-data/outputs/launch-agents-strict.sh) - Enhanced launcher with session resumption
2. [**planner_agent_strict.txt**](computer:///mnt/user-data/outputs/planner_agent_strict.txt) - Strict planner (21KB)
3. [**reviewer_agent_strict.txt**](computer:///mnt/user-data/outputs/reviewer_agent_strict.txt) - Strict reviewer (25KB)
4. [**STRICT_MODE_GUIDE.md**](computer:///mnt/user-data/outputs/STRICT_MODE_GUIDE.md) - Complete guide (22KB)

### Place Them Here:

```bash
# After downloading, organize like this:
cd ~/agent-system

# Copy strict launcher
cp ~/Downloads/launch-agents-strict.sh .
chmod +x launch-agents-strict.sh

# Copy strict prompts
cp ~/Downloads/planner_agent_strict.txt prompts/
cp ~/Downloads/reviewer_agent_strict.txt prompts/
```

---

## 📋 PHASE 2: Create Your Task List (5 minutes)

### Step 1: Create tasks.md in Your Project

```bash
# Navigate to your project
cd /path/to/your/project

# Create tasks.md
nano tasks.md
```

### Step 2: Write Your Tasks

**Format:** Numbered list, one task per line

```markdown
# Project Tasks

1. Add user authentication with JWT tokens
2. Implement rate limiting middleware (100 req/15min)
3. Add password reset functionality with email
4. Create user profile endpoints (GET, PUT, DELETE)
5. Add email verification system
6. Implement role-based access control (RBAC)
7. Add comprehensive error handling middleware
8. Create API documentation with OpenAPI/Swagger
```

**Important:**
- Be SPECIFIC (not vague like "make it better")
- One clear task per line
- Order matters (dependencies first)
- Keep tasks 2-4 hours each

### Step 3: Save and Verify

```bash
# Save the file (Ctrl+X, Y, Enter in nano)

# Verify it's there
cat tasks.md

# Should see your numbered list
```

---

## 🚀 PHASE 3: Launch in Strict Mode (1 minute)

### Option A: New Project Start

```bash
# Launch with strict mode
~/agent-system/launch-agents-strict.sh /path/to/your/project "Complete all tasks in tasks.md"
```

### Option B: Resume Previous Session

```bash
# Resume the last session (continues where it left off)
~/agent-system/launch-agents-strict.sh --continue /path/to/your/project
```

### What Happens:

```
═══════════════════════════════════════════
🎯 PLANNER AGENT (STRICT MODE) STARTING
═══════════════════════════════════════════

STRICT MODE ENABLED:
  ✓ Complete implementation required
  ✓ All tests must pass (unit, integration, contract, e2e)
  ✓ No TODOs or placeholders allowed
  ✓ Full verification before proceeding

Reading tasks.md...
Found 8 tasks
Creating task tracking system...

Starting Task 1/8: Add user authentication with JWT tokens
```

---

## 👀 PHASE 4: Watch It Work (Ongoing)

### Window Layout (4 Windows)

```
Ctrl+b 0  →  🎯 PLANNER AGENT
              - Reading tasks
              - Creating proposals
              - Writing tests
              - Implementing features

Ctrl+b 1  →  ✅ REVIEWER AGENT
              - Evaluating proposals
              - Enforcing test requirements
              - Verifying completions
              - Rejecting incomplete work

Ctrl+b 2  →  📊 MONITOR DASHBOARD
              - Current task (e.g., "Task 3/8")
              - Status
              - Test results
              - Completed tasks

Ctrl+b 3  →  📝 ACTIVITY LOGS
              - Real-time progress
              - All agent actions
              - Test results
              - Verifications
```

### Typical Flow You'll See

```
[10:00] PLANNER: [Task 1/8] Reading tasks.md - Found 8 tasks
[10:01] PLANNER: [Task 1/8] Creating proposals for authentication
[10:06] PLANNER: [Task 1/8] Created 3 proposals (JWT, Sessions, OAuth)
[10:07] REVIEWER: [Task 1/8] Received proposals
[10:08] REVIEWER: [Task 1/8] Evaluating approaches...
[10:12] REVIEWER: [Task 1/8] Selected JWT with STRICT requirements
[10:30] PLANNER: [Task 1/8] Approval received - starting TDD
[10:31] PLANNER: [Task 1/8] Writing unit tests FIRST
[10:45] PLANNER: [Task 1/8] Unit tests: 45/45 passing ✓
[10:46] PLANNER: [Task 1/8] Implementing authentication
[11:00] PLANNER: [Task 1/8] Implementation complete
[11:01] PLANNER: [Task 1/8] Writing integration tests
[11:15] PLANNER: [Task 1/8] Integration tests: 12/12 passing ✓
[11:16] PLANNER: [Task 1/8] Writing contract tests
[11:25] PLANNER: [Task 1/8] Contract tests: 8/8 passing ✓
[11:26] PLANNER: [Task 1/8] Writing e2e tests
[11:40] PLANNER: [Task 1/8] E2E tests: 5/5 passing ✓
[11:41] PLANNER: [Task 1/8] All tests passing, requesting verification
[11:44] REVIEWER: [Task 1/8] Starting verification...
[11:45] REVIEWER: [Task 1/8] Checking for TODOs... NONE ✓
[11:46] REVIEWER: [Task 1/8] Checking tests... ALL PASSING ✓
[11:47] REVIEWER: [Task 1/8] Code coverage: 87% ✓
[11:48] REVIEWER: [Task 1/8] Linter: clean ✓
[11:49] REVIEWER: [Task 1/8] ✓ VERIFIED - Moving to next task
[11:50] PLANNER: [Task 2/8] Starting rate limiting middleware
```

---

## 🛡️ PHASE 5: What Strict Mode Enforces

### Planner Agent Requirements

**1. Task List Tracking**
- Reads tasks.md at startup
- Creates coordination/task_status.json
- Works through tasks IN ORDER
- Never skips tasks
- Marks task complete only after reviewer verification

**2. Complete Implementation**
- NO "TODO" comments
- NO placeholder functions
- NO "will implement later"
- Everything fully functional
- All error cases handled
- All edge cases covered

**3. Comprehensive Testing (TDD)**
- Write tests FIRST when possible
- Unit tests for every function
- Integration tests for interactions
- Contract tests for APIs
- E2E tests for critical flows
- ALL tests must pass (100%)
- Code coverage ≥ 80%

**4. Quality Standards**
- No linter errors
- No type errors (if TypeScript)
- No console.log in production code
- Code documented
- Follows project style

### Reviewer Agent Enforcement

**1. Proposal Review**
- Demands complete test strategy in proposals
- Rejects vague or incomplete plans
- Requires unit + integration + contract + e2e tests
- Adds mandatory requirements to approval

**2. Implementation Verification**
```bash
# Reviewer checks:
grep -r "TODO" src/          # REJECTS if found
grep -r "FIXME" src/         # REJECTS if found
# Checks all test types exist  # REJECTS if missing
# Checks all tests pass        # REJECTS if any fail
# Checks code coverage         # REJECTS if < 80%
npm run lint                  # REJECTS if errors
```

**3. Rejection Examples**

When reviewer finds issues:
```
❌ REJECTED - Incomplete implementation

ISSUES:
- auth.js line 45: TODO comment found
- Missing integration tests for /api/logout
- Unit test 'handles invalid JWT' is FAILING
- Code coverage only 65% (need 80%)

REQUIRED ACTIONS:
- Remove TODO and implement fully
- Write integration tests
- Fix failing test
- Increase coverage to 80%

Do not mark complete until ALL issues resolved.
```

**4. Verification**

Only after EVERYTHING passes:
```
✓ VERIFIED - Task 1/8 complete

Verification checklist:
✓ Implementation 100% complete
✓ No TODO/FIXME comments
✓ All unit tests passing (45/45)
✓ All integration tests passing (12/12)
✓ All contract tests passing (8/8)
✓ All e2e tests passing (5/5)
✓ Code coverage: 87%
✓ No linter errors
✓ Well documented

Moving to Task 2/8
```

---

## 🎛️ PHASE 6: Intervention & Control

### When to Intervene

**Good reasons:**
1. Adding requirements: "Also add 2FA support"
2. Clarifying requirements: "The rate limit should be per user, not per IP"
3. Providing context: "Use our existing sendEmail() function in utils/"
4. Course correction: "Use PostgreSQL, not MongoDB"

### How to Intervene

**Method 1: Direct to Planner**
```bash
Ctrl+b 0  # Switch to planner

# Type your message
"Wait - for password reset, use our existing email template in /templates/reset-password.html"

Enter  # Send message
```

**Method 2: Direct to Reviewer**
```bash
Ctrl+b 1  # Switch to reviewer

# Type your message
"For this task, E2E tests are not required since we'll test this manually"

Enter  # Send message
```

**Method 3: Update tasks.md**
```bash
# In another terminal
nano /path/to/project/tasks.md

# Add details to tasks:
5. Add email verification system
   - Send verification email on registration
   - Use SendGrid API (credentials in .env)
   - Token expires in 24 hours
   - Resend endpoint: POST /api/auth/resend-verification
```

### When NOT to Intervene

**Let them work:**
- Taking time to write tests (that's good!)
- Implementation seems slow (quality takes time)
- Writing multiple test files (comprehensive = good)
- Debugging failed tests (part of the process)

---

## 🔄 PHASE 7: Session Resumption

### Why Resume?

- Long task list (can't finish in one sitting)
- Need to disconnect (close laptop)
- Network interruption
- Want to continue tomorrow

### How to Resume

**Option 1: Continue Last Session**
```bash
# Simple - just continue
~/agent-system/launch-agents-strict.sh --continue /path/to/project
```

**What happens:**
- Loads previous conversation history
- Planner checks task_status.json
- Continues from current task
- Maintains context

**Option 2: Resume Specific Session**
```bash
# Find session IDs
ls ~/.claude/sessions/

# Resume specific one
~/agent-system/launch-agents-strict.sh --resume 550e8400-e29b-41d4 /path/to/project
```

### What Gets Resumed

✅ **Preserved:**
- Conversation history
- Current task context
- Task progress (via task_status.json)
- All coordination files

❌ **NOT preserved:**
- tmux window layout (new session created)
- Terminal scroll history

### Resume Workflow

```bash
# Day 1: Start work
~/agent-system/launch-agents-strict.sh ~/project "Follow tasks.md"

# Complete tasks 1-3
# Detach for the day
Ctrl+b d

# Day 2: Resume
~/agent-system/launch-agents-strict.sh --continue ~/project

# Agents say: "Resuming... Currently on Task 4/8"
# Continue from where you left off
```

---

## 📊 PHASE 8: Monitoring Progress

### Check Current Task

```bash
# View monitor dashboard
Ctrl+b 2

# Shows:
Task 3/8: Add password reset functionality
Status: implementing
Progress:
  Unit tests: 18/18 passing ✓
  Integration tests: 6/6 passing ✓
  Contract tests: writing...
  E2E tests: not started
```

### Check Task History

```bash
# In your project
cat coordination/task_status.json | jq .

# Shows:
{
  "tasks": [
    {
      "id": "task_1",
      "description": "Add user authentication",
      "status": "verified",
      "completed_at": "2024-01-15T11:50:00Z"
    },
    {
      "id": "task_2",
      "description": "Implement rate limiting",
      "status": "verified",
      "completed_at": "2024-01-15T13:30:00Z"
    },
    {
      "id": "task_3",
      "description": "Add password reset",
      "status": "in_progress",
      "started_at": "2024-01-15T14:00:00Z"
    }
  ],
  "current_task_index": 2,
  "completed_tasks": 2,
  "total_tasks": 8
}
```

### Check Live Logs

```bash
# View activity log
Ctrl+b 3

# Or from terminal
tail -f /path/to/project/coordination/logs/notifications.log
```

---

## ✅ PHASE 9: Final Verification

### When All Tasks Complete

```
[TIMESTAMP] REVIEWER: 🎉 ALL TASKS VERIFIED - 8/8 complete

Final Summary:
✓ 8 tasks completed
✓ All implementations verified
✓ All tests passing
✓ High quality code
✓ Ready for production
```

### Your Verification

```bash
# Stop agents
~/agent-system/stop-agents.sh

# Run tests yourself
cd /path/to/project
npm test

# Should see: ALL TESTS PASSING
# Should see: 234 tests passed

# Check coverage
npm run test:coverage
# Should see: ≥80% (probably 85%+)

# Check for any TODOs
grep -r "TODO" src/
# Should see: (nothing)

# Check quality
npm run lint
# Should see: No errors

# Review changes
git diff
# Should see: Complete, clean implementations
```

---

## 🎯 COMPLETE EXAMPLE: Real Project

### Scenario: Building Blog API

**tasks.md:**
```markdown
1. Add user authentication (JWT)
2. Create post CRUD endpoints
3. Add comment system
4. Implement post categories/tags
5. Add image upload for posts
6. Create search functionality
7. Add rate limiting
8. Generate API documentation
```

**Commands:**
```bash
# Day 1: Start
cd ~/blog-api
~/agent-system/launch-agents-strict.sh . "Complete all tasks in tasks.md"

# Watch it work
# Tasks 1-3 complete
# Detach at 5pm
Ctrl+b d

# Day 2: Resume
~/agent-system/launch-agents-strict.sh --continue ~/blog-api

# Continue from Task 4
# Tasks 4-6 complete
# Detach again

# Day 3: Finish
~/agent-system/launch-agents-strict.sh --continue ~/blog-api

# Tasks 7-8 complete
# All done!

# Verify
npm test  # ALL PASSING
git diff  # Review quality
```

---

## 📚 Quick Reference Card

```bash
# SETUP (once)
~/agent-system/setup.sh /path/to/project
cd /path/to/project
nano tasks.md  # Create task list

# START
~/agent-system/launch-agents-strict.sh /path/to/project "Follow tasks.md"

# RESUME
~/agent-system/launch-agents-strict.sh --continue /path/to/project

# MONITOR
Ctrl+b 0  # Planner
Ctrl+b 1  # Reviewer
Ctrl+b 2  # Dashboard
Ctrl+b 3  # Logs

# INTERVENE
Ctrl+b 0  # Switch to planner
[Type message]
Enter

# DETACH
Ctrl+b d

# REATTACH
tmux attach -t agent_system

# STOP
~/agent-system/stop-agents.sh
```

---

## 🎉 You're Ready!

**What you've set up:**
✅ Strict mode with complete implementation enforcement
✅ Comprehensive testing requirements (TDD, unit, integration, contract, e2e)
✅ Task list tracking and sequential completion
✅ Session resumption for long-running work
✅ Reviewer that rejects incomplete work
✅ No shortcuts, no placeholders, production-ready code

**Next steps:**
1. Download the strict mode files
2. Create tasks.md in your project
3. Launch with strict mode
4. Watch your tasks get completed with full test coverage!

Need help? Read **STRICT_MODE_GUIDE.md** for complete details!
