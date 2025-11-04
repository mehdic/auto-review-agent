## Summary

This PR fixes the stuck planner implementation issue and completely reimplements the agent loops to be universal and robust.

### Problems Solved

1. **Stuck Planner Issue**: Status shows "implementing" but no Claude process running
   - Root cause: `planner-loop.sh` updated status but exited without starting implementation
   - Fix: Complete rewrite with continuous loop

2. **Premature Exits**: Old loops would exit after one Claude call, regardless of completion
   - Fix: Loops now continue until spec success criteria are verified

3. **Task-Specific Loops**: Old loops were hardcoded for specific tasks
   - Fix: New generic loops work with ANY spec.md file

### What's New

#### 1. Generic Agent Loops
- ✅ `planner-loop.sh` - Continuous implementation until verified complete
- ✅ `reviewer-loop.sh` - Monitors and verifies until all work done
- ✅ `check-completion.sh` - Universal completion verifier

#### 2. Immediate Fixes
- ✅ `wake-up-planner.sh` - Wakes stuck planner in existing tmux session
- ✅ `nuclear-fix.sh` - Force implementation regardless of state
- ✅ `diagnose-stuck.sh` - Diagnostic tool for troubleshooting

#### 3. Documentation
- ✅ `GENERIC_LOOPS_GUIDE.md` - Complete guide for new generic loops
- ✅ `FIX_STUCK_PLANNER.md` - Troubleshooting guide

### Key Features

**Generic Loop Architecture:**
- Parses "Definition of Done" and "Success Criteria" from any spec.md
- Multiple iterations if needed to achieve all criteria
- Completion verification before exit (no premature exits)
- Reviewer independently verifies completion
- Works with tests, features, documentation, any task

**Flow:**
```
Loop continuously:
  1. Create proposals (if needed)
  2. Wait for approval
  3. Update status to "implementing"
  4. Run implementation
  5. Verify completion against spec
  6. If complete → exit(0)
  7. If not → wait 120s and iterate
```

### Benefits

- ✅ No more stuck implementations (continuous loop)
- ✅ No more premature exits (verified completion)
- ✅ Universal solution (any spec.md format)
- ✅ Fully autonomous (runs until actually done)
- ✅ Transparent (iteration counters, status logging)
- ✅ Safe (double verification by planner and reviewer)

### Testing

Works with any spec that includes:
```markdown
## Success Criteria
- SC-001: [Measurable criterion]

## Definition of Done
✅ [Checkable item]
```

### Files Changed

**Core Loops:**
- `planner-loop.sh` - Rewritten as generic continuous loop
- `reviewer-loop.sh` - Rewritten with verification
- `check-completion.sh` - New universal completion checker

**Fix Scripts:**
- `wake-up-planner.sh` - Wake existing planner (tmux-aware)
- `nuclear-fix.sh` - Force implementation
- `diagnose-stuck.sh` - Diagnostics

**Documentation:**
- `GENERIC_LOOPS_GUIDE.md` - Complete usage guide
- `FIX_STUCK_PLANNER.md` - Troubleshooting

**Legacy (kept for reference):**
- `planner-loop-continuous.sh` - Alternative implementation
- `reviewer-loop-continuous.sh` - Alternative implementation
- `planner-loop-fixed.sh` - Old fix attempt
- `direct-implement.sh` - Direct implementation starter

### Migration

No changes needed! Just restart agents:
```bash
tmux kill-session -t agent_system_spec
./launch-agents-from-spec.sh 999-fix-remaining-tests
```

The new loops will run until 183/183 tests pass, verified.

### Immediate Action (For Stuck Planner)

If planner is currently stuck:
```bash
git pull origin claude/fix-planner-implementation-stuck-011CUnivgURzCzxghnaLrUNX
./wake-up-planner.sh
```

This wakes the existing planner without creating new processes.

---

## Test Plan

- [x] Test wake-up-planner.sh with existing tmux session
- [x] Verify generic loops work with spec 999-fix-remaining-tests
- [x] Test check-completion.sh parses spec correctly
- [x] Verify continuous loop iterations
- [x] Test completion verification

---

**This is a major improvement to the agent system architecture. The loops are now truly autonomous and universal.**
