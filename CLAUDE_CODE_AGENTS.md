# Claude Code Custom Agents Guide

This project includes **three custom Claude Code agents** that work together to implement features with built-in code review.

## The Agents

Located in `.claude/agents/`:

1. **🔨 Developer** (`developer.md`) - Implementation specialist
2. **👔 Tech Lead** (`techlead.md`) - Review and guidance specialist
3. **🎭 Orchestrator** (`orchestrator.md`) - Coordinates the two agents

## How It Works

```
You → @orchestrator [task]
        ↓
    @developer (implements)
        ↓
    @techlead (reviews)
        ↓
    Decision:
    - Approved? ✅ Done!
    - Changes needed? → @developer (revise) → @techlead (re-review)
```

The orchestrator handles all the back-and-forth automatically!

## Quick Start

### Step 1: Copy Agent Files

The agents are already defined in `.claude/agents/`. Make sure this directory is in your project root.

```bash
# Check agents are present
ls .claude/agents/
# Should show: developer.md  orchestrator.md  techlead.md
```

### Step 2: Invoke the Orchestrator

In Claude Code, simply use:

```
@orchestrator

Task: Implement JWT authentication for the REST API

Requirements:
- Token generation on login
- Token validation middleware
- Refresh token mechanism
- Rate limiting on auth endpoints
- Comprehensive tests

Project: /path/to/your/project

Please coordinate developer and tech lead to implement this.
```

### Step 3: Watch the Magic!

The orchestrator will:
1. Call `@developer` with the task
2. Developer implements and reports results
3. Call `@techlead` with developer's work
4. Tech lead reviews and provides feedback
5. If changes needed: Call `@developer` again with feedback
6. Repeat until tech lead approves
7. Report completion to you

## Using Individual Agents

You can also use agents directly:

### Developer Agent

Use when you just want implementation without review:

```
@developer

Implement a simple calculator API:
- POST /calculate endpoint
- Operations: add, subtract, multiply, divide
- Input validation
- Error handling
- Tests

Project: /tmp/calculator

Please implement and test.
```

### Tech Lead Agent

Use when you want to review existing code:

```
@techlead

Please review my JWT authentication implementation:

Files to review:
- src/auth/jwt_handler.py
- src/middleware/auth.py
- tests/test_jwt_auth.py

Project: /path/to/project

Check for security issues, test coverage, and code quality.
```

### Orchestrator Agent (Recommended!)

Use for complete feature development with review:

```
@orchestrator

[Your task description]
```

## Example Session

Here's what a real orchestration looks like:

```
═══════════════════════════════════════════
YOU: @orchestrator

Task: Implement user registration endpoint

Requirements:
- POST /api/register
- Email validation
- Password strength check
- Duplicate email check
- Return JWT token on success
- Tests

Project: /home/user/api-project
═══════════════════════════════════════════

ORCHESTRATOR:
Starting orchestration for user registration...

Invoking developer agent...

═══════════════════════════════════════════
@developer

Implement user registration endpoint.

Requirements:
- POST /api/register endpoint
- Email validation (proper format)
- Password strength (min 8 chars, must have number and special char)
- Check for duplicate emails
- Return JWT token on success
- Comprehensive tests

Project: /home/user/api-project

Please implement, test, and report results.
═══════════════════════════════════════════

DEVELOPER:
## Implementation Complete

**Summary:** Implemented user registration endpoint with validation

**Files Modified:**
- src/api/auth.py (created - registration endpoint)
- src/validators.py (created - email and password validation)
- src/models/user.py (modified - added registration method)
- tests/test_registration.py (created - 8 tests)

**Key Changes:**
- POST /api/register endpoint with input validation
- Email format validation using regex
- Password strength check (min 8 chars, requires number and special char)
- Duplicate email check before user creation
- Returns JWT token on successful registration

**Code Snippet:**
```python
@app.route('/api/register', methods=['POST'])
def register():
    data = request.get_json()

    if not validate_email(data['email']):
        return {'error': 'Invalid email'}, 400

    if not validate_password_strength(data['password']):
        return {'error': 'Password too weak'}, 400

    if User.query.filter_by(email=data['email']).first():
        return {'error': 'Email already registered'}, 409

    user = User.create(email=data['email'], password=data['password'])
    token = generate_jwt(user.id)

    return {'token': token}, 201
```

**Tests:**
- Total: 8
- Passing: 8
- Failing: 0

Test coverage:
- Valid registration
- Invalid email format
- Weak password
- Duplicate email
- Missing fields
- SQL injection attempt
- XSS attempt
- Token generation

**Status:** READY_FOR_REVIEW

═══════════════════════════════════════════

ORCHESTRATOR:
Developer completed implementation:
- Created registration endpoint
- Added validation
- 8/8 tests passing

Invoking tech lead for review...

═══════════════════════════════════════════
@techlead

Review Request:

**Original Task:** User registration endpoint

**Developer's Implementation:**
[Passes full developer report]

**Files to Review:**
- src/api/auth.py
- src/validators.py
- src/models/user.py
- tests/test_registration.py

**Project:** /home/user/api-project

Please review for quality, security, and completeness.
═══════════════════════════════════════════

TECH LEAD:
## Review: CHANGES REQUESTED

**Issues Found:**

### 1. [CRITICAL] Password Storage Not Hashed
**Location:** src/models/user.py:15
**Problem:** Password is stored in plain text

**Current code:**
```python
def create(cls, email, password):
    user = cls(email=email, password=password)
    db.session.add(user)
    db.session.commit()
    return user
```

**Should be:**
```python
from werkzeug.security import generate_password_hash

def create(cls, email, password):
    hashed = generate_password_hash(password, method='pbkdf2:sha256')
    user = cls(email=email, password=hashed)
    db.session.add(user)
    db.session.commit()
    return user
```

**Why:** Storing passwords in plain text is a critical security vulnerability

### 2. [HIGH] Missing Rate Limiting
**Location:** src/api/auth.py:10
**Problem:** No rate limiting on registration endpoint

**Should add:**
```python
from flask_limiter import Limiter

@limiter.limit("5 per hour")
@app.route('/api/register', methods=['POST'])
```

**Why:** Prevents spam account creation and DoS attacks

**What Was Done Well:**
- Good input validation
- Proper error codes
- Comprehensive test coverage
- Good handling of edge cases

**Next Steps:**
1. Fix password hashing (CRITICAL!)
2. Add rate limiting
3. Resubmit for review

**Overall:** Great structure and testing! Just fix these security issues.

═══════════════════════════════════════════

ORCHESTRATOR:
Tech lead found issues:
- Critical: Password not hashed
- High: Missing rate limiting

Sending feedback to developer...

═══════════════════════════════════════════
@developer

Tech lead review feedback:

**Decision:** CHANGES REQUESTED

**Issues to Address:**

1. [CRITICAL] Password Not Hashed
   - Location: src/models/user.py:15
   - Problem: Storing plain text passwords
   - Fix: Use generate_password_hash from werkzeug.security
   - Code provided above

2. [HIGH] Missing Rate Limiting
   - Location: src/api/auth.py:10
   - Problem: No rate limiting on registration
   - Fix: Add @limiter.limit("5 per hour") decorator

**What Was Done Well:**
- Good validation
- Comprehensive tests
- Edge case handling

Please fix these issues and resubmit for review.
═══════════════════════════════════════════

DEVELOPER:
## Feedback Addressed

**Issue 1:** Password not hashed
- **Fixed:** ✅ Now using generate_password_hash with pbkdf2:sha256
- **File:** src/models/user.py:15
- **Verified:** Added test for password hashing

**Issue 2:** Missing rate limiting
- **Fixed:** ✅ Added @limiter.limit("5 per hour") decorator
- **File:** src/api/auth.py:10
- **Verified:** Added test for rate limit enforcement

**All tests passing:** 10/10 (added 2 new tests)

**Changes:**
- src/models/user.py: Hash passwords before storage
- src/api/auth.py: Add rate limiting decorator
- tests/test_registration.py: Added password hashing and rate limit tests

**Status:** READY_FOR_REVIEW

═══════════════════════════════════════════

ORCHESTRATOR:
Developer addressed all feedback. Requesting re-review...

═══════════════════════════════════════════
@techlead

Re-review Request:

Developer addressed both issues:
1. ✅ Passwords now hashed with pbkdf2:sha256
2. ✅ Rate limiting added (5 per hour)
3. Added 2 new tests
4. All 10 tests passing

Files: user.py, auth.py, test_registration.py

Please verify fixes are correct.
═══════════════════════════════════════════

TECH LEAD:
## Review: APPROVED

**What Was Done Well:**
- Password hashing correctly implemented with strong algorithm
- Rate limiting properly configured
- All previous feedback addressed
- Added tests for new security features
- Code is clean and maintainable

**Code Quality:** Excellent. Production-ready.

**Test Coverage:** Comprehensive. All security features tested.

**Ready for Production:** YES ✅

Great work addressing the feedback! This implementation now follows security best practices.

═══════════════════════════════════════════

ORCHESTRATOR:
═══════════════════════════════════════════
✅ Task Complete: User Registration
═══════════════════════════════════════════

**Summary:**
- Implementation iterations: 2
- Issues found: 2 (1 critical, 1 high)
- All issues resolved
- Tech lead approved
- Status: Production-ready

**Statistics:**
- Total iterations: 4
  - 1 initial implementation
  - 1 review
  - 1 revision
  - 1 re-review
- Final test count: 10/10 passing

**Files Modified:**
- src/api/auth.py
- src/validators.py
- src/models/user.py
- tests/test_registration.py

User registration endpoint is complete and ready for deployment! 🎉
```

## Advanced Usage

### Multiple Tasks

Give orchestrator a list:

```
@orchestrator

I need to implement these features:

1. User registration endpoint
   - Email validation
   - Password hashing
   - JWT token return

2. User login endpoint
   - Email/password authentication
   - Token generation
   - Rate limiting

3. Password reset flow
   - Reset token generation
   - Email sending
   - Token validation

Project: /path/to/project

Please work through each task systematically.
```

The orchestrator will handle each one sequentially with proper review cycles.

### Handling Blockers

If developer gets blocked, orchestrator automatically gets tech lead to help:

```
Developer: "BLOCKED - database migration failing"

Orchestrator: @techlead [passes blocker details]

Tech Lead: [provides specific solutions]

Orchestrator: @developer [passes solutions]

Developer: [continues with solutions]
```

All handled automatically!

### Direct Agent Invocation

Skip orchestrator if you want direct control:

**Step 1: Call developer**
```
@developer

Implement JWT auth for the API...
```

**Step 2: Manually call tech lead**
```
@techlead

Review this implementation:
[paste developer's report]
```

**Step 3: Manually send feedback**
```
@developer

Tech lead said:
[paste tech lead feedback]
```

But orchestrator does this for you automatically!

## Benefits

### Quality Enforcement
- ✅ Every implementation gets reviewed
- ✅ Issues caught before "completion"
- ✅ Security vulnerabilities identified
- ✅ Test coverage verified

### Clear Roles
- 🔨 Developer focuses on implementation
- 👔 Tech Lead focuses on quality
- 🎭 Orchestrator manages coordination

### Iterative Improvement
- Feedback is specific and actionable
- Developer addresses issues systematically
- Re-review ensures fixes are correct
- Multiple iterations until quality met

### Autonomous Operation
- Orchestrator handles all coordination
- You just give initial task
- Agents collaborate automatically
- You get notified when complete

## Agent Customization

### Modify Standards

Edit `.claude/agents/developer.md` to add project-specific rules:

```markdown
## Our Project Standards

- Always use TypeScript strict mode
- All functions must have JSDoc comments
- Use async/await, not callbacks
- Error handling with Result<T, E> type
- Follow Airbnb style guide
```

### Modify Review Criteria

Edit `.claude/agents/techlead.md` to change what gets reviewed:

```markdown
## Project-Specific Checklist

- [ ] All database queries use our ORM
- [ ] API responses use standard envelope format
- [ ] Logging at appropriate levels
- [ ] Feature flags for new functionality
- [ ] Performance metrics added
```

### Modify Orchestration Flow

Edit `.claude/agents/orchestrator.md` to add phases:

```markdown
### Phase X: Security Scan

After tech lead approval:
1. Run automated security scan
2. Review findings
3. If issues: send back to developer
```

## Tips & Best Practices

### For Users

1. **Give clear requirements** - The more specific, the better
2. **Include acceptance criteria** - How to know it's done?
3. **Specify project path** - So agents know where to work
4. **Let orchestrator work** - Don't micro-manage the agents
5. **Review final results** - Agents are good but check their work

### For Developers

1. **Actually implement** - Use Read/Write/Edit/Bash tools
2. **Test thoroughly** - All tests must pass
3. **Report clearly** - Structured reports help reviews
4. **Don't ask permission** - Make reasonable decisions
5. **Ask when stuck** - Tech lead is there to help

### For Tech Leads

1. **Actually read code** - Use Read tool, don't trust descriptions
2. **Be specific** - File:line references, code examples
3. **Prioritize issues** - Critical vs nice-to-have
4. **Be constructive** - Help developer succeed
5. **Approve when ready** - Don't demand perfection

## Troubleshooting

### Agent Not Found

**Problem:** `@orchestrator` doesn't work

**Solution:**
1. Check `.claude/agents/orchestrator.md` exists
2. Make sure you're in project with `.claude` directory
3. Restart Claude Code
4. Try absolute path: `@/path/to/project/.claude/agents/orchestrator`

### Infinite Loop

**Problem:** Developer and tech lead keep going back and forth forever

**Solution:**
- Orchestrator should detect (>5 iterations)
- If it doesn't, interrupt manually
- Break task into smaller pieces
- Or clarify requirements

### Agent Gives Generic Response

**Problem:** Agent doesn't actually use tools or implement

**Solution:**
- Make requirements more specific
- Remind: "Actually use Read/Write/Edit tools"
- Check agent definitions have clear instructions
- May need to rephrase the ask

### Quality Issues

**Problem:** Tech lead approves things that shouldn't be approved

**Solution:**
- Edit `.claude/agents/techlead.md`
- Add stricter criteria
- Add specific checks for your domain
- Provide examples of good/bad code

## Comparison: Custom Agents vs Other Approaches

| Feature | Custom Agents | Task Tool | Scripts |
|---------|--------------|-----------|---------|
| **Setup** | Copy .claude folder | Paste prompt | Run scripts |
| **Invocation** | `@agent` syntax | `Task(...)` | Shell command |
| **Reusability** | Very easy | Copy-paste prompts | Need scripts |
| **Customization** | Edit .md files | Edit prompts | Edit scripts |
| **Persistence** | Agent definitions | None | State files |
| **Best For** | Regular use | One-off tasks | Automation |

**Recommendation:** Use custom agents! They're the cleanest approach for regular multi-agent workflows.

## What's Next?

### Try It Now!

```
@orchestrator

Task: Create a simple TODO list API

Requirements:
- GET /todos - list all
- POST /todos - create
- PUT /todos/:id - update
- DELETE /todos/:id - delete
- Include tests

Project: /tmp/todo-api

Please coordinate implementation and review.
```

### Add More Agents

Create more specialists:

- `.claude/agents/security.md` - Security auditor
- `.claude/agents/performance.md` - Performance reviewer
- `.claude/agents/docs.md` - Documentation writer

Update orchestrator to use them!

### Share With Team

Copy `.claude/` directory to team projects. Everyone gets the same review standards!

## Conclusion

These custom Claude Code agents provide:

✅ **Formal code review** for every implementation
✅ **Clear separation of concerns** between roles
✅ **Iterative improvement** until quality standards met
✅ **Autonomous collaboration** between specialists
✅ **Reusable patterns** across projects
✅ **Easy customization** for your standards

The result: Higher quality code with less manual review overhead!

---

**Ready to start?**

```bash
# Agents are already set up in .claude/agents/
# Just invoke the orchestrator!

@orchestrator [your task]
```

Happy orchestrating! 🎭✨
