# Generic Agent Loops - Universal Spec Implementation

## Overview

The agent system now uses **generic loops** that work with **ANY** spec.md file, not just specific tasks. The loops automatically:

1. Parse the spec file's "Definition of Done" and "Success Criteria"
2. Create implementation proposals
3. Review and approve proposals
4. Implement continuously until ALL criteria are met
5. Verify completion before exiting

## Key Components

### 1. `check-completion.sh`
**Purpose:** Generic completion checker that works with any spec

**Usage:**
```bash
./check-completion.sh <project_path> <spec_file> [verbose]
```

**How it works:**
- Reads the spec file
- Extracts "Definition of Done" and "Success Criteria" sections
- Uses Claude to evaluate if current state meets those criteria
- Returns exit code 0 if complete, 1 if incomplete

**Example:**
```bash
./check-completion.sh /Users/me/MyProject specs/123-feature/spec.md true
# Returns: COMPLETE or INCOMPLETE: reason
```

---

### 2. `planner-loop.sh` (Generic Version)
**Purpose:** Continuous planning and implementation until completion

**Features:**
- ✅ Works with ANY spec.md format
- ✅ Runs continuously until success criteria met
- ✅ Never exits prematurely
- ✅ Uses check-completion.sh to verify work is done
- ✅ Handles multiple iterations if needed

**Flow:**
1. **Iteration Loop** (continues until complete)
   - Phase 1: Create proposals (if needed)
   - Phase 2: Wait for approval
   - Phase 3: Update status to "implementing"
   - Phase 4: Run implementation with Claude
   - Phase 5: Check completion with check-completion.sh
   - If complete → update to "completed" and exit
   - If not complete → wait 120s and repeat

**What it doesn't hardcode:**
- ❌ Specific test counts (like "183 tests")
- ❌ Specific build commands
- ❌ Specific success criteria
- ✅ Everything is read from the spec dynamically

---

### 3. `reviewer-loop.sh` (Generic Version)
**Purpose:** Reviews proposals and monitors implementation progress

**Features:**
- ✅ Works with ANY spec.md format
- ✅ Runs continuously until work verified complete
- ✅ Monitors implementation progress
- ✅ Verifies completion before exiting
- ✅ Can reset status if completion claim is false

**States it handles:**
- `awaiting_review` → Reviews and approves proposals
- `implementing` → Monitors for activity (file changes)
- `approved` → Waits for implementation to start
- `completed` → Verifies with check-completion.sh before exiting

**Safety feature:**
If status is "completed" but check-completion.sh says work isn't done, reviewer resets status to "implementing" and planner continues.

---

## How It Works With Any Spec

### Example 1: Test Fixing Spec (999-fix-remaining-tests)
**Spec says:**
```markdown
## Definition of Done
✅ All 183 tests passing
✅ No @Ignored tests
✅ Clean test output
```

**How loops handle it:**
- Planner creates proposals for fixing tests
- Reviewer approves best approach
- Planner implements, running mvn test periodically
- check-completion.sh verifies all 183 tests pass
- Loops exit when verified

---

### Example 2: Feature Implementation Spec
**Spec says:**
```markdown
## Success Criteria
- SC-001: User authentication API endpoint working
- SC-002: JWT tokens generated correctly
- SC-003: Integration tests pass
```

**How loops handle it:**
- Planner creates proposals for implementing auth
- Reviewer approves approach
- Planner implements feature
- check-completion.sh verifies:
  - API endpoint exists and works
  - JWT functionality correct
  - Integration tests passing
- Loops exit when verified

---

### Example 3: Documentation Spec
**Spec says:**
```markdown
## Definition of Done
✅ README.md updated with new features
✅ API documentation complete
✅ Examples added
```

**How loops handle it:**
- Planner proposes documentation structure
- Reviewer approves
- Planner writes docs
- check-completion.sh verifies all files exist and are complete
- Loops exit when verified

---

## Key Differences From Old Loops

| Aspect | Old Loops | New Generic Loops |
|--------|-----------|-------------------|
| **Completion** | Exit after one Claude call | Continue until spec criteria met |
| **Verification** | No verification | Use check-completion.sh |
| **Spec Support** | Hardcoded for specific tasks | Work with ANY spec.md |
| **Iterations** | Single pass | Multiple iterations if needed |
| **Exit Condition** | After implementation runs | After verification passes |

---

## Usage

### Starting Agents (No Changes)
```bash
cd /Users/mchaouachi/agent-system
./launch-agents-from-spec.sh 999-fix-remaining-tests
```

The launch script will use the new generic loops automatically.

### Manual Testing
```bash
# Test completion checker
./check-completion.sh \
  /Users/mchaouachi/IdeaProjects/StockMonitor \
  specs/999-fix-remaining-tests/spec.md \
  true

# Test planner loop
./planner-loop.sh \
  /Users/mchaouachi/IdeaProjects/StockMonitor \
  specs/999-fix-remaining-tests/spec.md \
  "fix-remaining-tests" \
  prompts/planner_agent_spec.txt

# Test reviewer loop
./reviewer-loop.sh \
  /Users/mchaouachi/IdeaProjects/StockMonitor \
  specs/999-fix-remaining-tests/spec.md \
  "fix-remaining-tests" \
  prompts/reviewer_agent_spec.txt
```

---

## Benefits

### 1. **Truly Autonomous**
Agents don't stop until work is actually complete, verified against the spec.

### 2. **Universal**
Write any spec.md with "Definition of Done" and the loops will handle it.

### 3. **Reliable**
Completion is verified, not assumed. If Claude claims work is done but it isn't, loops continue.

### 4. **Transparent**
Logs show iteration count, status transitions, and completion checks.

### 5. **Safe**
Multiple verification layers prevent premature exit:
- Planner checks completion
- Reviewer independently verifies
- Both use check-completion.sh

---

## Creating a New Spec

To create a spec that works with generic loops:

### 1. Required Sections

```markdown
## Success Criteria
- SC-001: [Specific measurable criterion]
- SC-002: [Another criterion]
...

## Definition of Done
✅ [Checkable item 1]
✅ [Checkable item 2]
...
```

### 2. Make Criteria Verifiable

Good:
- ✅ "All 183 tests passing" (can run tests to verify)
- ✅ "API endpoint /users returns 200" (can test endpoint)
- ✅ "Build succeeds without errors" (can run build)

Bad:
- ❌ "Code is clean" (subjective, hard to verify)
- ❌ "Good performance" (vague)
- ❌ "Should work" (not specific)

### 3. Include Implementation Guidance

```markdown
## Agent Instructions
**CRITICAL:**
- Work autonomously - do NOT ask for permission between fixes
- [Specific guidance for this task]
- Continue until all success criteria met
```

---

## Troubleshooting

### Loops Keep Running Forever

**Problem:** Loops don't detect completion

**Solutions:**
1. Check spec has clear "Definition of Done"
2. Run check-completion.sh manually to see what's failing
3. Verify success criteria are actually achievable
4. Check logs for what Claude is reporting

### Loops Exit Too Early

**Problem:** Work incomplete but loops exit

**Solution:** This should not happen with new loops! If it does:
1. Check check-completion.sh is working
2. Verify reviewer is calling check-completion.sh
3. Check logs for verification step

### check-completion.sh Says INCOMPLETE

**Problem:** Work appears done but checker disagrees

**Solutions:**
1. Run checker with verbose flag to see reason
2. Compare actual state vs spec requirements
3. May need to continue implementation
4. Spec criteria might be too strict

---

## Migration Notes

If you have old agents running:

1. **Stop them:** `tmux kill-session -t agent_system_spec`
2. **Update scripts:** Already done - planner-loop.sh and reviewer-loop.sh are updated
3. **Restart:** `./launch-agents-from-spec.sh <spec-name>`

The new loops are **backward compatible** - they'll work with old specs too, just better!

---

## Advanced: Custom Completion Checks

For complex specs, you can create a custom completion checker:

```bash
# Create specs/my-feature/check-completion.sh
#!/bin/bash
PROJECT_PATH="$1"

# Custom verification logic
if [[ $(my_test_command) == "success" ]]; then
    echo "COMPLETE"
    exit 0
else
    echo "INCOMPLETE: my_test_command failed"
    exit 1
fi
```

Then modify planner-loop.sh to use your custom checker instead of the generic one.

---

## Summary

The new generic loops make the agent system **truly universal**. Write any spec with clear success criteria, and the agents will:

1. ✅ Understand what needs to be done
2. ✅ Create proposals
3. ✅ Get approval
4. ✅ Implement systematically
5. ✅ Verify completion
6. ✅ Exit when actually done

**No more stuck implementations. No more premature exits. Just reliable, continuous work until the job is done.**
