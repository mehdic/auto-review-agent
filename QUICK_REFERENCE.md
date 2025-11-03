# 🚀 Quick Reference: Spec-Based Agent System

## Before and After

### ❌ OLD WAY (Free-form tasks)
```bash
./launch-agents.sh /project "Create a REST API for user authentication with JWT tokens"
```
- Task is interpreted by planner
- Requirements are inferred
- Success is vague
- Testing is ad-hoc

### ✅ NEW WAY (Spec-based)
```bash
./launch-agents-from-spec.sh /project 001
```
- Task is read from `specs/001-xxx/spec.md`
- Requirements are explicit (acceptance scenarios)
- Success is measurable (acceptance scenarios pass)
- Testing is built-in

---

## 3-Step Setup

### Step 1: Initialize Project
```bash
./setup.sh /path/to/project
```
Creates:
- `specs/` folder
- `coordination/` folder
- Sample spec.md template

### Step 2: Add Your Specs
Copy spec files to:
```
specs/001-feature-name/spec.md
specs/002-feature-name/spec.md
specs/007-latest-feature/spec.md
```

### Step 3: Launch Agents
```bash
./launch-agents-from-spec.sh /path/to/project 001
```

---

## Spec.md Template

```markdown
# Feature Specification: [Feature Name]

**Feature Branch**: `001-feature-name`
**Created**: 2025-11-03
**Status**: Draft

## User Scenarios & Testing

### User Story 1 - [Story Name] (Priority: P1)

[Why this matters]

**Acceptance Scenarios**:

1. **Given** user visits app
   **When** they click signup
   **Then** signup form appears

2. **Given** user fills signup form
   **When** they click submit
   **Then** account created, email sent

---

## Success Criteria

- **SC-001**: 95% signup completion rate
- **SC-002**: Email delivered within 1 minute

## Constraints

**Out of Scope for V1**
- OAuth integration
- Multi-language support

**Technical Constraints**
- API responses under 100ms
- Support 1000 concurrent users
```

---

## How Agents Work with Specs

### 🎯 PLANNER AGENT

**Phase 1: Read & Analyze**
- Opens spec.md
- Extracts acceptance scenarios (the real requirements)
- Reads success criteria
- Checks constraints

**Phase 2: Propose**
- Creates 2-3 implementation approaches
- Each approach shows how to implement ALL acceptance scenarios
- Includes timeline, risk, tech choices

**Phase 3: Implement**
- For EACH acceptance scenario in spec:
  - Write code to implement it
  - Test it
  - Mark as COMPLETE
- Implementation is DONE when all scenarios pass

### ✅ REVIEWER AGENT

**Phase 1: Receive**
- Gets proposals from planner
- Reads spec analysis

**Phase 2: Evaluate**
- Do all acceptance scenarios have solutions? ✓
- Are hard constraints respected? ✓
- Can success criteria be measured? ✓
- Is timeline realistic? ✓

**Phase 3: Approve**
- Choose best approach
- Give implementation instructions
- List acceptance scenarios in order

---

## Monitoring Progress

### Watch in Real-Time
```bash
# See agent logs
tail -f coordination/logs/notifications.log

# Check current work
cat coordination/active_work_registry.json | jq .

# See proposal status
cat coordination/task_proposals.json | jq .status
```

### What to Look For
- `PLANNER: Analyzing spec` → Reading spec
- `PLANNER: Created 3 approaches` → Planning phase done
- `REVIEWER: Decision: APPROVED` → Reviewer chose approach
- `PLANNER: SCENARIO X COMPLETE` → Scenario implemented ✓
- `PLANNER: All scenarios passing` → Implementation done!

---

## File Structure

### Project Layout
```
project/
├── specs/
│   ├── 001-auth/
│   │   └── spec.md
│   ├── 002-payments/
│   │   └── spec.md
│   └── 003-analytics/
│       └── spec.md
└── coordination/
    ├── task_proposals.json       ← Proposals and status
    ├── active_work_registry.json ← Current work
    ├── completed_work_log.json   ← Finished work
    ├── messages/
    │   ├── planner_to_reviewer.json
    │   └── reviewer_to_planner.json
    └── logs/
        ├── notifications.log     ← Agent activity
        └── agent_activity.log
```

### Archive Contents
```
agent-system-spec-integrated.zip/
├── setup.sh                      ← Initialize project
├── launch-agents-from-spec.sh   ← Launch with spec
├── launch-agents.sh             ← Launch with free-form task
├── README.md                    ← Full documentation
├── SPEC_BASED_WORKFLOW.md      ← Spec workflow guide
└── prompts/
    ├── planner_agent_spec.txt   ← Spec-aware planner
    └── reviewer_agent_spec.txt  ← Spec-aware reviewer
```

---

## Usage Examples

### Example 1: New Project
```bash
# Initialize
./setup.sh ~/my-app

# Add your spec
cp my-specs/001-user-auth.md ~/my-app/specs/001-user-auth/spec.md

# Launch
./launch-agents-from-spec.sh ~/my-app 001

# Watch in tmux
# Ctrl+b 0 → Planner window
# Ctrl+b 1 → Reviewer window
# Ctrl+b 2 → Monitor window
```

### Example 2: Multiple Features
```bash
# List all features
./launch-agents-from-spec.sh ~/my-app

# Output:
# ✓ 001-user-auth - User Authentication
# ✓ 002-payments - Payment Processing
# ✓ 007-analytics - Analytics Dashboard

# Work on feature 002
./launch-agents-from-spec.sh ~/my-app 002
```

### Example 3: Free-Form Task (Legacy)
```bash
# Still works for non-spec work
./launch-agents.sh ~/my-app "Add error handling middleware"
```

---

## Acceptance Scenarios = Your Tests

Each scenario in the spec is a **requirement that must pass**:

```markdown
**Given** user is not logged in
**When** they visit /dashboard
**Then** redirected to /login page
```

This means:
- You must write code that makes this happen
- You must test this scenario
- Implementation not done until this passes

---

## Success Metrics (SC-NNN)

Define what "done" means:

```
SC-001: 95% of signup attempts complete successfully
SC-002: Email confirmation delivered within 1 minute
SC-003: Dashboard loads in under 100ms for 99% of requests
SC-004: Zero signup errors in production for 7 days
```

These become the implementation goals.

---

## Constraints Shape Implementation

```markdown
## Constraints

**Out of Scope for V1**
- OAuth (only JWT)
- Admin panel
- Mobile app

**Technical Constraints**
- Must support 1000 concurrent users
- API calls under 100ms
- Only PostgreSQL (no other databases)

**Business Constraints**
- Budget: $50K for infrastructure
- Timeline: 8 weeks
```

These limit the planner's choices.

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Specs folder not found" | Run `./setup.sh /project` first |
| "No spec folders found" | Add `specs/001-xxx/spec.md` files |
| "Agents seem stuck" | Check `tail -f coordination/logs/notifications.log` |
| "Proposals are poor quality" | Make acceptance scenarios more specific |
| "Want to use free-form mode" | Use `./launch-agents.sh /project "task"` instead |
| "Want to customize prompts" | Edit `prompts/planner_agent_spec.txt` |

---

## Key Differences

| Aspect | Free-Form | Spec-Based |
|--------|-----------|-----------|
| Input | Task description | spec.md file |
| Requirements | Interpreted | Explicit (scenarios) |
| Success | "Looks good" | All scenarios pass |
| Testing | Ad-hoc | Built-in (scenarios) |
| Scope | Inferred | Defined in constraints |
| Metrics | Created | Defined (SC-NNN) |

---

## Next Steps

1. **Extract the archive**
   ```bash
   unzip agent-system-spec-integrated.zip
   cd agent-system-spec-integrated
   ```

2. **Set up your first project**
   ```bash
   ./setup.sh ~/my-project
   ```

3. **Add a spec file**
   ```bash
   # Copy your spec.md to:
   # ~/my-project/specs/001-feature-name/spec.md
   ```

4. **Launch the agents**
   ```bash
   ./launch-agents-from-spec.sh ~/my-project 001
   ```

5. **Watch the magic happen!** ✨

---

**Remember**: Your acceptance scenarios ARE your test cases! 🚀
