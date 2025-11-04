# Multi-Agent Orchestration System Guide

## Overview

This is a **V3 architecture** for the auto-review-agent system that implements a sophisticated multi-agent orchestration pattern. Unlike V1 (async file polling) and V2 (implementer/watchdog), this system features three specialized agents working in concert:

1. **Orchestrator Agent** - Master coordinator managing workflow
2. **Developer Agent** - Implementation specialist writing code
3. **Tech Lead Agent** - Review and guidance specialist

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR AGENT                        │
│                   (Master Coordinator)                       │
│                                                              │
│  • Reads both agent states                                  │
│  • Decides who should act next                              │
│  • Routes information between agents                        │
│  • Manages turn handoffs                                    │
│  • Ensures progress and quality                             │
└───────────────┬─────────────────────┬───────────────────────┘
                │                     │
        ┌───────▼─────────┐   ┌───────▼─────────┐
        │  DEVELOPER      │   │   TECH LEAD     │
        │    AGENT        │   │     AGENT       │
        │                 │   │                 │
        │ • Implements    │   │ • Reviews code  │
        │ • Writes tests  │   │ • Provides      │
        │ • Fixes bugs    │   │   guidance      │
        │ • Reports       │   │ • Unblocks      │
        │   progress      │   │ • Makes         │
        │ • Requests      │   │   decisions     │
        │   reviews       │   │ • Approves work │
        └─────────────────┘   └─────────────────┘
                │                     │
                └──────────┬──────────┘
                           │
                ┌──────────▼──────────┐
                │  COORDINATION DIR   │
                │                     │
                │  State Files:       │
                │  • orchestrator     │
                │  • developer        │
                │  • techlead         │
                │                     │
                │  Messages:          │
                │  • dev → lead       │
                │  • lead → dev       │
                │                     │
                │  Logs:              │
                │  • orchestrator.log │
                │  • developer.log    │
                │  • techlead.log     │
                └─────────────────────┘
```

## Key Concepts

### Turn-Based Collaboration

The system operates on a **turn-based model**:

1. **Orchestrator evaluates** the current state
2. **Orchestrator decides** which agent should act
3. **Agent receives** clear instructions and context
4. **Agent acts** autonomously within their domain
5. **Agent updates** their state file when done
6. **Orchestrator detects** the state change
7. **Cycle repeats** with next decision

This prevents agents from talking past each other and ensures coordinated progress.

### Agent Specialization

Each agent has a **well-defined role**:

**Developer Agent:**
- Focused on implementation
- Writes code, tests, documentation
- Reports blockers and questions
- Requests reviews when ready
- Accepts feedback and iterates

**Tech Lead Agent:**
- Focused on quality and guidance
- Reviews code for correctness and style
- Provides specific, actionable feedback
- Unblocks developers with solutions
- Makes strategic technical decisions

**Orchestrator Agent:**
- Focused on coordination
- Monitors both agents
- Routes information between them
- Ensures agents don't get stuck
- Maintains overall progress

### State-Based Communication

All communication happens through **JSON state files**:

```
coordination/
├── orchestrator_state.json  # Orchestrator's decisions
├── developer_state.json     # Developer's current work
├── techlead_state.json      # Tech lead's reviews
└── messages/
    ├── developer_to_techlead.json  # Review requests, questions
    └── techlead_to_developer.json  # Feedback, guidance
```

This provides:
- **Persistence** - State survives crashes
- **Observability** - Users can inspect any time
- **Debuggability** - Full audit trail
- **Decoupling** - Agents don't need direct connection

## File Structure

### Prompts

```
prompts/
├── orchestrator_agent.txt           # Master coordinator instructions
└── sub-agents/
    ├── developer_agent.txt          # Developer role instructions
    └── techlead_agent.txt           # Tech lead role instructions
```

### Scripts

```
launch-orchestrator.sh     # Start the orchestration system
orchestrator-loop.sh       # Main orchestration logic loop
stop-orchestrator.sh       # Clean shutdown of system
```

### State Files (Created at Runtime)

```
<project>/coordination/
├── orchestrator_state.json
├── developer_state.json
├── techlead_state.json
├── orchestrator.pid
├── messages/
│   ├── developer_to_techlead.json
│   └── techlead_to_developer.json
└── logs/
    ├── orchestrator.log
    ├── orchestrator-loop.log
    ├── developer.log
    └── techlead.log
```

## Usage

### Starting Orchestration

```bash
./launch-orchestrator.sh /path/to/project 001
```

This will:
1. Create a tmux session with 6 windows
2. Start Claude Code in developer window
3. Start Claude Code in tech lead window
4. Initialize all state files
5. Start orchestrator loop in background
6. Display monitoring dashboards

### Tmux Windows

After launch, you'll have:

```
Window 0 (developer)    - Developer agent working live
Window 1 (techlead)     - Tech lead agent reviewing live
Window 2 (orchestrator) - Orchestrator state monitor
Window 3 (dev-state)    - Developer state monitor
Window 4 (lead-state)   - Tech lead state monitor
Window 5 (logs)         - Orchestrator logs streaming
```

### Tmux Commands

```bash
# Attach to running session
tmux attach -t orchestrator_001_12345

# Detach (keep running in background)
Ctrl+b, then d

# Switch windows
Ctrl+b 0  # Developer
Ctrl+b 1  # Tech lead
Ctrl+b 2  # Orchestrator
Ctrl+b 5  # Logs

# Stop orchestration
./stop-orchestrator.sh orchestrator_001_12345
```

### Monitoring Progress

Watch the orchestrator logs in real-time:

```bash
tail -f /path/to/project/coordination/logs/orchestrator.log
```

Check current state:

```bash
cat /path/to/project/coordination/orchestrator_state.json
cat /path/to/project/coordination/developer_state.json
cat /path/to/project/coordination/techlead_state.json
```

## Workflow Example

Let's walk through a complete task cycle:

### Iteration 1: Task Assignment

```
ORCHESTRATOR sees: Developer status="idle"
ORCHESTRATOR decides: Assign task to developer
ORCHESTRATOR activates: Developer agent

Developer agent:
  1. Reads tasks.md
  2. Picks first uncompleted task: "Implement JWT authentication"
  3. Updates state: status="working"
  4. Starts implementation...
```

### Iteration 2-5: Developer Working

```
ORCHESTRATOR sees: Developer status="working"
ORCHESTRATOR decides: Monitor (no action needed)
ORCHESTRATOR logs: "Developer working, 3 files modified recently"

Developer agent:
  - Writes auth.py with JWT logic
  - Adds tests in test_auth.py
  - Runs tests
  - Updates state periodically with progress
```

### Iteration 6: Review Request

```
Developer agent:
  1. Implementation complete
  2. All tests passing
  3. Updates state: status="waiting_review"
  4. Writes message to developer_to_techlead.json:
     "JWT auth implemented. 5 files modified. Tests passing."

ORCHESTRATOR sees: Developer status="waiting_review"
ORCHESTRATOR decides: Activate tech lead for review
ORCHESTRATOR activates: Tech lead agent
```

### Iteration 7: Tech Lead Review

```
Tech lead agent:
  1. Reads review request from messages
  2. Reviews modified files: auth.py, test_auth.py, etc.
  3. Finds issue: "Missing rate limiting on auth endpoint"
  4. Updates state: approved=false, issues=[...]
  5. Writes detailed feedback to techlead_to_developer.json
```

### Iteration 8: Feedback to Developer

```
ORCHESTRATOR sees: Tech lead status="complete", approved=false
ORCHESTRATOR decides: Send feedback to developer
ORCHESTRATOR activates: Developer agent with tech lead feedback

Developer agent:
  1. Reads tech lead feedback
  2. Understands issue: needs rate limiting
  3. Updates state: status="working"
  4. Implements rate limiting...
```

### Iteration 9-10: Developer Revises

```
Developer agent:
  1. Adds rate limiting middleware
  2. Updates tests
  3. Runs tests - all pass
  4. Updates state: status="waiting_review"
  5. Sends re-review request
```

### Iteration 11: Re-Review

```
Tech lead agent:
  1. Reviews changes
  2. Verifies rate limiting implemented correctly
  3. Updates state: approved=true
  4. Sends approval message
```

### Iteration 12: Move to Next Task

```
ORCHESTRATOR sees: Tech lead approved=true
ORCHESTRATOR decides: Move developer to next task
ORCHESTRATOR activates: Developer agent

Developer agent:
  1. Reads next task from tasks.md
  2. Updates state: status="working", current_task="Implement user registration"
  3. Starts new implementation cycle...
```

## State File Schemas

### orchestrator_state.json

```json
{
  "current_phase": "planning|developer_turn|techlead_turn|integration|completed",
  "active_agent": "developer|techlead|none",
  "current_task_id": "task_1",
  "iteration": 42,
  "status": "orchestrating|completed|error",
  "message": "Tech lead reviewing developer's implementation",
  "last_update": "2024-01-15T10:30:00Z",
  "conversation_log": [
    {
      "agent": "developer",
      "action": "implemented_jwt_auth",
      "timestamp": "2024-01-15T10:15:00Z"
    },
    {
      "agent": "techlead",
      "action": "reviewed_requested_changes",
      "timestamp": "2024-01-15T10:25:00Z"
    }
  ]
}
```

### developer_state.json

```json
{
  "status": "idle|working|waiting_review|blocked|complete|error",
  "current_task": "Implement JWT authentication",
  "task_id": "task_1",
  "progress": "Implemented token generation, working on validation",
  "files_modified": [
    "src/auth.py",
    "src/middleware.py",
    "tests/test_auth.py"
  ],
  "test_results": "15 tests passing",
  "blockers": [],
  "questions": [],
  "last_update": "2024-01-15T10:30:00Z",
  "message": "Working on token validation logic",
  "iteration": 5
}
```

### techlead_state.json

```json
{
  "status": "idle|reviewing|providing_guidance|analyzing|complete",
  "reviewing_task": "task_1",
  "review_type": "code_review",
  "feedback": {
    "approved": false,
    "issues": [
      "Missing rate limiting on auth endpoint",
      "No test coverage for token expiration"
    ],
    "suggestions": [
      "Add rate limiting middleware: 10 requests per minute per IP",
      "Add test for expired token rejection"
    ],
    "next_steps": [
      "Implement rate limiting",
      "Add expiration tests",
      "Resubmit for review"
    ]
  },
  "decisions": [
    "Use JWT over sessions for stateless auth"
  ],
  "last_update": "2024-01-15T10:30:00Z"
}
```

### messages/developer_to_techlead.json

```json
{
  "messages": [
    {
      "id": "msg_1737024000",
      "from": "developer",
      "timestamp": "2024-01-15T10:30:00Z",
      "type": "review_request",
      "subject": "JWT authentication implementation complete",
      "body": "Implemented JWT authentication with token generation, validation, and refresh logic. All 15 tests passing. Ready for review.",
      "context": {
        "task_id": "task_1",
        "files": [
          "src/auth.py",
          "src/middleware.py",
          "tests/test_auth.py"
        ],
        "test_status": "passing"
      },
      "priority": "medium",
      "read": false
    }
  ],
  "unread_count": 1
}
```

### messages/techlead_to_developer.json

```json
{
  "messages": [
    {
      "id": "msg_1737024300",
      "from": "techlead",
      "timestamp": "2024-01-15T10:35:00Z",
      "type": "review_feedback",
      "subject": "JWT auth review - changes requested",
      "body": "Good implementation! Found 2 issues:\n\n1. Missing rate limiting on auth endpoint\n   - Add middleware: max 10 requests/min per IP\n   - Prevents brute force attacks\n\n2. No test for token expiration\n   - Add test_expired_token_rejected()\n   - Should return 401\n\nFix these and resubmit. Great work overall!",
      "actionable_items": [
        "Add rate limiting middleware to auth endpoints",
        "Write test for expired token rejection",
        "Run all tests",
        "Resubmit for review"
      ],
      "priority": "high",
      "read": false
    }
  ],
  "unread_count": 1
}
```

## Orchestration Decision Logic

The orchestrator uses a **priority-based decision tree**:

```
Priority 1: Developer BLOCKED
  → Activate tech lead to unblock
  → Tech lead provides specific solutions

Priority 2: Developer WAITING_REVIEW
  → Activate tech lead for code review
  → Tech lead evaluates and provides feedback

Priority 3: Developer has QUESTIONS
  → Activate tech lead to answer
  → Tech lead provides guidance

Priority 4: Tech lead COMPLETE (approved=true)
  → Move developer to next task
  → Reset tech lead to idle

Priority 5: Tech lead COMPLETE (approved=false)
  → Send feedback to developer
  → Developer revises implementation

Priority 6: Developer IDLE
  → Assign next task
  → Developer starts working

Priority 7: Developer WORKING
  → Monitor progress
  → Check for file activity
  → Wait for state change

Priority 8: All else
  → Wait and monitor
  → Log idle state
  → Check for stuck conditions
```

## Benefits Over V1 and V2

### Compared to V1 (Planner/Reviewer)

**V1 Limitations:**
- One-shot execution (no persistence)
- Limited interaction
- Agents can't see each other's work in progress
- No recovery from failures

**V3 Improvements:**
- ✓ Persistent agents in tmux windows
- ✓ Continuous interaction and iteration
- ✓ Real-time visibility into both agents
- ✓ Graceful recovery from errors
- ✓ Better separation of concerns

### Compared to V2 (Implementer/Watchdog)

**V2 Limitations:**
- Watchdog is reactive, not proactive
- No code review step
- Single implementer can get stuck
- Less strategic guidance

**V3 Improvements:**
- ✓ Proactive tech lead reviews quality
- ✓ Formal review step ensures quality
- ✓ Two specialized agents collaborate
- ✓ Strategic decisions made explicitly
- ✓ Better unblocking with specific solutions

## Advanced Features

### Conflict Resolution

When agents disagree or get stuck in loops, the orchestrator can:

1. **Detect the conflict** (same task failing multiple times)
2. **Analyze the pattern** (what's being repeated?)
3. **Mediate** (provide context to both agents)
4. **Make executive decision** (break tie, choose direction)
5. **Enforce outcome** (update states to move forward)

### Health Monitoring

The orchestrator tracks:

- **Agent health**: Are they responsive?
- **Progress velocity**: Tasks completing over time?
- **Quality trends**: First-pass approval rate?
- **Blocker patterns**: Common issues?

### Graceful Degradation

If an agent crashes or becomes unresponsive:

1. Orchestrator detects (state file not updating)
2. Attempts to recover (restart agent)
3. Restores context (from state files)
4. Resumes from last known good state
5. If recovery fails, escalates to user

## Extending the System

### Adding New Agents

To add a new specialized agent (e.g., "Security Auditor"):

1. Create prompt: `prompts/sub-agents/security_agent.txt`
2. Add state file: `coordination/security_state.json`
3. Update orchestrator decision logic to activate security agent
4. Create message channels for communication
5. Update launch script to create window for new agent

### Custom Workflows

You can customize the orchestration logic in `orchestrator-loop.sh`:

```bash
# Add custom decision logic
if [ "$CUSTOM_CONDITION" = "true" ]; then
    NEXT_ACTION="custom_action"
fi

# Add custom action handler
case "$NEXT_ACTION" in
    custom_action)
        log_message "Executing custom action..."
        # Your custom logic here
        ;;
esac
```

### Integration with External Tools

State files are JSON, so you can:

- Monitor with external scripts
- Trigger alerts on certain states
- Inject decisions from external systems
- Export metrics to monitoring tools

Example:

```bash
# Watch for blocked states and alert
watch -n 10 '
  if jq -r .status coordination/developer_state.json | grep -q "blocked"; then
    echo "Developer blocked!" | mail -s "Alert" admin@example.com
  fi
'
```

## Troubleshooting

### Orchestrator Not Making Progress

**Symptoms:** Iteration count increasing but nothing happening

**Check:**
1. Are agent windows responsive? (Switch to them in tmux)
2. Are state files being updated? (`ls -la coordination/*.json`)
3. Are there errors in logs? (`tail coordination/logs/*.log`)

**Solutions:**
- Restart stuck agent: Switch to window, Ctrl+C, restart Claude
- Reset state files: Delete and let orchestrator reinitialize
- Check for filesystem issues: Disk space, permissions

### Agents Ignoring State Files

**Symptoms:** Agents not reading/writing state files

**Check:**
1. Are file paths correct in prompts?
2. Can agents write to coordination directory?
3. Are prompts being loaded correctly?

**Solutions:**
- Verify file paths are absolute
- Check directory permissions
- Re-read prompt files and send to agents

### Infinite Review Loop

**Symptoms:** Developer implements, tech lead rejects, repeat forever

**Check:**
1. What is tech lead requesting?
2. Is developer understanding the feedback?
3. Is the task actually feasible?

**Solutions:**
- Manually intervene: Type guidance in tech lead window
- Break task into smaller pieces
- Update tech lead prompt to be more specific
- Update developer prompt to ask clarifying questions

### Session Crashes

**Symptoms:** Tmux session killed or exits unexpectedly

**Check:**
1. Orchestrator loop still running? (`ps aux | grep orchestrator`)
2. System resources available? (memory, CPU)
3. Any errors in orchestrator-loop.log?

**Solutions:**
- Restart: `./launch-orchestrator.sh` (state preserved)
- Check system resources: `free -h`, `top`
- Review logs for crash cause

## Best Practices

### 1. Clear Task Definitions

Write tasks in `tasks.md` that are:
- **Specific** - "Implement JWT auth" not "Add security"
- **Testable** - "All tests pass" not "Make it work"
- **Sized appropriately** - 30-60 min each, not 8 hours

### 2. Monitor Early, Intervene Rarely

- Watch orchestrator logs to understand decisions
- Let agents work autonomously
- Only intervene when truly stuck (3+ failed attempts)
- Document patterns for future orchestrator improvements

### 3. Iterate on Prompts

As you learn what works:
- Update agent prompts with learnings
- Add examples of good behaviors
- Clarify areas where agents struggle
- Test changes with small tasks first

### 4. Preserve State Between Runs

State files are your safety net:
- Never delete while orchestration running
- Back up before major changes
- Use for post-mortem analysis
- Archive completed runs for learning

### 5. Use Logs for Debugging

Logs tell the story:
- Orchestrator log: Decision flow
- Developer log: Implementation details
- Tech lead log: Review reasoning

When debugging, trace a single task through all three logs.

## Comparison Matrix

| Feature | V1 (Planner/Reviewer) | V2 (Implementer/Watchdog) | V3 (Orchestrator) |
|---------|----------------------|---------------------------|-------------------|
| **Architecture** | Async file polling | Persistent + monitor | Multi-agent orchestration |
| **Agent Persistence** | No (one-shot) | Yes (tmux) | Yes (tmux) |
| **Code Review** | Informal | No formal review | Formal review cycle |
| **Unblocking** | Reactive | Pattern matching | Proactive guidance |
| **Visibility** | Logs only | Live windows + dashboard | Live windows + state + logs |
| **Recovery** | Poor | Good | Excellent |
| **Scalability** | <50 tasks | <200 tasks | 500+ tasks |
| **Quality Control** | Good | Fair | Excellent |
| **Complexity** | Medium | Medium | High |

## Future Enhancements

Possible improvements to the orchestration system:

1. **Multi-developer support** - Multiple developers working in parallel
2. **Specialized reviewers** - Security auditor, performance analyst
3. **Learning from history** - Improve decisions based on past runs
4. **User interaction API** - External control and monitoring
5. **Distributed execution** - Agents on different machines
6. **Workflow customization** - YAML-based workflow definitions
7. **Quality gates** - Automated checks before phase transitions
8. **Metrics dashboard** - Real-time visualization of progress

## Conclusion

The V3 Orchestrator system represents a sophisticated approach to autonomous software development. By separating concerns (implementation, review, coordination) and formalizing communication protocols, it achieves both autonomy and quality.

Key takeaways:

- **Three agents** (orchestrator, developer, tech lead) work together
- **Turn-based** coordination prevents conflicts
- **State files** provide persistence and observability
- **Formal review cycle** ensures quality
- **Extensible architecture** allows customization

Use this system when you need:
- High-quality implementations
- Complex, multi-step tasks
- Autonomous operation
- Formal review process
- Detailed audit trail

---

**Ready to start?**

```bash
./launch-orchestrator.sh /path/to/project 001
```

Watch the magic happen! ✨
