# Native Orchestrator Guide - Claude Code Sub-Agents

## Overview

This is a **native Claude Code** multi-agent system that uses Claude's built-in Task tool to spawn and coordinate sub-agents. No external scripts needed - it's all done through Claude Code's agent capabilities!

## Architecture

```
┌─────────────────────────────────────────┐
│     YOU (invoke orchestrator)           │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│    ORCHESTRATOR AGENT                   │
│    (You're talking to this one)         │
│                                         │
│  Coordinates the workflow:              │
│  1. Spawns developer agent              │
│  2. Receives developer results          │
│  3. Spawns tech lead agent              │
│  4. Receives tech lead review           │
│  5. Repeats until task complete         │
└──────────┬──────────────┬───────────────┘
           │              │
    ┌──────▼──────┐  ┌───▼──────────┐
    │  DEVELOPER  │  │  TECH LEAD   │
    │  SUB-AGENT  │  │  SUB-AGENT   │
    │             │  │              │
    │  Spawned    │  │  Spawned     │
    │  via Task   │  │  via Task    │
    │  tool       │  │  tool        │
    └─────────────┘  └──────────────┘
```

## How It Works

The orchestrator uses Claude Code's **Task tool** to spawn sub-agents:

```python
Task(
    subagent_type="general-purpose",
    description="Developer implementing JWT auth",
    prompt="You are a DEVELOPER agent. [full instructions + task]"
)
```

Each sub-agent:
- Receives a complete prompt with context
- Works independently using tools (Read, Write, Edit, Bash, etc.)
- Returns results to the orchestrator
- Orchestrator extracts information and decides next step

## Files

```
prompts/
├── native_orchestrator.txt                # Main orchestrator prompt
└── native-agents/
    ├── developer_task_prompt.txt          # Template for developer tasks
    └── techlead_task_prompt.txt           # Template for tech lead reviews
```

## Usage

### Method 1: Direct Invocation in Claude Code

**Step 1**: Copy the orchestrator prompt

```bash
cat prompts/native_orchestrator.txt
```

**Step 2**: Start a Claude Code session and paste the prompt, followed by your task:

```
[Paste orchestrator prompt here]

═══════════════════════════════════════════════════════════════

TASK: Implement JWT authentication for the REST API

Requirements:
- Token generation on login
- Token validation middleware
- Refresh token mechanism
- Rate limiting on auth endpoints

Project path: /path/to/project
Spec file: specs/001-auth/spec.md

START ORCHESTRATION NOW!
```

**Step 3**: Watch the orchestrator work!

It will:
1. Spawn developer agent to implement
2. Developer reports back with implementation
3. Spawn tech lead agent to review
4. Tech lead provides feedback
5. If changes needed, spawn developer again with feedback
6. Repeat until tech lead approves
7. Report completion

### Method 2: Task File Based

**Step 1**: Create a tasks file `specs/001-auth/tasks.md`:

```markdown
# Authentication Tasks

## Task 1: JWT Authentication
Implement JWT-based authentication system:
- Token generation on login
- Token validation middleware
- Refresh token mechanism
- Rate limiting

## Task 2: User Registration
Implement user registration endpoint:
- Email validation
- Password strength requirements
- Duplicate email check
- Email verification

## Task 3: Password Reset
Implement password reset flow:
- Reset token generation
- Email sending
- Token expiration
- New password validation
```

**Step 2**: Invoke orchestrator with tasks file:

```
[Paste orchestrator prompt]

TASK: Complete all tasks in specs/001-auth/tasks.md

Project path: /path/to/project

For each task:
1. Spawn developer to implement
2. Spawn tech lead to review
3. Iterate until approved
4. Move to next task

START ORCHESTRATION NOW!
```

### Method 3: Using Task Tool (Meta-Level)

You can spawn the orchestrator itself as a sub-agent!

From main Claude Code session:

```python
Use Task tool:

subagent_type: "general-purpose"

description: "Orchestrator managing developer and tech lead for JWT auth implementation"

prompt: """
[Paste contents of native_orchestrator.txt]

TASK: Implement JWT authentication for the REST API

Requirements:
- Token generation on login
- Token validation middleware
- Refresh token mechanism
- Rate limiting on auth endpoints

Project path: /path/to/project

START ORCHESTRATION NOW!
"""
```

This creates a meta-agent structure:
- Main Claude session (you)
  - → Orchestrator agent (spawned via Task)
    - → Developer agent (spawned by orchestrator)
    - → Tech lead agent (spawned by orchestrator)

## Example Session

Here's what a complete orchestration looks like:

```
═══════════════════════════════════════════════════════════════
ORCHESTRATOR: Starting orchestration for JWT authentication
═══════════════════════════════════════════════════════════════

STEP 1: Spawning developer agent...

[Orchestrator uses Task tool to spawn developer with full context]

═══════════════════════════════════════════════════════════════
DEVELOPER AGENT RESULT:
═══════════════════════════════════════════════════════════════

IMPLEMENTATION COMPLETE

Summary: Implemented JWT authentication with token generation,
validation, and refresh mechanism

Files Modified:
- src/auth/jwt_handler.py (created)
- src/middleware/auth_middleware.py (created)
- src/api/routes.py (modified - added auth endpoints)
- tests/test_jwt_auth.py (created)

Key Changes:
- JWT token generation using HS256 algorithm
- Token validation middleware for protected routes
- Refresh token mechanism with secure storage
- Rate limiting on auth endpoints (10/min per IP)

Tests:
- Total: 12
- Passing: 12
- Failing: 0

Concerns:
- Should we add refresh token rotation for extra security?

Status: READY_FOR_REVIEW

═══════════════════════════════════════════════════════════════
ORCHESTRATOR: Developer completed implementation
═══════════════════════════════════════════════════════════════

Files modified: jwt_handler.py, auth_middleware.py, routes.py, test_jwt_auth.py
Tests: 12/12 passing
Developer raised question about refresh token rotation

STEP 2: Spawning tech lead agent for review...

[Orchestrator uses Task tool to spawn tech lead with developer's work]

═══════════════════════════════════════════════════════════════
TECH LEAD AGENT RESULT:
═══════════════════════════════════════════════════════════════

DECISION: CHANGES_REQUESTED

Issues Found:

1. [CRITICAL] SQL Injection Vulnerability
   Location: src/auth/jwt_handler.py:45
   Problem: Using string formatting in database query

   Current code:
   ```python
   cursor.execute(f'SELECT * FROM users WHERE email={email}')
   ```

   Should be:
   ```python
   cursor.execute('SELECT * FROM users WHERE email=?', (email,))
   ```

   Why: Attacker can inject SQL to bypass authentication

2. [HIGH] Missing Token Expiration Test
   Location: tests/test_jwt_auth.py
   Problem: No test verifying expired tokens are rejected

   Add:
   ```python
   def test_expired_token_rejected():
       token = create_token(exp=datetime.now() - timedelta(hours=1))
       response = client.get('/protected',
                           headers={'Authorization': f'Bearer {token}'})
       assert response.status_code == 401
   ```

3. [MEDIUM] Developer's concern about token rotation is valid
   Recommend: Implement refresh token rotation for security

What was done well:
- Clean code structure
- Good test coverage overall
- Rate limiting properly implemented

Next steps:
1. Fix SQL injection (critical!)
2. Add expired token test
3. Implement refresh token rotation
4. Resubmit for review

═══════════════════════════════════════════════════════════════
ORCHESTRATOR: Tech lead requests changes
═══════════════════════════════════════════════════════════════

Issues found:
- CRITICAL: SQL injection vulnerability (line 45)
- HIGH: Missing token expiration test
- MEDIUM: Add refresh token rotation

STEP 3: Spawning developer with tech lead feedback...

[Orchestrator spawns developer again with specific feedback]

═══════════════════════════════════════════════════════════════
DEVELOPER AGENT RESULT:
═══════════════════════════════════════════════════════════════

FEEDBACK ADDRESSED

Original feedback addressed:

1. SQL injection vulnerability
   Fixed: ✅ Changed to parameterized query in jwt_handler.py:45
   Verified: Tested with malicious input - properly escaped

2. Missing token expiration test
   Fixed: ✅ Added test_expired_token_rejected()
   Result: Test passes, expired tokens correctly rejected

3. Refresh token rotation
   Fixed: ✅ Implemented rotation mechanism
   Details: New refresh token issued on each use, old one invalidated

All tests passing: 14/14 (added 2 new tests)

Changes made:
- src/auth/jwt_handler.py: Parameterized query, token rotation
- tests/test_jwt_auth.py: Added 2 tests (expiration, rotation)

Status: READY_FOR_REVIEW

═══════════════════════════════════════════════════════════════
ORCHESTRATOR: Developer addressed all feedback
═══════════════════════════════════════════════════════════════

All issues resolved:
- SQL injection fixed with parameterized query
- Token expiration test added
- Refresh token rotation implemented

STEP 4: Spawning tech lead for re-review...

[Orchestrator spawns tech lead to verify fixes]

═══════════════════════════════════════════════════════════════
TECH LEAD AGENT RESULT:
═══════════════════════════════════════════════════════════════

DECISION: APPROVED

What was done well:
- SQL injection vulnerability properly fixed
- Parameterized queries used correctly throughout
- Excellent test coverage (14 tests covering all scenarios)
- Refresh token rotation implemented securely
- All previous feedback addressed thoroughly

Code quality: Excellent. Production-ready.

Test coverage: Comprehensive. All critical paths tested including:
- Valid token authentication
- Invalid token rejection
- Expired token rejection
- Refresh token rotation
- Rate limiting enforcement

Ready for production: YES

Outstanding work addressing all feedback! This implementation
follows security best practices and is well-tested.

═══════════════════════════════════════════════════════════════
ORCHESTRATOR: Tech lead APPROVED!
═══════════════════════════════════════════════════════════════

✅ Task complete: JWT Authentication

Summary:
- Implementation iterations: 2
- Issues found and fixed: 3 (1 critical, 1 high, 1 medium)
- Final test count: 14/14 passing
- Code review: Approved by tech lead
- Status: Production-ready

Implementation complete! JWT authentication is now ready for deployment.

═══════════════════════════════════════════════════════════════
```

## Benefits of Native Agent Approach

### Compared to Script-Based Systems

**✅ Advantages:**

1. **No external infrastructure needed**
   - No tmux sessions to manage
   - No state files to coordinate
   - No background processes
   - Just native Claude Code capabilities

2. **Simpler to use**
   - Just paste prompt + task
   - Claude handles everything
   - Clear conversation flow
   - Easy to follow progress

3. **More flexible**
   - Can invoke anywhere in Claude Code
   - Can nest orchestrators
   - Can customize on-the-fly
   - Easy to modify prompts

4. **Better error handling**
   - Claude Code's native error recovery
   - No process crashes to handle
   - Clear error messages
   - Easy to retry

5. **Cleaner output**
   - All in one conversation
   - Easy to review history
   - Can scroll back to see decisions
   - Copy-paste friendly

**⚠️ Considerations:**

1. **Token usage**
   - Each sub-agent spawned uses tokens
   - Large tasks may hit limits
   - Solution: Break into smaller tasks

2. **No persistent state**
   - If you close Claude Code, orchestration stops
   - Solution: Orchestrator can save state to files if needed

3. **Sequential execution**
   - Agents run one at a time
   - Can't parallelize multiple developers
   - Usually fine for most workflows

## Customization

### Custom Developer Behavior

Edit `prompts/native-agents/developer_task_prompt.txt`:

```markdown
Add to "CODING STANDARDS" section:

**Our Project Standards:**
- Always use TypeScript strict mode
- All functions must have JSDoc comments
- Use async/await, not callbacks
- Error handling with Result<T, E> type
```

### Custom Tech Lead Criteria

Edit `prompts/native-agents/techlead_task_prompt.txt`:

```markdown
Add to "REVIEW CHECKLIST":

**PROJECT SPECIFIC:**
☐ All database queries use our ORM (no raw SQL)
☐ API responses use standard envelope format
☐ Logging at appropriate levels (info/warn/error)
☐ Feature flags for any new functionality
```

### Custom Orchestration Flow

Edit `prompts/native_orchestrator.txt`:

```markdown
Add custom phase:

PHASE X: SECURITY SCAN
────────────────────────────────────────────
After tech lead approval, before marking complete:

1. Spawn security agent (if available)
2. Run automated security scans
3. Review findings
4. If issues found, send back to developer
```

## Advanced Patterns

### Pattern 1: Parallel Tasks

Orchestrator can manage multiple parallel streams:

```
TASK: Implement 3 independent features:
1. User authentication
2. Data export
3. Email notifications

These can be worked on in parallel by spawning multiple
developer agents. Report progress for each feature separately.
```

Orchestrator spawns 3 developers, tracks each independently, tech lead reviews each.

### Pattern 2: Specialist Agents

Add specialized reviewers:

```python
# In orchestrator, after tech lead approval:

# Spawn security specialist
Task(
    subagent_type="general-purpose",
    description="Security specialist reviewing authentication",
    prompt="You are a SECURITY SPECIALIST. Review this implementation
           for security vulnerabilities: [details]"
)

# Spawn performance specialist
Task(
    subagent_type="general-purpose",
    description="Performance specialist reviewing database queries",
    prompt="You are a PERFORMANCE SPECIALIST. Review this implementation
           for performance issues: [details]"
)
```

### Pattern 3: Hierarchical Orchestration

Orchestrators can spawn orchestrators:

```
Main Orchestrator
  ├─ Feature A Orchestrator
  │   ├─ Developer (implements A)
  │   └─ Tech Lead (reviews A)
  ├─ Feature B Orchestrator
  │   ├─ Developer (implements B)
  │   └─ Tech Lead (reviews B)
  └─ Integration Orchestrator
      ├─ Developer (integrates A+B)
      └─ Tech Lead (reviews integration)
```

### Pattern 4: Learning from History

Orchestrator can maintain a "lessons learned" file:

```markdown
After each task:
1. Spawn tech lead to analyze what went well/poorly
2. Update docs/lessons_learned.md
3. Use in future orchestrations as context
4. Improve over time
```

## Troubleshooting

### Issue: Developer Not Following Instructions

**Solution**: Make developer prompt more explicit:

```markdown
CRITICAL INSTRUCTIONS:
1. You MUST actually use the Write tool to create files
2. You MUST actually use the Bash tool to run tests
3. DO NOT just describe what you would do
4. DO NOT skip steps
5. DO NOT leave placeholders or TODOs
```

### Issue: Tech Lead Too Lenient/Strict

**Solution**: Adjust approval criteria in tech lead prompt:

```markdown
For this project:
- APPROVE if: Core functionality works, tests pass, no security issues
- REQUEST CHANGES if: Any security issue OR tests fail OR incorrect logic

Do not nitpick:
- Variable names (unless truly confusing)
- Code style (unless very inconsistent)
- Minor optimizations
```

### Issue: Infinite Review Loop

**Symptoms**: Developer implements → Tech lead rejects → repeat forever

**Solution**: Add to orchestrator prompt:

```markdown
If same task has been reviewed >3 times:
1. Analyze why it's failing
2. Either:
   a) Break task into smaller pieces
   b) Provide more specific guidance
   c) Escalate to user for input
3. Do not allow infinite loops
```

### Issue: Sub-Agent Errors

**Symptoms**: Task tool fails or agent reports error

**Solution**: Orchestrator should catch and handle:

```markdown
When spawning agents:
1. Wrap in try-catch conceptually
2. If agent reports error/failure
3. Provide more context and retry
4. Or adjust approach
5. If 3 failures, escalate to user
```

## Best Practices

### 1. Provide Complete Context

Always give agents everything they need:
- Original requirements (from spec files)
- Project path and structure
- Previous feedback (if revision)
- Relevant constraints

### 2. Extract Structured Information

When receiving agent results:
- Don't just forward raw output
- Extract: decision, files, issues, questions
- Summarize for next agent
- Keep context focused

### 3. Track Progress

Maintain awareness of:
- Current task
- Iteration count (how many attempts?)
- Issues found and fixed
- Overall progress through task list

### 4. Preserve Quality

- Tech lead should maintain standards
- Don't pressure to approve prematurely
- Better to iterate than ship broken code
- Document quality criteria clearly

### 5. Optimize Token Usage

- Don't include massive file dumps in prompts
- Reference file paths, let agents read them
- Summarize previous results, don't repeat verbatim
- Use concise language in instructions

## Comparison: Native vs. Script-Based

| Aspect | Native Orchestrator | Script-Based (tmux) |
|--------|-------------------|---------------------|
| **Setup** | Copy-paste prompt | Run shell script |
| **Dependencies** | None | bash, tmux, python |
| **Persistence** | Session-based | Process-based |
| **Visibility** | One conversation | Multiple windows |
| **Control** | Orchestrator decides | External scripts decide |
| **Flexibility** | Very flexible | Fixed workflow |
| **State** | In-memory | JSON files |
| **Recovery** | Retry in conversation | Process restart |
| **Best for** | Interactive work, prototyping | Long-running, production |

**Recommendation**:
- Use **Native** for: Development, prototyping, learning, <50 tasks
- Use **Script-based** for: Production runs, 100+ tasks, monitoring needed

## Examples

### Example 1: Single Feature

```
Task: Implement user registration endpoint

Expected flow:
1. Developer implements → Reports ready
2. Tech lead reviews → Finds issue
3. Developer fixes → Reports ready
4. Tech lead reviews → Approves
5. Done!

Estimated: 2-4 iterations, ~5-10 minutes
```

### Example 2: Multi-Task Project

```
Tasks from tasks.md:
1. JWT authentication
2. User registration
3. Password reset
4. Email verification
5. Rate limiting

Expected flow (per task):
- Developer implements
- Tech lead reviews
- Iterate until approved
- Move to next

Estimated: 10-20 iterations total, ~30-60 minutes
```

### Example 3: Complex Feature with Blocker

```
Task: Implement OAuth2 integration

Expected flow:
1. Developer starts → Gets blocked on API keys
2. Orchestrator spawns tech lead for guidance
3. Tech lead provides solutions
4. Developer continues → Implements
5. Tech lead reviews → Requests changes
6. Developer fixes → Tech lead approves
7. Done!

Estimated: 4-6 iterations, ~15-20 minutes
```

## Getting Started

**Quick Start:**

1. Copy orchestrator prompt:
   ```bash
   cat prompts/native_orchestrator.txt | pbcopy
   ```

2. Start Claude Code

3. Paste prompt + add your task:
   ```
   [Pasted prompt]

   TASK: Implement [your feature]

   START ORCHESTRATION NOW!
   ```

4. Watch the agents collaborate!

**Your First Task:**

Try something simple to learn the flow:

```
TASK: Create a simple TODO list API

Requirements:
- GET /todos - list all todos
- POST /todos - create todo
- PUT /todos/:id - update todo
- DELETE /todos/:id - delete todo
- Include basic tests

Project: [your project path]

START ORCHESTRATION NOW!
```

## Conclusion

The native orchestrator leverages Claude Code's built-in Task tool to create a seamless multi-agent collaboration experience. No external scripts, no tmux complexity - just intelligent agents working together to build high-quality software.

**Key Benefits:**
- ✅ Simple to use (paste and go)
- ✅ Formal code review process
- ✅ Iterative improvement
- ✅ Quality enforcement
- ✅ Clear audit trail

**Perfect for:**
- Interactive development
- Prototyping features
- Learning and experimentation
- Code review automation
- Quality-focused development

Start orchestrating! 🎭✨
