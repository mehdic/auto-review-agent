# V4 Workflow Diagrams

This document contains comprehensive visual workflows for the V4 multi-agent orchestration system.

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [Adaptive Mode Selection](#adaptive-mode-selection)
3. [Simple Mode Flow](#simple-mode-flow)
4. [Parallel Mode Flow](#parallel-mode-flow)
5. [State Management Flow](#state-management-flow)
6. [Routing Decision Tree](#routing-decision-tree)
7. [Failure Recovery Flows](#failure-recovery-flows)

---

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│                         USER PROVIDES REQUIREMENTS                       │
│                                                                          │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                                 ↓
┌──────────────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR (Main Claude)                        │
│                                                                          │
│  Role: Message Router & Workflow Coordinator                            │
│  Persistent: YES (only persistent agent)                                │
│  Tools: Task (spawn), Write (log), Read (state files)                  │
│                                                                          │
│  Responsibilities:                                                       │
│  • Spawn all other agents via Task tool                                │
│  • Route messages between agents                                        │
│  • Maintain workflow state                                              │
│  • Log all interactions                                                 │
│  • NEVER do implementation work                                         │
│                                                                          │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                                 ↓
              ┌──────────────────────────────────┐
              │     Spawns Agent Specialists     │
              └──────────────────┬───────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ↓                       ↓                       ↓
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ PROJECT MANAGER │    │   DEVELOPER(S)   │    │   QA EXPERT     │
│                 │    │                  │    │                 │
│ Spawned: Task   │    │ Spawned: Task    │    │ Spawned: Task   │
│ Persistent: NO  │    │ Persistent: NO   │    │ Persistent: NO  │
│                 │    │ Count: 1-4       │    │                 │
│ Analyzes        │    │                  │    │ Integration     │
│ requirements    │    │ Implements       │    │ testing         │
│ Decides mode    │    │ code & tests     │    │ Contract        │
│ Creates groups  │    │ Commits work     │    │ testing         │
│ Tracks progress │    │ Reports status   │    │ E2E testing     │
│ Sends BAZINGA   │    │                  │    │ Reports results │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                 │
                                 ↓
                       ┌──────────────────┐
                       │   TECH LEAD      │
                       │                  │
                       │ Spawned: Task    │
                       │ Persistent: NO   │
                       │                  │
                       │ Reviews code     │
                       │ Checks security  │
                       │ Validates best   │
                       │ practices        │
                       │ Unblocks devs    │
                       │ Approves groups  │
                       └──────────────────┘
```

---

## Adaptive Mode Selection

```
┌─────────────────────────────────────────────────────────────┐
│                   User: /orchestrate [REQUIREMENTS]          │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────┐
│          Orchestrator: Initialize Session                    │
│                                                              │
│  1. Create coordination/ folder                             │
│  2. Initialize empty state files                            │
│  3. Generate unique session ID                              │
│  4. Read pm_state.json (empty on first run)                │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────┐
│          Orchestrator: Spawn PM for Analysis                 │
│                                                              │
│  Task(                                                       │
│    subagent_type: "general-purpose",                        │
│    description: "PM analyzing requirements",                │
│    prompt: [PM prompt + requirements + state]               │
│  )                                                           │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ↓
┌─────────────────────────────────────────────────────────────┐
│            PROJECT MANAGER: Analyze Requirements             │
│                                                              │
│  Analysis Criteria:                                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 1. Count distinct features/capabilities                │ │
│  │ 2. Identify file/module overlap                        │ │
│  │ 3. Check for dependencies between tasks                │ │
│  │ 4. Evaluate complexity level                           │ │
│  │ 5. Estimate effort per feature                         │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Decision Logic:                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ IF (features = 1) OR (file_overlap = high):            │ │
│  │     → SIMPLE MODE (1 developer)                        │ │
│  │                                                         │ │
│  │ ELSE IF (features >= 2) AND (independent = true):      │ │
│  │     parallel_count = min(features, 4)                  │ │
│  │     → PARALLEL MODE (N developers)                     │ │
│  │                                                         │ │
│  │ ELSE IF (dependencies = critical):                     │ │
│  │     → SIMPLE MODE (sequential safer)                   │ │
│  │                                                         │ │
│  │ ELSE:                                                   │ │
│  │     → SIMPLE MODE (default safe choice)                │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────────────────────┬────────────────────────────────┘
                             │
                   ┌─────────┴─────────┐
                   │                   │
                   ↓                   ↓
┌──────────────────────────┐  ┌────────────────────────────┐
│      SIMPLE MODE         │  │      PARALLEL MODE         │
│                          │  │                            │
│  PM Returns:             │  │  PM Returns:               │
│  {                       │  │  {                         │
│    "mode": "simple",     │  │    "mode": "parallel",     │
│    "task_groups": [      │  │    "task_groups": [        │
│      {                   │  │      {                     │
│        "id": "main",     │  │        "id": "A",          │
│        "tasks": [...],   │  │        "tasks": [...],     │
│        "files": [...]    │  │        "files": [...],     │
│      }                   │  │        "branch":           │
│    ],                    │  │          "feature/group-A" │
│    "parallel_count": 1,  │  │      },                    │
│    "reasoning": "..."    │  │      {...}, {...}, {...}   │
│  }                       │  │    ],                      │
│                          │  │    "parallel_count": 3,    │
│  Updates: pm_state.json  │  │    "reasoning": "..."      │
│  Returns to: Orchestrator│  │  }                         │
│                          │  │                            │
│                          │  │  Updates: pm_state.json    │
│                          │  │  Returns to: Orchestrator  │
└──────────────────────────┘  └────────────────────────────┘
```

---

## Simple Mode Flow

```
┌────────────────────────────────────────────────────────────────┐
│                      SIMPLE MODE EXECUTION                     │
│                     (Single Developer Flow)                    │
└──────────────────────────┬─────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Spawn Single Developer                           │
│                                                                  │
│  Task(                                                           │
│    description: "Developer implementing main task",             │
│    prompt: [All requirements + main task group]                 │
│  )                                                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  DEVELOPER AGENT                                                 │
│                                                                  │
│  1. Read requirements                                            │
│  2. Analyze codebase                                             │
│  3. Implement features                                           │
│  4. Write unit tests                                             │
│  5. Run unit tests (must pass)                                   │
│  6. Commit to feature branch                                     │
│  7. Report status                                                │
│                                                                  │
│  Returns:                                                        │
│  {                                                               │
│    "status": "READY_FOR_QA",                                     │
│    "files_modified": [...],                                      │
│    "tests_passing": "15/15",                                     │
│    "branch": "feature/task-name",                                │
│    "commits": ["abc123", "def456"]                               │
│  }                                                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Route Based on Status                            │
│                                                                  │
│  IF status = "READY_FOR_QA": → Spawn QA Expert                 │
│  IF status = "BLOCKED": → Spawn Tech Lead for unblocking       │
│  IF status = "INCOMPLETE": → Spawn Tech Lead for guidance      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ (Assuming READY_FOR_QA)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  QA EXPERT AGENT                                                 │
│                                                                  │
│  1. Checkout feature branch                                      │
│  2. Run Integration Tests                                        │
│     • API endpoint testing                                       │
│     • Database integration                                       │
│     • Service interaction testing                                │
│  3. Run Contract Tests                                           │
│     • API contract validation                                    │
│     • Schema verification                                        │
│     • Backward compatibility                                     │
│  4. Run E2E Tests                                                │
│     • Full user flows                                            │
│     • Cross-system testing                                       │
│  5. Aggregate results                                            │
│                                                                  │
│  Returns:                                                        │
│  {                                                               │
│    "result": "PASS",                                             │
│    "integration_tests": "25/25 passed",                          │
│    "contract_tests": "10/10 passed",                             │
│    "e2e_tests": "8/8 passed",                                    │
│    "total_time": "2m 30s"                                        │
│  }                                                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Route QA Result                                  │
│                                                                  │
│  IF result = "PASS": → Spawn Tech Lead for review              │
│  IF result = "FAIL": → Spawn Developer with failures           │
└──────────────────────────┬──────────────────────────────────────┘
                           │ (Assuming PASS)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  TECH LEAD AGENT                                                 │
│                                                                  │
│  Context Received:                                               │
│  • Developer implementation details                              │
│  • QA test results (all passing)                                │
│  • Files modified                                                │
│  • Original requirements                                         │
│                                                                  │
│  Review Process:                                                 │
│  1. Read modified files                                          │
│  2. Check code quality                                           │
│  3. Review security                                              │
│  4. Validate best practices                                      │
│  5. Ensure requirements met                                      │
│  6. Make decision                                                │
│                                                                  │
│  Returns:                                                        │
│  {                                                               │
│    "decision": "APPROVED",                                       │
│    "feedback": "Excellent implementation...",                    │
│    "code_quality": "high",                                       │
│    "security_issues": []                                         │
│  }                                                               │
│                                                                  │
│  NOTE: Does NOT send BAZINGA (that's PM's job)                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Route Tech Lead Decision                         │
│                                                                  │
│  IF decision = "APPROVED": → Spawn PM for final check          │
│  IF decision = "CHANGES_REQUESTED": → Spawn Developer           │
└──────────────────────────┬──────────────────────────────────────┘
                           │ (Assuming APPROVED)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  PROJECT MANAGER AGENT (Final Check)                            │
│                                                                  │
│  1. Read pm_state.json                                           │
│  2. Check task completion:                                       │
│     • Main task: COMPLETE ✅                                    │
│  3. Verify all requirements met                                  │
│  4. Make final decision                                          │
│                                                                  │
│  Returns:                                                        │
│  {                                                               │
│    "status": "complete",                                         │
│    "message": "All tasks successfully completed",                │
│    "signal": "BAZINGA"                                           │
│  }                                                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Detect BAZINGA                                   │
│                                                                  │
│  1. Check PM response for "BAZINGA"                             │
│  2. Found: YES                                                   │
│  3. Log final success                                            │
│  4. Display completion message to user                           │
│  5. END WORKFLOW                                                 │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ↓
                    ✅ COMPLETE ✅
```

---

## Parallel Mode Flow

```
┌────────────────────────────────────────────────────────────────┐
│                    PARALLEL MODE EXECUTION                      │
│                 (Multi-Developer Flow - Up to 4)               │
└──────────────────────────┬─────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Spawn Multiple Developers IN PARALLEL            │
│                                                                  │
│  In ONE message, spawn N developers (N = 2-4):                  │
│                                                                  │
│  Task(description: "Dev Group A", prompt: [Group A tasks])      │
│  Task(description: "Dev Group B", prompt: [Group B tasks])      │
│  Task(description: "Dev Group C", prompt: [Group C tasks])      │
│  Task(description: "Dev Group D", prompt: [Group D tasks])      │
│                                                                  │
│  Each prompt includes:                                           │
│  • Task group ID                                                 │
│  • Specific tasks for that group                                 │
│  • Files to modify                                               │
│  • Feature branch name: feature/group-{ID}                       │
│  • Context about other groups (for awareness)                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
         ┌─────────────────┼─────────────────┬─────────────────┐
         │                 │                 │                 │
         ↓                 ↓                 ↓                 ↓
┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│ DEVELOPER A    │ │ DEVELOPER B    │ │ DEVELOPER C    │ │ DEVELOPER D    │
│                │ │                │ │                │ │                │
│ Group: A       │ │ Group: B       │ │ Group: C       │ │ Group: D       │
│ Branch:        │ │ Branch:        │ │ Branch:        │ │ Branch:        │
│ feature/A      │ │ feature/B      │ │ feature/C      │ │ feature/D      │
│                │ │                │ │                │ │                │
│ Implements     │ │ Implements     │ │ Implements     │ │ Implements     │
│ Auth system    │ │ User mgmt      │ │ API endpoints  │ │ DB migrations  │
│                │ │                │ │                │ │                │
│ Works on:      │ │ Works on:      │ │ Works on:      │ │ Works on:      │
│ • auth.py      │ │ • users.py     │ │ • api.py       │ │ • migrations/  │
│ • middleware.py│ │ • profiles.py  │ │ • routes.py    │ │ • models.py    │
│                │ │                │ │                │ │                │
│ No git         │ │ No git         │ │ No git         │ │ No git         │
│ conflicts!     │ │ conflicts!     │ │ conflicts!     │ │ conflicts!     │
│                │ │                │ │                │ │                │
│ Returns:       │ │ Returns:       │ │ Returns:       │ │ Returns:       │
│ READY_FOR_QA   │ │ READY_FOR_QA   │ │ BLOCKED        │ │ READY_FOR_QA   │
└────────┬───────┘ └────────┬───────┘ └────────┬───────┘ └────────┬───────┘
         │                  │                  │                  │
         └──────────────────┴──────────────────┴──────────────────┘
                                     ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Receive All 4 Responses                          │
│                                                                  │
│  Results:                                                        │
│  • Developer A: READY_FOR_QA ✅                                 │
│  • Developer B: READY_FOR_QA ✅                                 │
│  • Developer C: BLOCKED ⚠️                                      │
│  • Developer D: READY_FOR_QA ✅                                 │
│                                                                  │
│  Route Each INDEPENDENTLY:                                       │
│  • Group A: Spawn QA Expert                                      │
│  • Group B: Spawn QA Expert                                      │
│  • Group C: Spawn Tech Lead (unblock)                            │
│  • Group D: Spawn QA Expert                                      │
└──────────────────────────┬──────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┬─────────────────┐
         │                 │                 │                 │
         ↓                 ↓                 ↓                 ↓
┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│ QA EXPERT A    │ │ QA EXPERT B    │ │ TECH LEAD C    │ │ QA EXPERT D    │
│                │ │                │ │  (Unblocking)  │ │                │
│ Tests Group A  │ │ Tests Group B  │ │                │ │ Tests Group D  │
│                │ │                │ │ Provides       │ │                │
│ Integration ✅ │ │ Integration ✅ │ │ solutions to   │ │ Integration ✅ │
│ Contract ✅    │ │ Contract ✅    │ │ Developer C    │ │ Contract ✅    │
│ E2E ✅         │ │ E2E ✅         │ │                │ │ E2E ✅         │
│                │ │                │ │ Returns:       │ │                │
│ Returns: PASS  │ │ Returns: PASS  │ │ "Try X, Y, Z"  │ │ Returns: PASS  │
└────────┬───────┘ └────────┬───────┘ └────────┬───────┘ └────────┬───────┘
         │                  │                  │                  │
         │                  │                  ↓                  │
         │                  │         ┌────────────────┐          │
         │                  │         │ DEVELOPER C    │          │
         │                  │         │ (Retry)        │          │
         │                  │         │                │          │
         │                  │         │ Tries solution │          │
         │                  │         │ Gets unblocked │          │
         │                  │         │ Returns:       │          │
         │                  │         │ READY_FOR_QA   │          │
         │                  │         └────────┬───────┘          │
         │                  │                  │                  │
         │                  │                  ↓                  │
         │                  │         ┌────────────────┐          │
         │                  │         │ QA EXPERT C    │          │
         │                  │         │                │          │
         │                  │         │ Tests Group C  │          │
         │                  │         │ Returns: PASS  │          │
         │                  │         └────────┬───────┘          │
         │                  │                  │                  │
         └──────────────────┴──────────────────┴──────────────────┘
                                     ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: All Groups Passed QA                             │
│                                                                  │
│  Spawn Tech Lead for Each Group (can be parallel):              │
│  • Tech Lead for Group A                                        │
│  • Tech Lead for Group B                                        │
│  • Tech Lead for Group C                                        │
│  • Tech Lead for Group D                                        │
└──────────────────────────┬──────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┬─────────────────┐
         │                 │                 │                 │
         ↓                 ↓                 ↓                 ↓
┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│ TECH LEAD A    │ │ TECH LEAD B    │ │ TECH LEAD C    │ │ TECH LEAD D    │
│                │ │                │ │                │ │                │
│ Reviews A      │ │ Reviews B      │ │ Reviews C      │ │ Reviews D      │
│                │ │                │ │                │ │                │
│ Returns:       │ │ Returns:       │ │ Returns:       │ │ Returns:       │
│ APPROVED ✅    │ │ CHANGES REQ ⚠️ │ │ APPROVED ✅    │ │ APPROVED ✅    │
└────────┬───────┘ └────────┬───────┘ └────────┬───────┘ └────────┬───────┘
         │                  │                  │                  │
         │                  ↓                  │                  │
         │         ┌────────────────┐          │                  │
         │         │ DEVELOPER B    │          │                  │
         │         │ (Revise)       │          │                  │
         │         │                │          │                  │
         │         │ Fixes issues   │          │                  │
         │         │ → QA again     │          │                  │
         │         │ → Tech Lead    │          │                  │
         │         │ → APPROVED ✅  │          │                  │
         │         └────────┬───────┘          │                  │
         │                  │                  │                  │
         └──────────────────┴──────────────────┴──────────────────┘
                                     ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: All Groups APPROVED                              │
│                                                                  │
│  Update group_status.json:                                       │
│  • Group A: COMPLETE ✅                                         │
│  • Group B: COMPLETE ✅                                         │
│  • Group C: COMPLETE ✅                                         │
│  • Group D: COMPLETE ✅                                         │
│                                                                  │
│  Spawn PM with completion status                                │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  PROJECT MANAGER AGENT (Final Check)                            │
│                                                                  │
│  1. Read pm_state.json                                           │
│  2. Read group_status.json                                       │
│  3. Check all groups:                                            │
│     • Group A: COMPLETE ✅                                      │
│     • Group B: COMPLETE ✅                                      │
│     • Group C: COMPLETE ✅                                      │
│     • Group D: COMPLETE ✅                                      │
│  4. Check for more work:                                         │
│     • Pending groups: None                                       │
│  5. Make decision: ALL COMPLETE                                  │
│                                                                  │
│  Returns:                                                        │
│  {                                                               │
│    "status": "all_complete",                                     │
│    "completed_groups": ["A", "B", "C", "D"],                     │
│    "pending_groups": [],                                         │
│    "message": "All 4 groups successfully completed",             │
│    "signal": "BAZINGA"                                           │
│  }                                                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│  Orchestrator: Detect BAZINGA                                   │
│                                                                  │
│  1. Check PM response for "BAZINGA"                             │
│  2. Found: YES                                                   │
│  3. Log final success with all group summaries                   │
│  4. Display completion message to user                           │
│  5. END WORKFLOW                                                 │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ↓
                    ✅ COMPLETE ✅
```

---

## State Management Flow

```
┌─────────────────────────────────────────────────────────────────┐
│           HOW STATELESS AGENTS GET "MEMORY"                     │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
                                   ↓
┌──────────────────────────────────────────────────────────────────┐
│  Orchestrator: Before Spawning Any Agent                         │
│                                                                  │
│  1. Read relevant state file:                                    │
│     • pm_state.json (for PM spawns)                             │
│     • group_status.json (for status checks)                     │
│     • orchestrator_state.json (for decisions)                   │
│                                                                  │
│  2. Parse JSON contents                                          │
│  3. Include state in agent's prompt                              │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
                                   ↓
┌──────────────────────────────────────────────────────────────────┐
│  Example: Spawning PM                                            │
│                                                                  │
│  state = read("coordination/pm_state.json")                     │
│                                                                  │
│  Task(                                                           │
│    subagent_type: "general-purpose",                            │
│    description: "PM coordinating tasks",                        │
│    prompt: """                                                   │
│      You are the PROJECT MANAGER.                               │
│                                                                  │
│      PREVIOUS STATE:                                             │
│      ```json                                                     │
│      {state}                                                     │
│      ```                                                         │
│                                                                  │
│      NEW INFORMATION:                                            │
│      - Group A: Approved by Tech Lead                           │
│      - Group B: Approved by Tech Lead                           │
│                                                                  │
│      YOUR JOB:                                                   │
│      1. Read previous state                                      │
│      2. Update with new information                             │
│      3. Check completion status                                  │
│      4. Decide next action                                       │
│      5. Write updated state back to file                         │
│      6. Return decision                                          │
│    """                                                           │
│  )                                                               │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
                                   ↓
┌──────────────────────────────────────────────────────────────────┐
│  PM Agent: Process with State                                    │
│                                                                  │
│  1. PM receives prompt with previous state                       │
│  2. PM parses state JSON                                         │
│  3. PM understands context from previous runs                    │
│  4. PM processes new information                                 │
│  5. PM makes decisions based on full history                     │
│  6. PM updates state:                                            │
│                                                                  │
│     old_state = parse(previous_state)                           │
│     new_state = update_state(old_state, new_info)              │
│     write_file("coordination/pm_state.json", new_state)         │
│                                                                  │
│  7. PM returns decision to orchestrator                          │
│  8. PM instance dies                                             │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
                                   ↓
┌──────────────────────────────────────────────────────────────────┐
│  Result: PM Has "Memory"                                         │
│                                                                  │
│  Next time PM is spawned:                                        │
│  • Orchestrator reads updated pm_state.json                     │
│  • New PM instance receives updated state                        │
│  • New PM sees full history                                      │
│  • Behaves as if it remembered everything                        │
│                                                                  │
│  This pattern works because:                                     │
│  ✅ State persists in file system                               │
│  ✅ Always passed to new instances                              │
│  ✅ Agent updates before dying                                  │
│  ✅ Orchestrator coordinates handoff                            │
└──────────────────────────────────────────────────────────────────┘
```

---

## Routing Decision Tree

```
┌─────────────────────────────────────────────────────────────────┐
│              ORCHESTRATOR ROUTING LOGIC                         │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
                                   ↓
                    ┌──────────────────────────┐
                    │ Agent Returns Response   │
                    └──────────┬───────────────┘
                               │
                ┌──────────────┴──────────────┐
                │ Which agent responded?      │
                └──────────┬──────────────────┘
                           │
         ┌─────────────────┼─────────────────┬──────────────┐
         │                 │                 │              │
         ↓                 ↓                 ↓              ↓
┌────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   DEVELOPER    │ │  QA EXPERT   │ │  TECH LEAD   │ │     PM       │
└────────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
         │                │                │                │
         ↓                ↓                ↓                ↓

┌─────────────────────────────────────────────────────────────────┐
│ DEVELOPER Response Routing                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ IF status == "READY_FOR_QA":                                     │
│    log("Developer ready, spawning QA Expert")                   │
│    spawn_qa_expert(group_id, dev_result)                        │
│                                                                  │
│ ELSE IF status == "BLOCKED":                                     │
│    log("Developer blocked, spawning Tech Lead for unblocking")  │
│    spawn_tech_lead_unblock(group_id, blocker_details)           │
│                                                                  │
│ ELSE IF status == "INCOMPLETE":                                  │
│    log("Developer incomplete, spawning Tech Lead for guidance") │
│    spawn_tech_lead_guidance(group_id, incomplete_reason)        │
│                                                                  │
│ ELSE IF status == "ERROR":                                       │
│    log("Developer error, spawning Tech Lead for troubleshoot")  │
│    spawn_tech_lead_troubleshoot(group_id, error_details)        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ QA EXPERT Response Routing                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ IF result == "PASS":                                             │
│    log("QA passed, spawning Tech Lead for review")              │
│    spawn_tech_lead_review(                                       │
│      group_id,                                                   │
│      dev_result,                                                 │
│      qa_result                                                   │
│    )                                                             │
│                                                                  │
│ ELSE IF result == "FAIL":                                        │
│    log("QA failed, sending back to Developer")                  │
│    spawn_developer_fix(                                          │
│      group_id,                                                   │
│      qa_failures,                                                │
│      failed_tests                                                │
│    )                                                             │
│                                                                  │
│ ELSE IF result == "BLOCKED":                                     │
│    log("QA blocked (e.g., env issue), escalate to Tech Lead")   │
│    spawn_tech_lead_unblock_qa(group_id, qa_blocker)             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ TECH LEAD Response Routing                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ IF decision == "APPROVED":                                       │
│    log("Tech Lead approved group")                              │
│    update_group_status(group_id, "COMPLETE")                    │
│    if all_groups_complete():                                     │
│       log("All groups done, spawning PM for final check")       │
│       spawn_pm_final_check()                                     │
│    else:                                                         │
│       log("Other groups still in progress, continue monitoring")│
│                                                                  │
│ ELSE IF decision == "CHANGES_REQUESTED":                         │
│    log("Tech Lead requested changes, back to Developer")        │
│    spawn_developer_revise(                                       │
│      group_id,                                                   │
│      tech_lead_feedback                                          │
│    )                                                             │
│                                                                  │
│ ELSE IF decision == "UNBLOCKED":                                 │
│    log("Tech Lead provided unblocking guidance")                │
│    spawn_developer_retry(                                        │
│      group_id,                                                   │
│      solutions_provided                                          │
│    )                                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ PM Response Routing                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ IF response contains "BAZINGA":                                  │
│    log("PM sent BAZINGA - workflow complete!")                  │
│    log_final_summary()                                           │
│    display_completion_message_to_user()                          │
│    END_WORKFLOW()                                                │
│                                                                  │
│ ELSE IF response contains next_assignments:                      │
│    log("PM assigned next batch of task groups")                 │
│    groups = response.next_assignments                            │
│    spawn_multiple_developers(groups)                             │
│                                                                  │
│ ELSE IF response contains "MODE_DECISION":                       │
│    mode = response.mode                                          │
│    if mode == "simple":                                          │
│       spawn_single_developer(response.task_group)                │
│    else:                                                         │
│       spawn_multiple_developers(response.task_groups)            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Failure Recovery Flows

### Developer Blocked Flow

```
┌──────────────────────────────────────────────┐
│ Developer Status: BLOCKED                    │
│ Blocker: "Database connection failing"       │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Orchestrator: Detect Blocker                 │
│ Action: Spawn Tech Lead for unblocking       │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Tech Lead: Analyze Blocker                   │
│                                              │
│ Provides 3 specific solutions:               │
│ 1. Check DATABASE_URL in .env                │
│ 2. Verify database is running: docker ps    │
│ 3. Try connection test: psql -U user -h...  │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Orchestrator: Send Solutions to Developer    │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Developer: Try Solutions                     │
│                                              │
│ 1. Checks .env → DATABASE_URL missing!       │
│ 2. Adds correct DATABASE_URL                 │
│ 3. Connection works!                         │
│ 4. Continues implementation                  │
│ 5. Returns: READY_FOR_QA                     │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
         ✅ Unblocked Successfully
```

### QA Tests Fail Flow

```
┌──────────────────────────────────────────────┐
│ QA Expert: Tests FAILED                      │
│                                              │
│ Failures:                                    │
│ • test_auth_invalid_token: 500 (expect 401) │
│ • test_rate_limiting: Not enforced          │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Orchestrator: Send Failures to Developer     │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Developer: Fix Issues                        │
│                                              │
│ 1. Fix invalid token handling → Return 401  │
│ 2. Add rate limiting decorator               │
│ 3. Re-run unit tests → All pass              │
│ 4. Commit fixes                              │
│ 5. Returns: READY_FOR_QA                     │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Orchestrator: Spawn QA Again                 │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ QA Expert: Re-test                           │
│                                              │
│ • test_auth_invalid_token: ✅ PASS           │
│ • test_rate_limiting: ✅ PASS                │
│                                              │
│ Returns: PASS                                │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
         ✅ Tests Fixed and Passing
```

### Stuck Detection Flow

```
┌──────────────────────────────────────────────┐
│ Orchestrator: Track Attempts                 │
│                                              │
│ Group A:                                     │
│ • dev_attempts: 6 (exceeds threshold of 5)  │
│ • Same issue keeps recurring                 │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Orchestrator: Detect Stuck Condition         │
│ Action: Escalate to PM                       │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ PM: Analyze Stuck Situation                  │
│                                              │
│ Reviews:                                     │
│ • Original task definition                   │
│ • Developer attempts                         │
│ • Tech Lead feedback                         │
│ • Pattern: Task too complex                  │
│                                              │
│ Decision: Break into smaller tasks           │
│ • Group A1: Core auth (simpler)              │
│ • Group A2: Advanced features (later)        │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Orchestrator: Spawn Dev with Simpler Task    │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────┐
│ Developer: Implement Simpler Version         │
│ Success! Returns: READY_FOR_QA               │
└──────────────────┬───────────────────────────┘
                   │
                   ↓
         ✅ Unstuck via Task Simplification
```

---

## Performance Metrics Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRACKING PERFORMANCE                         │
└──────────────────────────────────┬──────────────────────────────┘
                                   │
┌──────────────────────────────────┴──────────────────────────────┐
│ Orchestrator: Track Per-Group Metrics                           │
│                                                                  │
│ For each group:                                                  │
│ {                                                                │
│   "group_id": "A",                                               │
│   "start_time": "2025-01-06T10:00:00Z",                         │
│   "end_time": "2025-01-06T10:15:00Z",                           │
│   "total_duration_minutes": 15,                                  │
│   "iterations": {                                                │
│     "developer": 2,                                              │
│     "qa": 1,                                                     │
│     "tech_lead": 1                                               │
│   },                                                             │
│   "first_pass_approval": false,                                  │
│   "quality_score": 8.5                                           │
│ }                                                                │
│                                                                  │
│ Aggregate Metrics:                                               │
│ {                                                                │
│   "total_duration_minutes": 26,                                  │
│   "groups_completed": 4,                                         │
│   "parallel_efficiency": 1.7x (vs sequential),                  │
│   "first_pass_rate": "75%" (3/4 groups),                        │
│   "average_iterations_per_group": 4.5                            │
│ }                                                                │
└──────────────────────────────────────────────────────────────────┘
```

---

## Summary

These workflows demonstrate:

1. **Adaptive Mode Selection**: PM intelligently chooses simple vs parallel mode
2. **State Management**: Stateless agents gain "memory" via state files
3. **Independent Routing**: Each group flows through dev→QA→tech lead independently
4. **Failure Recovery**: Multiple strategies for handling blockers and failures
5. **BAZINGA from PM**: Only PM sends completion signal after all groups done
6. **Performance Tracking**: Metrics collected throughout for optimization

The visual flows show how V4 scales from simple single-developer tasks to complex multi-group parallel execution while maintaining quality through QA and Tech Lead review gates.
