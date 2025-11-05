# Slash Command Orchestration - The Best Approach

## TL;DR

**Use `/orchestrate [task]` instead of `@orchestrator`**

This makes **main Claude** the orchestrator, using Task tool to spawn sub-agents. It actually works and enforces completion through iteration!

## The Breakthrough Insight

### ❌ What Doesn't Work Well
```
@orchestrator (sub-agent trying to spawn other sub-agents)
  └─ Unclear if agents can spawn agents
  └─ Nested delegation complexity
  └─ Limited context
```

### ✅ What Works Perfectly
```
/orchestrate (slash command making main Claude the orchestrator)
  └─ Main Claude uses Task tool (designed for this!)
  └─ Single-level delegation
  └─ Full conversation context
  └─ Natural iteration
```

## How It Works

### Step 1: User Invokes

```
/orchestrate Task: Implement JWT authentication for the REST API

Requirements:
- Token generation on login
- Token validation middleware
- Refresh token mechanism
- Rate limiting
- Tests
```

### Step 2: Main Claude Becomes Orchestrator

The slash command loads orchestration instructions into main Claude:
- How to use Task tool to spawn agents
- How to process their responses
- When to iterate
- When to stop (BAZINGA signal)

### Step 3: Main Claude Spawns Developer

```
Main Claude uses Task tool:

Task(
  subagent_type: "general-purpose"
  description: "Developer implementing JWT auth"
  prompt: "You are DEVELOPER agent. [instructions] + [task]"
)
```

**Developer agent:**
- Runs in separate context
- Uses Read/Write/Edit/Bash tools
- Implements the feature
- Returns structured report to main Claude

### Step 4: Main Claude Receives Results

```
═══════════════════════════════════════════
Developer Implementation Complete
═══════════════════════════════════════════

Summary: Implemented JWT authentication system

Files Modified:
- src/auth/jwt_handler.py (created)
- src/middleware/auth.py (created)
- tests/test_jwt.py (created)

Tests: 12 passing

Status: READY_FOR_REVIEW

Sending to tech lead...
```

Main Claude **sees this in the conversation** and extracts info.

### Step 5: Main Claude Spawns Tech Lead

```
Main Claude uses Task tool again:

Task(
  subagent_type: "general-purpose"
  description: "Tech lead reviewing JWT auth"
  prompt: "You are TECH LEAD. Review this work:

[Pastes developer's full report]

Provide feedback..."
)
```

**Tech lead agent:**
- Uses Read tool to actually review code
- Evaluates quality
- Returns review with APPROVED or CHANGES_REQUESTED

### Step 6: Main Claude Receives Review

```
═══════════════════════════════════════════
Tech Lead Review: CHANGES REQUESTED
═══════════════════════════════════════════

Issues Found:

1. [CRITICAL] SQL Injection (line 45)
   Fix: Use parameterized queries

2. [HIGH] Missing rate limiting
   Fix: Add @limiter decorator

Sending feedback to developer...
```

Main Claude **sees tech lead's response** and decides: need to iterate!

### Step 7: Main Claude Spawns Developer Again

```
Main Claude uses Task tool:

Task(
  subagent_type: "general-purpose"
  description: "Developer addressing feedback"
  prompt: "You are DEVELOPER.

Tech lead found issues:
[Pastes tech lead's feedback]

Fix these and resubmit."
)
```

### Step 8: Loop Until BAZINGA

```
Developer fixes → Main Claude receives → Spawns tech lead
Tech lead re-reviews → Main Claude receives

If response contains "BAZINGA":
  ✅ Task complete!
  Stop orchestrating.

If response contains "CHANGES_REQUESTED":
  🔄 Spawn developer again with feedback
  Continue loop.
```

## Example Complete Session

```
═══════════════════════════════════════════════════════════════
YOU: /orchestrate Task: Implement user registration endpoint
═══════════════════════════════════════════════════════════════

MAIN CLAUDE:
Starting orchestration for user registration...

Spawning developer agent...

[Task tool spawns developer]

───────────────────────────────────────────────────────────────
Developer Agent Response:
───────────────────────────────────────────────────────────────

## Implementation Complete

**Summary:** Implemented user registration with validation

**Files Modified:**
- src/api/auth.py (created)
- src/validators.py (created)
- tests/test_registration.py (created)

**Key Changes:**
- POST /api/register endpoint
- Email format validation
- Password strength check
- Duplicate email prevention
- JWT token generation

**Tests:**
- Total: 8
- Passing: 8
- Failing: 0

**Status:** READY_FOR_REVIEW

───────────────────────────────────────────────────────────────

MAIN CLAUDE:
Developer completed implementation.
Files: auth.py, validators.py, test_registration.py
Tests: 8/8 passing

Spawning tech lead for review...

[Task tool spawns tech lead]

───────────────────────────────────────────────────────────────
Tech Lead Agent Response:
───────────────────────────────────────────────────────────────

## Review: CHANGES REQUESTED

**Issues Found:**

### 1. [CRITICAL] Password Not Hashed
**Location:** src/api/auth.py:25
**Problem:** Password stored in plain text

**Fix:**
```python
from werkzeug.security import generate_password_hash
hashed = generate_password_hash(password, method='pbkdf2:sha256')
```

### 2. [HIGH] Missing Rate Limiting
**Location:** src/api/auth.py:15
**Fix:** Add @limiter.limit("5 per hour") decorator

**Next Steps:**
1. Fix password hashing
2. Add rate limiting
3. Resubmit for review

───────────────────────────────────────────────────────────────

MAIN CLAUDE:
Tech lead found critical issues:
- Password not hashed
- Missing rate limiting

Sending feedback to developer...

[Task tool spawns developer with feedback]

───────────────────────────────────────────────────────────────
Developer Agent Response:
───────────────────────────────────────────────────────────────

## Feedback Addressed

**Issue 1:** Password not hashed
- **Fixed:** ✅ Using generate_password_hash with pbkdf2:sha256

**Issue 2:** Missing rate limiting
- **Fixed:** ✅ Added @limiter.limit("5 per hour") decorator

**All tests passing:** 10/10 (added 2 new tests)

**Status:** READY_FOR_REVIEW

───────────────────────────────────────────────────────────────

MAIN CLAUDE:
Developer addressed all feedback.
Tests: 10/10 passing

Spawning tech lead for re-review...

[Task tool spawns tech lead]

───────────────────────────────────────────────────────────────
Tech Lead Agent Response:
───────────────────────────────────────────────────────────────

## Review: APPROVED

**What Was Done Well:**
- Password hashing correctly implemented
- Rate limiting properly configured
- All security issues resolved
- Good test coverage

**Code Quality:** Excellent. Production-ready.

**Ready for Production:** YES ✅

**BAZINGA**

───────────────────────────────────────────────────────────────

MAIN CLAUDE:
═══════════════════════════════════════════════════════════════
✅ USER REGISTRATION COMPLETE!
═══════════════════════════════════════════════════════════════

BAZINGA detected - tech lead approved!

**Summary:**
- Implementation iterations: 2
- Issues found: 2 (1 critical, 1 high)
- All issues resolved
- Final tests: 10/10 passing
- Status: Production-ready

**Files:**
- src/api/auth.py
- src/validators.py
- tests/test_registration.py

Task complete! 🎉
```

## Why This Works

### 1. Main Claude Has Full Context
```
Iteration 1: Developer implements
  └─ Main Claude sees: "8 tests passing"

Iteration 2: Tech lead reviews
  └─ Main Claude sees: "Password not hashed"

Iteration 3: Developer fixes
  └─ Main Claude sees: "Fixed with pbkdf2"

Iteration 4: Tech lead approves
  └─ Main Claude sees: "BAZINGA"

Main Claude has EVERYTHING in conversation history!
```

### 2. Task Tool Used Correctly
```
Task tool is designed for:
✅ Main Claude spawning sub-agents
✅ Sub-agents returning results to caller
✅ Caller (main Claude) making decisions

NOT designed for:
❌ Agents spawning other agents (unclear support)
```

### 3. Natural Iteration
```
Main Claude:
  while not bazinga_received:
    if developer_done:
      spawn_techlead()
    if changes_requested:
      spawn_developer_with_feedback()
    if approved:
      break

This is natural conversation flow!
```

### 4. Clear Completion Signal
```
Tech Lead ends response with: "BAZINGA"

Main Claude checks:
  if "BAZINGA" in response:
    stop_orchestrating()
    report_completion()

Unambiguous!
```

### 5. User Visibility
```
User sees:
- When developer is spawned
- Developer's full report
- When tech lead is spawned
- Tech lead's full review
- When iterations happen
- When BAZINGA detected

Complete transparency!
```

## Advantages Over Other Approaches

| Feature | /orchestrate | @orchestrator | Scripts |
|---------|--------------|---------------|---------|
| **Main Claude in control** | ✅ Yes | ❌ No (sub-agent) | ❌ No (script) |
| **Full context** | ✅ Conversation history | ❌ Limited | ❌ State files |
| **Natural iteration** | ✅ Yes | ❌ Unclear | ✅ Yes (loop) |
| **User visibility** | ✅ All outputs visible | ⚠️ Hidden in agent | ⚠️ Tmux windows |
| **Easy to use** | ✅ `/orchestrate` | ✅ `@orchestrator` | ❌ `./launch-*.sh` |
| **Can iterate** | ✅ Unlimited | ❌ Runs once | ✅ Up to MAX |
| **Completion signal** | ✅ BAZINGA | ❌ None | ✅ State file |
| **Setup complexity** | ✅ None | ✅ None | ❌ Tmux, scripts |

## Usage

### Simple Task

```
/orchestrate Task: Create a calculator API with add, subtract, multiply, divide operations. Include tests.

Project: /tmp/calculator
```

### Complex Task with Requirements

```
/orchestrate Task: Implement JWT authentication

Requirements:
- Token generation using HS256
- Token validation middleware
- Refresh token mechanism with rotation
- Rate limiting (10 requests/min)
- Password hashing with bcrypt
- Comprehensive tests for all scenarios

Project: /path/to/api-project

Success criteria: All tests passing, tech lead approval, production-ready code
```

### Multiple Tasks

```
/orchestrate

I need these features implemented:

1. User Registration
   - Email validation
   - Password hashing
   - JWT token return

2. User Login
   - Email/password auth
   - Token generation
   - Rate limiting

3. Password Reset
   - Reset token generation
   - Email sending (mock for now)
   - Token validation

Project: /path/to/project

Work through each task systematically with developer/tech lead review cycles.
```

## Handling Edge Cases

### Developer Gets Blocked

Main Claude will:
1. See developer's BLOCKED status
2. Spawn tech lead with unblocking request
3. Tech lead provides specific solutions
4. Main Claude spawns developer with solutions
5. Developer continues

### Infinite Loop

Main Claude tracks iterations:
```
if iteration_count > 20:
  display: "⚠️ Exceeded 20 iterations"
  ask_user: "Continue or stop?"
```

### Tech Lead Never Approves

After multiple rejections:
```
if rejection_count > 5:
  display: "Tech lead rejected 5 times. Task may need clearer requirements."
  ask_user: "Want to revise requirements or continue?"
```

## Customization

### Stricter Reviews

Edit `.claude/commands/orchestrate.md`:
```markdown
### Step 4: Spawn Tech Lead Agent

Add to tech lead prompt:

"STRICT REQUIREMENTS:
- Zero TODOs allowed
- 100% test coverage required
- All critical paths tested
- Security scan must pass

Only approve if ALL requirements met."
```

### Faster Iterations

```markdown
"After tech lead feedback:
- If only LOW priority issues: Auto-approve
- If HIGH/CRITICAL: Send to developer
- BAZINGA when no HIGH/CRITICAL issues remain"
```

### Add Verification Step

```markdown
"After tech lead approval:
1. Spawn verification agent
2. Run all tests
3. Check for TODOs
4. Only then emit BAZINGA"
```

## Troubleshooting

### "BAZINGA not detected"

Tech lead must explicitly include "BAZINGA" in response:
```
Add to tech lead prompt:
"When approving, end your response with BAZINGA on a new line."
```

### "Loop doesn't continue"

Main Claude should see in orchestrate.md:
```
"Keep spawning agents until BAZINGA received.
Don't stop after one iteration."
```

### "Agent outputs truncated"

If responses are very long:
```
"Ask agents to be concise.
Developer: Summary only, not full code dump.
Tech Lead: List issues, don't repeat full code."
```

## Best Practices

### 1. Clear Task Description
```
❌ /orchestrate Implement auth

✅ /orchestrate Task: Implement JWT authentication with:
   - Token generation (HS256)
   - Validation middleware
   - Refresh mechanism
   - Rate limiting (10/min)
   - Full test coverage
```

### 2. Specify Project Path
```
✅ Project: /path/to/project

Helps agents find and modify the right files.
```

### 3. Set Success Criteria
```
✅ Success criteria:
   - All tests passing
   - No security vulnerabilities
   - Tech lead approval
   - Production-ready
```

### 4. Watch for BAZINGA
```
Main Claude should explicitly check:
"Tech lead response contains BAZINGA → stop orchestrating"
```

### 5. Display Progress
```
After each agent response:
"Developer completed X"
"Tech lead found Y issues"
"Iteration Z starting..."

Keeps user informed!
```

## Comparison with Script-Based V2

| Aspect | /orchestrate (Slash) | V2 (Scripts) |
|--------|---------------------|--------------|
| **When to use** | Interactive dev, <50 tasks | Automation, 100+ tasks |
| **Enforcement** | Main Claude iterates | External loop forces |
| **Visibility** | All in conversation | Tmux windows |
| **Setup** | None | Tmux + scripts |
| **Verification** | Main Claude checks | Script verifies |
| **Completion** | BAZINGA signal | State file check |
| **Can stop early** | Main Claude decides | Script enforces MAX |

**Recommendation:**
- **Interactive work**: Use `/orchestrate` - simpler, more natural
- **Large automation**: Use V2 scripts - more robust, forced iteration

## Conclusion

The `/orchestrate` slash command approach is the **sweet spot**:

✅ Simple (just a slash command)
✅ Natural (main Claude orchestrates)
✅ Powerful (full context, smart decisions)
✅ Iterative (loops until complete)
✅ Visible (all agent outputs shown)
✅ Works with Claude Code's design (Task tool)

It combines the best of:
- Native Claude Code features
- Intelligent coordination
- Iterative code review
- Clear completion signal

**Try it now:**
```
/orchestrate Task: [your task description]
```

Watch main Claude spawn agents, coordinate their work, and iterate until tech lead approves with BAZINGA! 🎉
