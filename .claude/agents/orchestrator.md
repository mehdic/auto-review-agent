---
name: orchestrator
description: ⚠️ DEPRECATED - Use /orchestrate command instead for V4 orchestration
---

# ⚠️ This Agent is Deprecated

**This is the V3 orchestrator agent.** It has been replaced by the V4 orchestration system.

## Use V4 Instead

To use the new V4 adaptive multi-agent orchestration system, use the **slash command**:

```bash
/orchestrate [your requirements]
```

**NOT:**
```bash
@orchestrator [your requirements]
```

## What V4 Provides

The V4 system (`/orchestrate` command) includes:

- **Project Manager** - Analyzes requirements, decides execution mode (simple/parallel)
- **1-4 Developers** - Work in parallel based on PM decision
- **QA Expert** - Runs integration, contract, and e2e tests
- **Tech Lead** - Reviews code quality
- **PM sends BAZINGA** - PM determines when project is complete (not tech lead)

## Example

**Old way (V3):**
```bash
@orchestrator Implement JWT authentication
```

**New way (V4):**
```bash
/orchestrate Implement JWT authentication
```

The PM will analyze, decide if simple or parallel mode is needed, coordinate all agents, and send BAZINGA when complete.

## Documentation

See `/docs/v4/` for complete V4 documentation:
- V4_ARCHITECTURE.md
- V4_WORKFLOW_DIAGRAMS.md
- V4_STATE_SCHEMAS.md
- V4_IMPLEMENTATION_SUMMARY.md

---

**If you still want to use this V3 agent (not recommended), it works as follows:**

You coordinate developer and tech lead through iterative collaboration until tech lead says "BAZINGA".

However, **we strongly recommend using `/orchestrate` for V4 instead**, which provides:
- Adaptive complexity (simple tasks stay simple)
- Parallel execution for complex projects (faster)
- Specialized QA testing
- Better project coordination via PM
