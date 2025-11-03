# 🎯 Spec-Based Agent Workflow

This system has been **integrated with your spec.md file structure**. Instead of giving agents free-form task descriptions, they now read feature specifications from your `specs/` folder and create implementation plans based on acceptance scenarios and success criteria.

## 📋 How It Works

### Your Spec Structure

```
project/
└── specs/
    ├── 001-initial-feature/
    │   └── spec.md
    ├── 002-feature-name/
    │   └── spec.md
    └── 007-latest-feature/
        └── spec.md
```

### Workflow

1. **Planner Agent** reads `specs/NNN-feature-name/spec.md`
2. **Planner** analyzes:
   - User stories and their priority (P1-P5)
   - Acceptance scenarios (Given/When/Then requirements)
   - Success criteria (measurable metrics)
   - Constraints (scope, technical, regulatory, UX, business)
3. **Planner** creates 2-3 implementation approaches tailored to the spec
4. **Reviewer** evaluates each approach against:
   - All acceptance scenarios covered? ✓
   - Hard constraints respected? ✓
   - Success criteria measurable? ✓
5. **Reviewer** approves the best approach with detailed implementation instructions
6. **Planner** implements using acceptance scenarios as the test checklist
7. Implementation considered complete when all acceptance scenarios pass

## 🚀 Quick Start

### Step 1: Initialize Your Project

```bash
./setup.sh /path/to/your/project
```

This creates:
- `specs/` folder with sample spec.md
- `coordination/` folder with agent communication files

### Step 2: Add Your Specs

Copy your feature specs to the specs folder:

```bash
cp your-spec.md /path/to/project/specs/001-feature-name/spec.md
```

### Step 3: Launch Agents for a Specific Feature

```bash
# List available features
./launch-agents-from-spec.sh /path/to/project

# Launch for specific feature
./launch-agents-from-spec.sh /path/to/project 001
```

This launches the agents in tmux with 3 windows:
- **Planner** (Ctrl+b 0) - Analyzes spec and implements
- **Reviewer** (Ctrl+b 1) - Reviews proposals and approves
- **Monitor** (Ctrl+b 2) - Shows coordination file status

## 📖 Spec.md Format

Your spec file should include these sections:

```markdown
# Feature Specification: [Name]

**Feature Branch**: `001-feature-name`
**Created**: 2025-11-03
**Status**: Draft
**Input**: User description: [Brief description]

## User Scenarios & Testing

### User Story 1 - [Name] (Priority: P1)

[Description]

**Acceptance Scenarios**:

1. **Given** [state], **When** [action], **Then** [result]
2. **Given** [state], **When** [action], **Then** [result]

---

## Success Criteria

**Adoption**
- **SC-001**: [Measurable metric]
- **SC-002**: [Measurable metric]

## Constraints

**Out of Scope for V1**
- [Item]
- [Item]

**Technical Constraints**
- [Constraint]
- [Constraint]
```

### Acceptance Scenarios Are Your Tests

Each scenario in the format:
- **Given** [initial state]
- **When** [user action]
- **Then** [expected result]

...becomes a requirement that the planner must implement and test. The implementation is considered complete when all acceptance scenarios work.

## 🎯 How Agents Use Your Specs

### Planner Agent

1. **Reading Phase**
   - Opens `spec.md`
   - Identifies all user stories and their priority
   - Lists all acceptance scenarios (this is the true requirement)
   - Reads constraints (defines scope boundaries)

2. **Analysis Phase**
   - Decomposes feature into components
   - Maps acceptance scenarios to code modules
   - Identifies dependencies and execution order
   - Checks if any hard constraints would prevent certain approaches

3. **Proposal Phase**
   - Creates 2-3 approaches, each addressing all acceptance scenarios
   - For each approach, explains:
     - Which components need building
     - How acceptance scenarios map to code
     - Timeline estimate
     - Risk assessment
     - Tech stack choices

4. **Implementation Phase**
   - **Uses acceptance scenarios as test checklist**
   - For each scenario, implements required code
   - Tests each scenario before moving to next
   - Logs which code implements which scenario
   - Builds logging/metrics for success criteria

### Reviewer Agent

1. **Receives** proposals with spec analysis
2. **Verifies** all acceptance scenarios can be implemented
3. **Checks** all hard constraints are respected
4. **Evaluates** timeline realism
5. **Approves** the best approach with implementation instructions
6. **Instructions** include:
   - Priority order for implementation
   - Scenario implementation order (by dependency)
   - Critical success factors
   - Testing requirements

## 📊 Example Workflow

### Step 1: Spec File

```markdown
# Feature Specification: User Authentication

**Feature Branch**: `001-user-authentication`
**Status**: Draft

## User Scenarios & Testing

### User Story 1 - User Signup (Priority: P1)

An individual investor signs up, verifies their email, and creates an account.

**Acceptance Scenarios**:

1. **Given** a new user visits the app
   **When** they sign up with valid email and password
   **Then** account created, confirmation email sent, session started

2. **Given** user received confirmation email
   **When** they click the link
   **Then** email verified, can log in

...

## Success Criteria

- **SC-001**: 95% of signup attempts complete successfully
- **SC-002**: Email delivery within 1 minute
```

### Step 2: Planner Analysis

Planner reads spec and creates proposals:

```
APPROACH 1: JWT + Email verification
- Backend: Auth API with JWT tokens
- Database: Users table, verification tokens
- Frontend: Signup form, email verification page
- Scenarios covered: 2/2
- Timeline: 40 hours
- Pros: Stateless, scales well
- Cons: Token management complexity

APPROACH 2: Session-based auth
- Backend: Auth service with sessions
- Database: Users table, sessions table
- Frontend: Signup form, email verification page
- Scenarios covered: 2/2
- Timeline: 35 hours
- Pros: Simpler, familiar pattern
- Cons: Session storage overhead

...
```

### Step 3: Reviewer Approval

Reviewer analyzes proposals:

```
✓ Both approaches cover all 2 acceptance scenarios
✓ Approach 1: Better for scaling (SC-001 metric)
✓ Approach 2: Faster implementation
→ APPROVED: Approach 1 - Better long-term fit
→ Instructions: JWT implementation, bcrypt for passwords, 
  rate limiting on endpoints, comprehensive error handling
```

### Step 4: Planner Implementation

Planner implements with scenario checklist:

```
[13:00] Starting implementation
[13:15] SCENARIO 1 PROGRESS: Created User model
[13:30] SCENARIO 1 PROGRESS: Signup endpoint created
[13:45] SCENARIO 1 COMPLETE: User signup working ✓
[14:00] SCENARIO 2 PROGRESS: Email verification created
[14:15] SCENARIO 2 COMPLETE: Email verification working ✓
[14:30] Implementation complete - All 2 scenarios passing
```

## 🔄 Monitoring Progress

While agents run, you can monitor:

```bash
# Watch logs in real-time
tail -f coordination/logs/notifications.log

# Check active work
cat coordination/active_work_registry.json | jq .

# Check proposal status
cat coordination/task_proposals.json | jq '.status'
```

## 💡 Tips

1. **Use Acceptance Scenarios as Tests** - Each scenario should have a corresponding test case in your codebase

2. **Be Specific About Constraints** - Hard constraints (those that must not be violated) guide the planner's decisions

3. **Organize by Priority** - P1 stories are non-negotiable; P2/P3 can be deferred if needed

4. **Success Criteria Must Be Measurable** - "Users love this" is not measurable; "70% daily active users" is

5. **Acceptance Scenarios Drive Implementation** - The implementation is complete when all scenarios work

## 📝 Advanced: Custom Prompts

If you want to customize how agents handle specs:

- `prompts/planner_agent_spec.txt` - How planner analyzes and implements specs
- `prompts/reviewer_agent_spec.txt` - How reviewer evaluates spec-based proposals

Edit these files to add project-specific guidance.

## 🐛 Troubleshooting

**Q: Agents not picking up my spec changes**
A: Agents check files every 30 seconds. Wait a moment and verify file is saved.

**Q: Planner created poor approaches**
A: Check that acceptance scenarios in spec are clear and specific. Vague scenarios lead to unclear proposals.

**Q: Reviewer rejected all approaches**
A: Likely a hard constraint can't be met. Review constraints in spec - are they realistic for V1?

**Q: How do I know if implementation is done?**
A: All acceptance scenarios must pass. Check logs for "SCENARIO X COMPLETE" messages.

## 📚 Related Files

- `setup.sh` - Initialize project with spec structure
- `launch-agents-from-spec.sh` - Launch agents for a specific feature spec
- `launch-agents.sh` - Launch with free-form task (legacy mode)
- `prompts/planner_agent_spec.txt` - Planner behavior for specs
- `prompts/reviewer_agent_spec.txt` - Reviewer behavior for specs

---

**Remember**: Your acceptance scenarios are the true requirements. Implementation is complete when all scenarios work! 🚀
