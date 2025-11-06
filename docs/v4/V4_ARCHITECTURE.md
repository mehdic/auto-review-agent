# V4 Multi-Agent Orchestration Architecture

## Overview

V4 is an **adaptive multi-agent orchestration system** that intelligently scales from simple single-feature development to complex multi-feature parallel execution based on the requirements.

**Key Innovation**: The system automatically decides whether to use simple 2-agent mode or advanced PM-coordinated mode with up to 4 parallel developers.

## Architecture Comparison

| System | Agents | Coordination | Parallelism | Best For |
|--------|--------|--------------|-------------|----------|
| **V3 (Current)** | 2 (Developer, Tech Lead) | Orchestrator | Sequential | Single features |
| **V4 (Adaptive)** | 2-6 (PM, Devs×1-4, QA, Tech Lead) | PM + Orchestrator | Adaptive (1-4 parallel) | Any complexity |

## The V4 Agent Team

### Core Agents

1. **Orchestrator** (Main Claude)
   - Only persistent agent throughout session
   - Spawns all other agents via Task tool
   - Routes messages between agents
   - Maintains workflow state
   - **Never does implementation work**

2. **Project Manager (PM)** (Spawned via Task)
   - Analyzes requirements complexity
   - Decides execution mode (simple vs parallel)
   - Breaks work into task groups
   - Validates task independence
   - Tracks overall progress
   - **Sends BAZINGA when all work complete**

3. **Developer** (1-4 instances spawned via Task)
   - Implements assigned task group
   - Writes unit tests
   - Commits to feature branch
   - Reports status: READY_FOR_QA / BLOCKED / INCOMPLETE

4. **QA Expert** (Spawned via Task)
   - Runs integration tests
   - Runs contract tests
   - Runs e2e tests
   - Reports PASS/FAIL with details

5. **Tech Lead** (Spawned via Task)
   - Reviews code quality
   - Checks security
   - Validates best practices
   - Unblocks developers
   - Approves/rejects with feedback

## Adaptive Mode Logic

The system automatically chooses the right execution mode:

```
┌─────────────────────────────────────────────┐
│         User Provides Requirements          │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│      Orchestrator Spawns PM (Always)        │
└──────────────────┬──────────────────────────┘
                   ↓
┌─────────────────────────────────────────────┐
│         PM Analyzes Requirements            │
│                                             │
│  Checks:                                    │
│  • Number of distinct features              │
│  • File/area independence                   │
│  • Complexity level                         │
│  • Dependencies between tasks               │
└──────────────────┬──────────────────────────┘
                   ↓
         ┌─────────┴─────────┐
         ↓                   ↓
┌─────────────────┐  ┌──────────────────┐
│  SIMPLE MODE    │  │  PARALLEL MODE   │
│                 │  │                  │
│  1 Developer    │  │  2-4 Developers  │
│  Sequential     │  │  Parallel        │
│  Dev→QA→TechLd  │  │  PM coordinates  │
└─────────────────┘  └──────────────────┘
```

### Simple Mode Criteria

PM chooses SIMPLE mode when:
- Single feature or closely related tasks
- Tasks affect same files/modules
- Low complexity
- Sequential dependencies exist
- Quick turnaround needed

**Flow**: Developer → QA → Tech Lead → BAZINGA

### Parallel Mode Criteria

PM chooses PARALLEL mode when:
- Multiple independent features (2-4)
- Tasks affect different files/modules
- High complexity project
- No critical dependencies between groups
- Parallelization provides value

**Flow**: Multiple developers in parallel → Each through QA → Each through Tech Lead → PM checks completion → BAZINGA

## State Management

Since Task tool spawns are **stateless** (each spawn is a fresh instance), V4 uses state files for "memory":

### State Files

```
coordination/
├── pm_state.json           # PM's memory across spawns
├── group_status.json       # Per-group tracking
├── orchestrator_state.json # Orchestrator decisions
└── messages/
    ├── dev_to_qa.json      # Developer → QA handoffs
    ├── qa_to_techlead.json # QA → Tech Lead handoffs
    └── techlead_to_dev.json# Tech Lead → Developer feedback
```

### State File Pattern

Every time an agent is spawned:

```
1. Orchestrator reads: coordination/{agent}_state.json
2. Orchestrator includes state in agent's prompt
3. Agent processes request
4. Agent updates state file
5. Agent returns result
6. Agent instance dies

Next spawn:
1. Orchestrator reads updated state
2. New agent instance has "memory" via state
```

This gives stateless agents persistent memory.

## Detailed Workflow

### Phase 0: Initialization

```
User: /orchestrate [requirements]
       ↓
Orchestrator:
1. Creates coordination/ folder if needed
2. Initializes empty state files
3. Spawns PM with requirements
```

### Phase 1: Planning (PM Decides Mode)

```
Project Manager Agent:
1. Reads pm_state.json (empty on first run)
2. Analyzes requirements
3. Counts distinct features
4. Checks file/module overlap
5. Evaluates complexity
6. Makes decision:

   SIMPLE MODE:
   {
     "mode": "simple",
     "task_groups": [
       {"id": "main", "tasks": [...], "files": [...]}
     ],
     "parallel_count": 1
   }

   PARALLEL MODE:
   {
     "mode": "parallel",
     "task_groups": [
       {"id": "A", "tasks": [...], "files": [...], "can_parallel": true},
       {"id": "B", "tasks": [...], "files": [...], "can_parallel": true},
       {"id": "C", "tasks": [...], "files": [...], "can_parallel": true}
     ],
     "parallel_count": 3
   }

7. Updates pm_state.json
8. Returns decision to orchestrator
```

### Phase 2A: Simple Mode Execution

```
Orchestrator spawns 1 developer:
  ↓
Developer implements → commits → returns READY_FOR_QA
  ↓
Orchestrator spawns QA Expert:
  ↓
QA runs all tests → returns PASS/FAIL
  ↓
If PASS: Orchestrator spawns Tech Lead for review
If FAIL: Back to Developer with failures
  ↓
Tech Lead reviews → returns APPROVED/CHANGES_REQUESTED
  ↓
If APPROVED: Orchestrator spawns PM to confirm completion
If CHANGES_REQUESTED: Back to Developer with feedback
  ↓
PM checks: All done? → Returns BAZINGA
  ↓
Orchestrator detects BAZINGA → END
```

### Phase 2B: Parallel Mode Execution

```
Orchestrator spawns N developers (2-4) IN PARALLEL:

Task(developer, group_A) ─┐
Task(developer, group_B) ─┤
Task(developer, group_C) ─┤─→ All spawn in ONE message
Task(developer, group_D) ─┘
                           ↓
Each developer independently:
- Creates feature/group-X branch
- Implements their tasks
- Writes unit tests
- Commits
- Returns READY_FOR_QA / BLOCKED / INCOMPLETE
                           ↓
Orchestrator receives all N responses
Routes EACH independently:
                           ↓
For each READY_FOR_QA:
  Spawn QA Expert for that group
                           ↓
For each QA PASS:
  Spawn Tech Lead for that group
                           ↓
For each Tech Lead APPROVED:
  Mark group complete in group_status.json
                           ↓
When ALL groups complete:
  Spawn PM with updated state
                           ↓
PM checks:
- More work? → Return next batch of groups
- All done? → Return BAZINGA
                           ↓
If BAZINGA: END
If more work: Loop to spawn next batch
```

## Routing Logic

The orchestrator follows this decision tree:

```
After Developer returns:
├─ Status = READY_FOR_QA → Spawn QA Expert
├─ Status = BLOCKED → Spawn Tech Lead for unblocking
└─ Status = INCOMPLETE → Spawn Tech Lead for guidance

After QA Expert returns:
├─ Result = PASS → Spawn Tech Lead for review
└─ Result = FAIL → Spawn Developer with failures

After Tech Lead returns:
├─ Decision = APPROVED → Mark group complete
│                        Check if all groups done
│                        If yes: Spawn PM
└─ Decision = CHANGES_REQUESTED → Spawn Developer with feedback

After PM returns:
├─ Has "BAZINGA" → END (task complete)
└─ No "BAZINGA" → Continue with next assignments
```

## Git Workflow

### Simple Mode

```
main (protected)
  └── feature/task-name
         └── All commits here
```

### Parallel Mode

```
main (protected)
  ├── feature/group-A-auth-system
  ├── feature/group-B-user-mgmt
  ├── feature/group-C-api-endpoints
  └── feature/group-D-db-migrations

After all groups approved:
  Merge all branches to main (or create integration branch first)
```

Each developer works in isolation on their branch, preventing git conflicts.

## QA Expert Responsibilities

The QA Expert performs three types of testing:

### 1. Integration Tests
- Tests interaction between modules
- API endpoint testing
- Database integration testing
- Service integration testing

### 2. Contract Tests
- Verifies API contracts are maintained
- Checks request/response schemas
- Validates backward compatibility
- Tests consumer-provider contracts

### 3. End-to-End Tests
- Full user flow testing
- UI testing (if applicable)
- Cross-system testing
- Acceptance testing

**QA Test Flow:**

```
QA Expert:
1. Checkout feature branch
2. Run integration tests → Report results
3. Run contract tests → Report results
4. Run e2e tests → Report results
5. Aggregate results:
   - ALL PASS → Return PASS
   - ANY FAIL → Return FAIL with details
```

## BAZINGA Signal

**Critical Change from V3:**

In V3: Tech Lead sends BAZINGA when code approved
In V4: **Only PM sends BAZINGA** when ALL work complete

```
Tech Lead role:
- Reviews individual task groups
- Returns: GROUP_APPROVED or CHANGES_REQUESTED
- NEVER sends BAZINGA

PM role:
- Tracks ALL task groups across ALL batches
- Checks completion status
- When everything done: Sends BAZINGA
- Only agent that sends BAZINGA
```

## Failure Handling & Recovery

### Developer Blocked

```
Developer returns: Status = BLOCKED
Blocker: "Can't connect to external API, no credentials"
  ↓
Orchestrator spawns Tech Lead with blocker details
  ↓
Tech Lead provides specific solutions:
1. Check .env file for API_KEY
2. Try: export API_KEY=test_key
3. Alternative: Use mock API for development
  ↓
Orchestrator spawns Developer again with solutions
  ↓
Developer tries solutions → Unblocked → Continues
```

### QA Tests Fail

```
QA Expert returns: Result = FAIL
Failures:
- test_auth_invalid_token: Expected 401, got 500
- test_rate_limiting: Rate limit not working
  ↓
Orchestrator spawns Developer with failure details
  ↓
Developer fixes issues → Resubmits
  ↓
Orchestrator spawns QA again
  ↓
QA re-tests → PASS → Continue to Tech Lead
```

### Stuck Detection

```
Orchestrator tracks per group:
- dev_attempts: Number of developer iterations
- qa_attempts: Number of QA test runs
- review_attempts: Number of tech lead reviews

IF dev_attempts > 5:
  → Spawn PM to evaluate: Should we simplify the task?

IF qa_attempts > 3:
  → Spawn Tech Lead to help Developer understand test requirements

IF review_attempts > 3:
  → Spawn PM to mediate: Break into smaller tasks
```

## Benefits of V4

### 1. Adaptive Complexity
- Simple tasks stay simple (no overhead)
- Complex tasks get parallel execution (faster)
- Automatic decision based on requirements

### 2. Specialized Testing
- QA Expert handles integration, contract, and e2e tests
- Separates testing expertise from development
- Better test coverage and quality

### 3. Intelligent Coordination
- PM provides project-level view
- Tracks progress across multiple workstreams
- Makes strategic decisions (parallel vs sequential)

### 4. Scalability
- Sequential: 1 developer (simple tasks)
- Parallel: 2-4 developers (complex projects)
- PM decides optimal parallelism

### 5. Clear Separation of Concerns
- Orchestrator: Message routing only
- PM: Project coordination
- Developer: Implementation
- QA: Testing
- Tech Lead: Quality & guidance

## Mitigations for V4 Cons

### Con 1: Increased Complexity

**Mitigation Strategies:**

1. **Adaptive Mode**: Simple tasks use 2-agent mode automatically
2. **Clear State Files**: All state is visible and debuggable
3. **Explicit Handoffs**: Each agent declares next agent and context
4. **Comprehensive Logging**: Every interaction logged with context
5. **Fail-Fast**: Detect issues early, don't let them compound

### Con 2: More Failure Points

**Mitigation Strategies:**

1. **Stuck Detection**: Track iterations per group, escalate if stuck
2. **Retry Logic**: Automatic retry for transient failures
3. **Graceful Degradation**: If QA fails, still get Tech Lead review
4. **State Persistence**: Crash-safe, can resume from last state
5. **Timeout Limits**: Maximum iterations before escalation to user

### Con 3: Context Management

**Mitigation Strategies:**

1. **State Files**: All context in JSON files, passed to each spawn
2. **Context Summarization**: Long histories get summarized
3. **Relevant Context Only**: Each agent gets only what they need
4. **Message Queue Pattern**: Structured messages between agents
5. **Session Isolation**: Each orchestration session has unique ID

### Con 4: Overkill for Simple Tasks

**Mitigation Strategies:**

1. **Adaptive Mode**: Automatically uses simple 2-agent flow
2. **PM Makes Decision**: PM evaluates and chooses mode
3. **Fast Path**: Simple mode bypasses PM coordination overhead
4. **No Penalty**: Simple tasks don't pay for parallel infrastructure
5. **User Override**: User can force simple mode if needed

## Performance Comparison

### Simple Task: "Add password reset endpoint"

**V3 (2-agent)**:
- Developer: 5 min
- Tech Lead: 2 min
- Total: 7 min
- Iterations: 2-3

**V4 (adaptive, chooses simple)**:
- PM Analysis: 30 sec
- Developer: 5 min
- QA Expert: 1 min
- Tech Lead: 2 min
- PM Confirm: 15 sec
- Total: ~9 min
- Iterations: 5

**Verdict**: Slight overhead (~2 min) but better test coverage

### Complex Project: "Implement auth system + user mgmt + API + DB"

**V3 (sequential)**:
- Auth: 15 min
- User Mgmt: 12 min
- API: 10 min
- DB: 8 min
- Total: 45 min
- Iterations: 12-15

**V4 (adaptive, chooses parallel)**:
- PM Planning: 2 min
- 4 Developers (parallel): 15 min (longest group)
- 4 QA Tests (parallel): 3 min
- 4 Tech Reviews (parallel): 5 min
- PM Final Check: 1 min
- Total: ~26 min
- Iterations: 18-20

**Verdict**: 40% faster despite more iterations (parallelism wins)

## Monitoring & Observability

### Log Structure

```
docs/orchestration-log.md

## Session: v4_20250106_100000

### Configuration
- Mode: Adaptive (PM decides)
- Max Parallel Developers: 4
- QA Testing: Full (integration + contract + e2e)

### Iteration 1 - Project Manager (Mode Selection)
Timestamp: 2025-01-06 10:00:00
Decision: PARALLEL MODE (3 groups)
Reasoning: 3 independent features, different file areas

### Iteration 2-4 - Developers A, B, C (Parallel Execution)
3 developers spawned in parallel

### Iteration 5 - QA Expert (Group A)
Tests: Integration ✅, Contract ✅, E2E ✅
Result: PASS

### Iteration 6 - Tech Lead (Group A)
Review: APPROVED ✅
Group A: COMPLETE

[... continues ...]

### Iteration 20 - Project Manager (Final Check)
All groups complete: A ✅ B ✅ C ✅
Result: BAZINGA - Task Complete
```

### State Files (Snapshots)

At any time, user can check:

```bash
# Check PM decision and progress
cat coordination/pm_state.json

# Check individual group status
cat coordination/group_status.json

# Check orchestrator decisions
cat coordination/orchestrator_state.json
```

### Visual Progress

```
═══════════════════════════════════════════
V4 Orchestration Progress
═══════════════════════════════════════════

Mode: PARALLEL (3 groups)

Group A [Auth System]        ████████████ COMPLETE ✅
Group B [User Management]    ████████████ COMPLETE ✅
Group C [API Endpoints]      ████████░░░░ IN_PROGRESS (QA)

Overall: 66% complete (2/3 groups done)
Estimated time remaining: 5 minutes
```

## Comparison Table: V3 vs V4

| Feature | V3 | V4 |
|---------|----|----|
| **Architecture** | Fixed 2-agent | Adaptive 2-6 agent |
| **Mode Selection** | Manual | Automatic (PM decides) |
| **Parallelism** | None | Up to 4 developers |
| **QA Testing** | Developer does it | QA Expert specialist |
| **Contract Tests** | No | Yes (QA Expert) |
| **Project Coordination** | Orchestrator | PM + Orchestrator |
| **BAZINGA Signal** | Tech Lead | PM |
| **Complexity Scaling** | Fixed | Adaptive |
| **Simple Tasks** | Optimal | Small overhead (~2 min) |
| **Complex Projects** | Slow (sequential) | Fast (parallel) |
| **Failure Recovery** | Basic | Advanced (stuck detection) |
| **Context Management** | In-prompt | State files |
| **Observability** | Basic logs | Logs + state files + progress |

## File Structure

```
project/
├── .claude/
│   └── commands/
│       └── orchestrate.md          # V4 orchestration command
├── coordination/                    # Created on first run
│   ├── pm_state.json               # PM memory
│   ├── group_status.json           # Per-group tracking
│   ├── orchestrator_state.json     # Orchestration decisions
│   └── messages/
│       ├── dev_to_qa.json
│       ├── qa_to_techlead.json
│       └── techlead_to_dev.json
├── docs/
│   ├── orchestration-log.md        # Full session log
│   └── v4/                          # V4 documentation
│       ├── V4_ARCHITECTURE.md      # This file
│       ├── V4_WORKFLOW_DIAGRAMS.md # Visual workflows
│       ├── V4_STATE_SCHEMAS.md     # State file schemas
│       ├── V4_AGENT_PROMPTS.md     # Agent instructions
│       └── V4_MITIGATIONS.md       # Handling cons
└── .claud.md                        # Project context (auto-updated)
```

## Getting Started

### Run Orchestration

```
/orchestrate Implement JWT authentication, user registration, and password reset
```

The PM will analyze and choose the appropriate mode automatically.

### Force Simple Mode (Optional)

```
/orchestrate --mode=simple Implement JWT authentication
```

### Force Parallel Mode (Optional)

```
/orchestrate --mode=parallel Implement auth system + user mgmt + API
```

### Monitor Progress

```bash
# Watch live log
tail -f docs/orchestration-log.md

# Check PM state
cat coordination/pm_state.json

# Check group status
cat coordination/group_status.json
```

## Conclusion

V4 represents the evolution of multi-agent orchestration:

✅ **Adaptive**: Scales from simple to complex automatically
✅ **Intelligent**: PM makes strategic coordination decisions
✅ **Parallel**: Up to 4 developers for maximum throughput
✅ **Specialized**: QA Expert for comprehensive testing
✅ **Resilient**: Multiple mitigation strategies for cons
✅ **Observable**: Complete visibility via logs and state files

The system maintains the simplicity of V3 for simple tasks while providing powerful parallelization capabilities for complex projects.

---

**Next Steps**: See the other V4 documentation files for detailed workflows, state schemas, and agent prompts.
