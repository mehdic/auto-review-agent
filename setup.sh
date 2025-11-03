#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Setting up Agent Coordination System with Spec Structure${NC}"
echo ""

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Usage: ./setup.sh /path/to/your/project${NC}"
    exit 1
fi

PROJECT_PATH="$1"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${YELLOW}📁 Project directory doesn't exist. Creating: $PROJECT_PATH${NC}"
    mkdir -p "$PROJECT_PATH"
fi

# Create specs folder structure
echo -e "${BLUE}📂 Creating specs folder structure...${NC}"
mkdir -p "$PROJECT_PATH/specs"

# Create sample spec folder if none exist
if [ -z "$(ls -A $PROJECT_PATH/specs 2>/dev/null)" ]; then
    mkdir -p "$PROJECT_PATH/specs/001-initial-feature"
    cat > "$PROJECT_PATH/specs/001-initial-feature/spec.md" << 'SPEC_EOF'
# Feature Specification: [Feature Name]

**Feature Branch**: `001-initial-feature`
**Created**: 2025-11-03
**Status**: Draft
**Input**: User description: [Brief description of the feature]

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Story Name] (Priority: P1)

[Story description and why it matters]

**Why this priority**: [Explain priority]

**Independent Test**: [How to test independently]

**Acceptance Scenarios**:

1. **Given** [initial condition], **When** [action], **Then** [expected outcome]

---

## Success Criteria

**Adoption**
- **SC-001**: [Measurable metric for adoption]

**Quality**
- **SC-002**: [Measurable metric for quality]

## Constraints

**Out of Scope for V1**
- [Item 1]
- [Item 2]

**Technical Constraints**
- [Constraint 1]
- [Constraint 2]

**Regulatory Constraints**
- [If applicable]

**User Experience Constraints**
- [UX requirement 1]
- [UX requirement 2]
SPEC_EOF
    echo -e "${GREEN}✅ Created sample spec in: $PROJECT_PATH/specs/001-initial-feature/spec.md${NC}"
else
    echo -e "${GREEN}✅ Specs folder already populated${NC}"
fi

# Create coordination directory
echo -e "${BLUE}📂 Creating coordination directory...${NC}"
mkdir -p "$PROJECT_PATH/coordination"
mkdir -p "$PROJECT_PATH/coordination/messages"
mkdir -p "$PROJECT_PATH/coordination/agent_locks"
mkdir -p "$PROJECT_PATH/coordination/logs"

# Initialize JSON files
echo -e "${BLUE}📝 Initializing coordination files...${NC}"

cat > "$PROJECT_PATH/coordination/task_proposals.json" << 'COORD_EOF'
{
  "proposals": [],
  "status": "idle",
  "planner_agent_id": null,
  "created_at": null,
  "task_description": null,
  "spec_file": null,
  "spec_feature_name": null
}
COORD_EOF

cat > "$PROJECT_PATH/coordination/active_work_registry.json" << 'COORD_EOF'
{
  "agents": {}
}
COORD_EOF

cat > "$PROJECT_PATH/coordination/completed_work_log.json" << 'COORD_EOF'
{
  "completed_tasks": []
}
COORD_EOF

cat > "$PROJECT_PATH/coordination/planned_work_queue.json" << 'COORD_EOF'
{
  "queued_tasks": [],
  "current_task": null
}
COORD_EOF

cat > "$PROJECT_PATH/coordination/messages/planner_to_reviewer.json" << 'COORD_EOF'
{
  "messages": [],
  "unread_count": 0
}
COORD_EOF

cat > "$PROJECT_PATH/coordination/messages/reviewer_to_planner.json" << 'COORD_EOF'
{
  "messages": [],
  "unread_count": 0
}
COORD_EOF

# Initialize logs
touch "$PROJECT_PATH/coordination/logs/notifications.log"
touch "$PROJECT_PATH/coordination/logs/agent_activity.log"

echo -e "${GREEN}✅ Coordination directory structure created${NC}"
echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Add your spec.md files to: $PROJECT_PATH/specs/NNN-feature-name/"
echo "2. Run: ./launch-agents-from-spec.sh $PROJECT_PATH [feature-number]"
echo ""
echo -e "${YELLOW}📖 Your project structure:${NC}"
echo "$PROJECT_PATH/"
echo "├── specs/"
echo "│   ├── 001-initial-feature/"
echo "│   │   └── spec.md"
echo "│   ├── 002-next-feature/"
echo "│   │   └── spec.md"
echo "│   └── ..."
echo "└── coordination/"
echo "    ├── task_proposals.json"
echo "    ├── messages/"
echo "    ├── agent_locks/"
echo "    └── logs/"
