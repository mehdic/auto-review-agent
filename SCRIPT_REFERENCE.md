# Agent System Scripts - Detailed Reference Guide

## 📁 Script Organization & Purpose

### 🚀 SETUP & INITIALIZATION SCRIPTS

#### **setup.sh**
- **Purpose**: Initialize project coordination structure
- **Usage**: `./setup.sh /path/to/project`
- **What it does**:
  - Creates coordination directory structure
  - Sets up task_proposals.json
  - Creates specs directory
  - Initializes logging directories
  - Sets proper permissions

#### **QUICKSTART.sh**
- **Purpose**: Automated setup wizard for first-time users
- **Usage**: `./QUICKSTART.sh`
- **What it does**:
  - Interactive setup guide
  - Creates all necessary directories
  - Generates sample specs
  - Tests agent connectivity
  - Provides step-by-step instructions

#### **CREATE_TEST_SPEC.sh**
- **Purpose**: Generate specification for test fixing tasks
- **Usage**: `./CREATE_TEST_SPEC.sh`
- **What it does**:
  - Creates 999-fix-remaining-tests spec
  - Analyzes current test status
  - Generates acceptance criteria
  - Sets up autonomous work instructions

---

### 🎮 LAUNCH SCRIPTS

#### **launch-agents-from-spec.sh** ⭐ (MAIN LAUNCHER)
- **Purpose**: Primary agent launcher with spec support
- **Usage**: `./launch-agents-from-spec.sh /project/path spec-number`
- **What it does**:
  - Reads spec from /specs/[number]-[name]/spec.md
  - Creates tmux session with 3 windows
  - Starts planner and reviewer agents
  - Passes spec to both agents
  - Sets up monitoring window
- **Fixed version**: Uses file-based approach to avoid command length issues

#### **launch-agents.sh**
- **Purpose**: Standard agent launcher without specs
- **Usage**: `./launch-agents.sh /project/path`
- **What it does**:
  - Basic agent launch
  - Creates planner/reviewer windows
  - No spec-based instructions
  - General task mode

#### **launch-agents-strict.sh**
- **Purpose**: Launch with strict validation mode
- **Usage**: `./launch-agents-strict.sh /project/path`
- **What it does**:
  - Enhanced validation rules
  - Stricter approval criteria
  - More detailed logging
  - Quality-focused reviews

---

### 📊 MONITORING & DEBUGGING SCRIPTS

#### **check-agent-progress.sh** ⭐ (RECOMMENDED)
- **Purpose**: Comprehensive progress report
- **Usage**: `./check-agent-progress.sh [project-path]`
- **Shows**:
  - Current status (idle/awaiting_review/approved/implementing)
  - Test progress (X/183 passing)
  - Recent agent activity
  - Files modified recently
  - Agent communication status
  - Recommendations for next steps

#### **monitor.sh**
- **Purpose**: Live monitoring dashboard
- **Usage**: `./monitor.sh /project/path`
- **What it does**:
  - Real-time status updates
  - Test progress tracking
  - File change monitoring
  - Agent activity display
  - Auto-refreshes every 5 seconds

#### **agent-manager.sh** ⭐ (QUICK TOOL)
- **Purpose**: Simple management interface
- **Usage**: `./agent-manager.sh [check|fix|restart|status]`
- **Commands**:
  - `check`: Full status check
  - `fix`: Auto-diagnose and fix
  - `restart`: Kill and restart
  - `status`: One-line status

#### **view-logs.sh**
- **Purpose**: Interactive log viewer
- **Usage**: `./view-logs.sh [project-path]`
- **Features**:
  - Browse agent history
  - Search logs
  - View Claude conversations
  - Filter by date/agent

#### **setup-logging.sh**
- **Purpose**: Enable comprehensive logging
- **Usage**: `./setup-logging.sh /project/path`
- **What it does**:
  - Creates logging wrappers
  - Captures tmux panes
  - Logs Claude conversations
  - JSON event tracking

---

### 🔧 FIXING & RECOVERY SCRIPTS

#### **agent-autofix.sh** ⭐⭐⭐ (INTELLIGENT FIXER)
- **Purpose**: Diagnose and fix all common issues
- **Usage**: `./agent-autofix.sh [project-path]`
- **Fixes**:
  1. Missing proposals → Creates them
  2. Stuck reviewer → Triggers review
  3. Approved but not implementing → Starts implementation
  4. Communication issues → Repairs channels
  5. File format issues → Corrects JSON
  6. Dead agents → Restarts (last resort)
- **Smart Features**:
  - Exhausts all options before restart
  - Logs all actions
  - Verifies fixes

#### **force-implementation.sh**
- **Purpose**: Force planner to implement approved proposal
- **Usage**: `./force-implementation.sh`
- **When to use**:
  - Status shows "approved"
  - But planner not implementing
  - After reviewer approval

#### **start-implementation.sh**
- **Purpose**: Simple implementation starter
- **Usage**: `./start-implementation.sh`
- **What it does**:
  - Sends implementation command
  - Quick and direct
  - No diagnostics

#### **force-proposals.sh**
- **Purpose**: Force proposal creation
- **Usage**: `./force-proposals.sh`
- **When to use**:
  - No proposals exist
  - Planner not creating

#### **fix-launch-script.sh**
- **Purpose**: Fix "command too long" errors
- **Usage**: `./fix-launch-script.sh`
- **What it does**:
  - Updates launch scripts
  - Implements file-based approach
  - Fixes argument length issues

#### **apply-file-fix.sh**
- **Purpose**: Apply file-based approach fixes
- **Usage**: `./apply-file-fix.sh`
- **What it does**:
  - Updates planner/reviewer loops
  - Fixes file reading issues

#### **stop-agents.sh**
- **Purpose**: Kill all agent sessions
- **Usage**: `./stop-agents.sh`
- **What it does**:
  - Kills tmux sessions
  - Cleans up processes
  - Safe shutdown

---

### 🔄 LOOP SCRIPTS (Background Workers)

#### **planner-loop.sh**
- **Purpose**: Planner agent main loop
- **Called by**: launch-agents-from-spec.sh
- **What it does**:
  - Creates proposals
  - Waits for approval
  - Implements approved plans
  - Works autonomously

#### **reviewer-loop.sh**
- **Purpose**: Reviewer agent main loop
- **Called by**: launch-agents-from-spec.sh
- **What it does**:
  - Monitors for proposals
  - Evaluates approaches
  - Approves/rejects
  - Updates status

#### **monitor-loop.sh**
- **Purpose**: Monitoring loop
- **Called by**: launch scripts
- **What it does**:
  - Displays status
  - Shows notifications
  - Tracks progress

---

## 📝 PROMPTS DIRECTORY

### **planner_agent_spec.txt**
- Planner agent instructions
- Proposal creation rules
- Implementation guidelines
- Autonomous work directives

### **reviewer_agent_spec.txt**
- Reviewer evaluation criteria
- Approval guidelines
- Quality standards
- Risk assessment rules

---

## 🗂️ FILE STRUCTURE

```
/Users/mchaouachi/agent-system/
├── start-here.sh              # THIS MENU SCRIPT
├── setup.sh                   # Project setup
├── launch-agents-from-spec.sh # Main launcher
├── agent-autofix.sh          # Intelligent fixer
├── check-agent-progress.sh   # Progress reporter
├── agent-manager.sh          # Quick manager
├── planner-loop.sh           # Planner worker
├── reviewer-loop.sh          # Reviewer worker
├── monitor.sh                # Live monitor
├── prompts/
│   ├── planner_agent_spec.txt
│   └── reviewer_agent_spec.txt
└── docs/
    ├── COMPLETE_DOCUMENTATION.md
    ├── QUICK_REFERENCE.md
    └── ...

/Users/mchaouachi/IdeaProjects/StockMonitor/
├── specs/
│   ├── 001-feature-name/
│   │   └── spec.md
│   └── 999-fix-remaining-tests/
│       └── spec.md
└── coordination/
    ├── task_proposals.json
    ├── active_work_registry.json
    └── logs/
        ├── planner/
        ├── reviewer/
        └── combined/
```

---

## 🎯 COMMON WORKFLOWS

### Starting Fresh
1. Run `./start-here.sh`
2. Select option 1 (Setup Project)
3. Select option 4 (Launch From Spec)
4. Monitor with option 7 (Check Progress)

### Fixing Stuck Agents
1. Run `./start-here.sh`
2. Select option 7 (Check Progress) - see what's wrong
3. Select option 12 (Auto Fix) - fixes most issues
4. If still stuck, option 13 (Force Implementation)

### Quick Commands (Without Menu)
```bash
# Check status
./agent-manager.sh check

# Auto-fix
./agent-autofix.sh

# Force implementation
./start-implementation.sh

# Full restart
./agent-manager.sh restart
```

---

## ⚡ QUICK TIPS

1. **Always check progress first** before applying fixes
2. **Auto-fix handles 90% of issues** - try it before manual fixes
3. **Don't restart unless necessary** - exhaust other options
4. **Monitor file changes** to verify agents are working
5. **Check logs** when debugging unusual issues
6. **Use specs** for clear task definitions
7. **Let agents work autonomously** - don't interrupt

---

## 🚨 TROUBLESHOOTING PRIORITY

1. First: Check Progress (`option 7`)
2. Second: Auto Fix (`option 12`)
3. Third: Force Implementation (`option 13`)
4. Fourth: Agent Manager Fix (`option 9 → fix`)
5. Last Resort: Full Restart (`option 9 → restart`)

---

## 📞 SUPPORT

- Documentation: Options 19-20 in menu
- Custom commands: Option 21
- Exit cleanly: Option 0

Remember: The start-here.sh script is your central command center!
