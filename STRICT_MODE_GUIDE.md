# 🎯 STRICT MODE GUIDE - Complete Implementation Enforcement

This guide explains how to use the **STRICT MODE** where agents are required to:
- ✅ Implement EVERYTHING completely (no TODOs, no placeholders)
- ✅ Write ALL tests (unit, integration, contract, e2e)
- ✅ Ensure ALL tests pass (100%)
- ✅ Achieve ≥80% code coverage
- ✅ Follow TDD when possible
- ✅ Get reviewer verification before moving to next task

---

## 🚀 Quick Start - Strict Mode

```bash
# Use the strict mode launcher
./launch-agents-strict.sh /path/to/project "Your task"

# Or work from a task list
./launch-agents-strict.sh /path/to/project "Follow tasks in tasks.md"
```

---

## 📋 PART 1: Creating a Task List (tasks.md)

### Step 1: Create tasks.md in Your Project Root

```bash
# Navigate to your project
cd /path/to/your/project

# Create tasks.md
nano tasks.md
```

### Step 2: Format Your Tasks

**Format: Numbered list with clear descriptions**

```markdown
# Project Tasks

1. Add user authentication with JWT
2. Implement rate limiting middleware  
3. Add password reset functionality
4. Create user profile endpoints (GET, PUT, DELETE)
5. Add email verification system
6. Implement role-based access control (RBAC)
7. Add API request logging
8. Implement database migrations system
9. Add comprehensive error handling
10. Create API documentation with OpenAPI
```

**Each task should be:**
- ✓ Clear and specific
- ✓ Independently completable
- ✓ Measurable (you can verify it's done)
- ✓ Ordered logically (dependencies first)

### Step 3: Launch Agents with Task List

```bash
./launch-agents-strict.sh ~/my-project "Complete all tasks in tasks.md"
```

**What happens:**
1. Planner reads tasks.md
2. Creates coordination/task_status.json to track progress
3. Works through tasks IN ORDER
4. Completes Task 1 fully before moving to Task 2
5. Reviewer verifies each task before allowing next

---

## 🔄 PART 2: Session Resumption

### Why Resume Sessions?

- Continue long-running work
- Pick up after disconnection
- Maintain conversation context
- Don't lose progress

### Option A: Resume Most Recent Session

```bash
# Continue the last session automatically
./launch-agents-strict.sh --continue /path/to/project
```

**When to use:**
- You detached from a session (Ctrl+b d)
- Session was interrupted
- You want to continue where you left off

### Option B: Resume Specific Session

```bash
# First, find session IDs
cd /path/to/project
ls ~/.claude/sessions/

# Resume specific session
./launch-agents-strict.sh --resume SESSION_ID /path/to/project
```

**Session ID format:** `550e8400-e29b-41d4-a716-446655440000`

### What Gets Resumed?

✅ Conversation history
✅ Current task context
✅ Task progress (reads task_status.json)
✅ Coordination state

❌ NOT resumed: Window layout (new tmux session created)

---

## 🎯 PART 3: How Strict Mode Works

### Planner Agent (Strict Mode)

**Phase 1: Read Task List**
```
[10:00] Reading tasks.md
[10:01] Found 10 tasks
[10:02] Creating task_status.json
[10:03] Starting Task 1/10: Add user authentication
```

**Phase 2: Create Proposals**
```
[10:05] Analyzing task requirements
[10:10] Created 3 detailed approaches
[10:11] Each approach includes full test strategy
[10:12] Waiting for reviewer approval
```

**Phase 3: Implementation (TDD)**
```
[10:30] Reviewer approved JWT approach
[10:31] Writing unit tests FIRST (TDD)
[10:45] Unit tests complete: 45 tests
[10:46] Running tests... ALL PASSING ✓
[10:47] Implementing authentication logic
[11:00] Implementation complete
[11:01] Writing integration tests
[11:15] Integration tests: 12 tests ALL PASSING ✓
[11:16] Writing contract tests
[11:25] Contract tests: 8 tests ALL PASSING ✓
[11:26] Writing e2e tests
[11:40] E2E tests: 5 tests ALL PASSING ✓
```

**Phase 4: Verification Request**
```
[11:41] All tests passing
[11:42] Code coverage: 87%
[11:43] No linter errors
[11:44] Requesting reviewer verification
```

**Phase 5: Next Task or Revision**
```
If VERIFIED:
[11:50] ✓ Task 1/10 verified by reviewer
[11:51] Moving to Task 2/10

If REJECTED:
[11:50] ❌ Rejected - Missing integration tests
[11:51] Reading feedback
[11:52] Fixing issues...
```

### Reviewer Agent (Strict Mode)

**Monitoring Loop**
```
Every 30 seconds:
- Check task_proposals.json for new work
- Check for implementations awaiting verification
```

**When New Proposal**
```
[10:12] New proposals received for Task 1/10
[10:13] Evaluating 3 approaches
[10:15] Checking test strategies
[10:17] JWT approach selected
[10:18] Adding strict requirements:
        - All tests must pass (unit, integration, contract, e2e)
        - No TODO comments
        - Code coverage ≥ 80%
        - No placeholders
[10:20] Approval sent to planner
```

**When Implementation Complete**
```
[11:44] Implementation ready for verification
[11:45] Checking code...
[11:46] Searching for TODOs... NONE FOUND ✓
[11:47] Checking test results...
        Unit: 45/45 passing ✓
        Integration: 12/12 passing ✓
        Contract: 8/8 passing ✓
        E2E: 5/5 passing ✓
[11:48] Code coverage: 87% ✓
[11:49] Linter: clean ✓
[11:50] ✓ VERIFIED - Task 1/10 complete
```

**If Issues Found**
```
[11:45] Verification started
[11:46] ❌ FOUND ISSUES:
        - TODO comment in auth.js line 45
        - Integration test failing: "handles timeout"
        - Code coverage only 65%
[11:47] ❌ REJECTED - Fix all issues
[11:48] Detailed feedback sent to planner
```

---

## 📊 PART 4: Monitoring Progress

### Window 0: Planner Agent

**What you see:**
- Current task being worked on
- Test writing progress
- Implementation details
- Test results

**When to check:**
- See what's being implemented
- Verify tests are being written
- Intervene if needed

### Window 1: Reviewer Agent

**What you see:**
- Proposal evaluations
- Verification checks
- Approval/rejection decisions
- Feedback to planner

**When to check:**
- See why something was rejected
- Understand quality requirements
- Verify reviewer is active

### Window 2: Monitor Dashboard

**What you see:**
```
📋 TASK PROPOSALS
  Status: approved
  Task: Task 3/10 - Add password reset
  Proposals: 3
  Chosen: approach_2

🔧 ACTIVE WORK
  🤖 planner_agent_123:
     Role: planner
     Status: implementing
     Working on: approach_2
     Progress:
       Implementation complete: true
       Unit tests: 28/28 passing ✓
       Integration tests: 8/8 passing ✓
       Contract tests: 5/5 passing ✓
       E2E tests: 3/3 passing ✓

✨ COMPLETED WORK
  ✅ Total completed: 2
  ✓ Task 1: User authentication - VERIFIED
  ✓ Task 2: Rate limiting - VERIFIED
```

### Window 3: Activity Logs

**What you see:**
```
[10:00:00Z] PLANNER: [Task 1/10] Started - Add user authentication
[10:05:00Z] PLANNER: [Task 1/10] Created 3 proposals
[10:12:00Z] REVIEWER: [Task 1/10] Received proposals for review
[10:20:00Z] REVIEWER: [Task 1/10] Approved JWT approach
[10:30:00Z] PLANNER: [Task 1/10] Starting implementation
[10:45:00Z] PLANNER: [Task 1/10] Unit tests - 45/45 passing ✓
[11:15:00Z] PLANNER: [Task 1/10] Integration tests - 12/12 passing ✓
[11:25:00Z] PLANNER: [Task 1/10] Contract tests - 8/8 passing ✓
[11:40:00Z] PLANNER: [Task 1/10] E2E tests - 5/5 passing ✓
[11:44:00Z] PLANNER: [Task 1/10] Requesting verification
[11:50:00Z] REVIEWER: [Task 1/10] ✓ VERIFIED - Moving to next task
[11:51:00Z] PLANNER: [Task 2/10] Started - Implement rate limiting
```

---

## 🛠️ PART 5: Intervention Strategies

### When to Intervene

**Good reasons to intervene:**
1. Agent is going down wrong path
2. You have additional requirements
3. You want to add context
4. Testing approach needs adjustment
5. Implementation details need clarification

**Bad reasons (let them work):**
1. They're taking too long (be patient)
2. You want to micromanage
3. They're writing tests (that's required!)
4. You want to skip a task (don't!)

### How to Intervene

**Method 1: Direct Message**
```bash
# Switch to planner
Ctrl+b 0

# Type your message
"Wait - use Redis for rate limiting, not in-memory. Our production uses Redis."

# Press Enter
```

**Method 2: Update Task List**
```bash
# Edit tasks.md while agents are running
nano /path/to/project/tasks.md

# Add details to a task:
3. Add password reset functionality
   - Must support email verification
   - Token expires in 1 hour
   - Send email via SendGrid API
```

**Method 3: Add Context via Message**
```bash
Ctrl+b 0

"Important context: Our API uses Express.js, PostgreSQL with Prisma, and Jest for testing. Follow existing patterns in /src/api folder."
```

---

## ⚙️ PART 6: Configuration & Customization

### Customize Test Requirements

Edit `prompts/reviewer_agent_strict.txt` around line 150:

```txt
"testing": {
  "unit_tests": {
    "required": true,
    "minimum_coverage": 85,  # Changed from 80
    "requirements": [
      "Test every function/method",
      "Test happy path",
      "Test error cases",
      "Test edge cases",
      "All tests must PASS"
    ]
  },
  "e2e_tests": {
    "required": true,  # Set to false if you don't need e2e
    ...
  }
}
```

### Adjust Monitoring Frequency

Edit both prompt files, change:
```txt
Every 30 seconds, check coordination/task_proposals.json
```

To:
```txt
Every 15 seconds, check coordination/task_proposals.json  # Faster
```

### Add Project-Specific Requirements

Edit `prompts/reviewer_agent_strict.txt` around line 300:

```txt
PROJECT SPECIFIC REQUIREMENTS:
- Must use TypeScript strict mode
- Must follow Airbnb style guide
- Must use Prisma for database
- Must use Jest for testing
- API responses must match OpenAPI spec in /docs
```

---

## 🎯 PART 7: Complete Example Workflow

### Example: E-commerce API Project

**Step 1: Create tasks.md**
```markdown
# E-commerce API Tasks

1. Add user authentication (JWT)
2. Implement product CRUD endpoints
3. Add shopping cart functionality
4. Implement order processing
5. Add payment integration (Stripe)
6. Implement email notifications
7. Add admin dashboard API
8. Create comprehensive API documentation
```

**Step 2: Launch in Strict Mode**
```bash
cd ~/ecommerce-api
~/agent-system/launch-agents-strict.sh . "Complete all tasks in tasks.md"
```

**Step 3: Monitor Progress**
```
[Watch Window 2 - Monitor]

Task 1/8: User Authentication
└─ Status: implementing
└─ Tests: 34/34 passing ✓
└─ Coverage: 89%

[10 minutes later]

Task 1/8: User Authentication  
└─ Status: verified ✓
Task 2/8: Product CRUD
└─ Status: planning
```

**Step 4: Intervene if Needed**
```bash
# Switch to planner
Ctrl+b 0

# Add requirement
"For the payment integration task, use Stripe Test Mode with test API keys. Store keys in .env file, never commit them."
```

**Step 5: Let Them Work**
```
# Detach and do other work
Ctrl+b d

# Come back later
tmux attach -t agent_system

# Check progress
Ctrl+b 2  # Monitor dashboard

# See they're on Task 5/8
```

**Step 6: Resume After Interruption**
```bash
# Next day, resume the session
~/agent-system/launch-agents-strict.sh --continue ~/ecommerce-api
```

**Step 7: Review Results**
```bash
# After all tasks complete
cd ~/ecommerce-api
git status  # See all changes
git diff    # Review implementations
npm test    # Verify all tests pass (they will!)
```

---

## 📝 PART 8: Task List Best Practices

### Good Task Descriptions

✅ **Clear and Specific**
```markdown
1. Add user authentication with JWT tokens
   - Login endpoint: POST /api/auth/login
   - Register endpoint: POST /api/auth/register
   - Token expiration: 24 hours
   - Refresh token support
```

✅ **Testable**
```markdown
2. Implement rate limiting
   - Limit: 100 requests per 15 minutes per IP
   - Return 429 status when exceeded
   - Include Retry-After header
```

✅ **Complete Requirements**
```markdown
3. Add email verification
   - Send verification email on registration
   - Verification link expires in 24 hours
   - Resend verification email endpoint
   - Update user status when verified
```

### Bad Task Descriptions

❌ **Too Vague**
```markdown
1. Make the API better
2. Fix bugs
3. Improve performance
```

❌ **Too Large**
```markdown
1. Build entire user management system with authentication, profiles, permissions, notifications, and analytics
```

❌ **No Acceptance Criteria**
```markdown
1. Add authentication (no details about how, what, or expected behavior)
```

### Task Size Guidelines

**Good task size: 2-4 hours of work**

- Small enough to complete in one sitting
- Large enough to be meaningful
- Can be fully tested
- Has clear completion criteria

**If task is too large, split it:**
```markdown
Instead of:
❌ 1. Build complete user management system

Do this:
✅ 1. Add user authentication
✅ 2. Add user profile endpoints
✅ 3. Add user permissions
✅ 4. Add user notifications
```

---

## 🔍 PART 9: Verification & Quality Checks

### What Reviewer Checks

**1. Implementation Completeness**
```bash
# Searches for:
grep -r "TODO" src/     # Should find NONE
grep -r "FIXME" src/    # Should find NONE
grep -r "console.log" src/  # Should find NONE in production code
```

**2. Test Coverage**
```bash
# Checks:
- Unit tests exist for all modules
- Integration tests exist for all endpoints
- Contract tests exist for API contracts
- E2E tests exist for critical flows
- ALL tests passing
- Coverage ≥ 80%
```

**3. Code Quality**
```bash
# Verifies:
npm run lint   # No errors
npm run type-check  # No type errors (if TypeScript)
npm test      # 100% passing
```

### Task Status Progression

```
not_started
    ↓
[Planner starts working]
    ↓
in_progress
    ↓
[Planner completes implementation]
    ↓
completed
    ↓
[Reviewer verifies]
    ↓
verified ✓
    OR
    ↓
[If issues found]
    ↓
needs_revision
    ↓
in_progress
[Loop until verified]
```

---

## 🚨 PART 10: Troubleshooting

### Issue: Agents Not Moving Forward

**Check:**
```bash
# View logs
tail -f /path/to/project/coordination/logs/notifications.log

# Check status
cat /path/to/project/coordination/task_proposals.json | jq .status

# Check task progress
cat /path/to/project/coordination/task_status.json | jq .
```

**Common causes:**
- Reviewer rejected work (check logs)
- Waiting for verification (be patient, checking every 30s)
- Tests failing (planner debugging)

### Issue: Tests Keep Failing

**Intervene:**
```bash
Ctrl+b 0
"The test 'handles null user' is failing. The issue is line 45 in auth.js - we need to check for null before accessing user.email"
```

### Issue: Task Seems Stuck

**Check progress:**
```bash
Ctrl+b 3  # View logs

# Should see updates every 5-10 minutes
# If no updates for 30+ minutes, intervene
```

**Intervene:**
```bash
Ctrl+b 0
"What's your current progress? Where are you stuck?"
```

### Issue: Want to Skip a Task

**DON'T!** Strict mode doesn't allow skipping.

**Instead:**
1. Stop agents: `./stop-agents.sh`
2. Edit tasks.md: Comment out or remove the task
3. Relaunch: `./launch-agents-strict.sh --continue ~/project`

---

## 🎉 PART 11: Success Indicators

### You Know It's Working When

✅ Planner completes tasks sequentially
✅ All tests are being written first (TDD)
✅ Test counts increasing in logs
✅ Reviewer rejecting incomplete work
✅ Tasks marked "verified" one by one
✅ No TODO comments in final code
✅ All tests passing
✅ Code coverage ≥ 80%

### Final Verification

After all tasks complete:

```bash
# Run full test suite
npm test
# Should see: ALL TESTS PASSING

# Check coverage
npm run test:coverage
# Should see: ≥80%

# Check for TODOs
grep -r "TODO" src/
# Should see: (nothing)

# Check linter
npm run lint
# Should see: No errors

# Review the code
git diff
# Should see: Complete, clean implementations
```

---

## 📚 Quick Reference

```bash
# New project with task list
./launch-agents-strict.sh ~/project "Follow tasks.md"

# Resume last session
./launch-agents-strict.sh --continue ~/project

# Resume specific session
./launch-agents-strict.sh --resume SESSION_ID ~/project

# Stop agents
./stop-agents.sh

# View progress
tmux attach -t agent_system
Ctrl+b 2  # Monitor
Ctrl+b 3  # Logs
```

---

**Remember:** Strict mode = Zero shortcuts, Complete testing, Full verification!
