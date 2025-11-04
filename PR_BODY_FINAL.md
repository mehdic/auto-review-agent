# Fix Stuck Planner + Generic Agent Loops + Unified Agent

## 🎯 Summary

This PR completely reimplements the agent system to fix the stuck planner issue and creates a robust, universal architecture that works with any spec.md file.

### Problems Solved

1. **Stuck Planner Issue** ✅
   - Status shows "implementing" but no Claude process running
   - Root cause: planner-loop.sh updated status but exited without starting implementation
   - Fix: Complete rewrite with continuous loop architecture

2. **Premature Exits** ✅
   - Old loops would exit after one Claude call regardless of completion
   - Fix: Loops now continue until spec success criteria are verified

3. **Task-Specific Loops** ✅
   - Old loops were hardcoded for specific tasks
   - Fix: Generic loops work with ANY spec.md file

4. **Tmux Raw Mode Error** ✅
   - `claude <<EOF` heredoc doesn't work in tmux
   - Error: "Raw mode is not supported on the current process.stdin"
   - Fix: Use piped prompts instead: `cat prompt | claude`

5. **Planner/Reviewer Isolation** ✅
   - Separate processes can't communicate
   - Planner asks questions, reviewer can't answer
   - Fix: NEW unified agent - single Claude session does everything

---

## 🆕 What's New

### Core Architecture

#### 1. Generic Agent Loops
- **planner-loop.sh** - Continuous implementation until verified complete
- **reviewer-loop.sh** - Monitors and verifies until all work done
- **check-completion.sh** - Universal completion verifier
- **Works with ANY spec.md** - not just test fixing!

#### 2. Tmux-Compatible Versions
- **planner-loop-tmux.sh** - Uses piped prompts, no raw mode issues
- **reviewer-loop-tmux.sh** - Tmux-friendly implementation
- Fixed heredoc → pipe architecture

#### 3. Interactive Mode (NEW)
- **planner-loop-interactive.sh** - Shows full Claude UI
- **reviewer-loop-interactive.sh** - Allows manual interaction
- User can see and interact with Claude while it works

#### 4. Unified Agent (NEW - RECOMMENDED)
- **unified-agent.sh** - Single Claude session does plan+review+implement
- Solves the communication problem
- Transparent, simple, actually works
- No more separate planner/reviewer windows

### Fix & Diagnostic Tools

- **wake-up-planner.sh** - Wake stuck planner in existing tmux
- **nuclear-fix.sh** - Force implementation regardless of state
- **diagnose-stuck.sh** - Comprehensive diagnostic tool
- **check-tmux-windows.sh** - Show what's in each tmux window
- **direct-implement.sh** - Direct implementation starter

### Documentation

- **GENERIC_LOOPS_GUIDE.md** - Complete guide to generic loops
- **FIX_STUCK_PLANNER.md** - Troubleshooting guide
- **LOOP_MODES.md** - Comparison of piped vs interactive modes
- **MENU_CHANGES.md** - Menu update details
- **PR_BODY.md** - This file

### Updated Menu

- **start-here.sh** updated to v2.0
- Added new scripts: Diagnose Stuck, Wake Up Planner, Nuclear Fix
- Removed outdated scripts: force-implementation, start-implementation, etc.
- Cleaner menu: 21 options → 19 focused options

---

## 📊 Architecture Comparison

### Old Architecture (Broken)

```
┌─────────────┐     ┌─────────────┐
│  Planner    │     │  Reviewer   │
│  (Window 0) │     │  (Window 1) │
│             │     │             │
│ Asks Q →    │  ✗  │ Can't see Q │
│ Gets stuck  │     │ Can't help  │
└─────────────┘     └─────────────┘
       ↓                   ↓
   No answer          Useless
```

**Problems:**
- Separate processes can't communicate
- Planner asks questions nobody can answer
- Piped mode hides Claude UI
- User can't see what's happening

### New Architecture (Fixed)

**Option 1: Generic Loops (Multi-Window)**
```
┌─────────────┐     ┌─────────────┐
│  Planner    │     │  Reviewer   │
│  Loop       │     │  Loop       │
│             │     │             │
│ Continuous  │     │ Monitors    │
│ Until Done  │     │ Verifies    │
└─────────────┘     └─────────────┘
       ↓                   ↓
   Verified          Confirmed
```

**Option 2: Unified Agent (RECOMMENDED)**
```
┌───────────────────────────────┐
│     Unified Agent             │
│   (Single Claude Session)     │
│                               │
│  Plan → Review → Implement    │
│  All in one transparent flow  │
│                               │
│  Can see UI, can interact     │
└───────────────────────────────┘
           ↓
    Actually works!
```

---

## 🔑 Key Features

### Generic Completion Checking
- Parses "Definition of Done" and "Success Criteria" from any spec
- Multiple iterations if needed to achieve all criteria
- Completion verification before exit (no premature exits)
- Reviewer independently verifies completion

### Continuous Operation
- Loops don't exit until verified complete
- Iteration counters for transparency
- Automatic retry on failure
- Safety reset if completion claim is false

### Tmux Compatibility
- No more "raw mode not supported" errors
- Piped prompts instead of heredoc
- Works perfectly in tmux sessions
- Proper logging to files

### Transparency & Control
- Interactive mode shows full Claude UI
- Can manually intervene when needed
- All activity logged
- Status tracking in JSON files

---

## 📁 Files Changed

### New Core Scripts
- `check-completion.sh` - Universal completion verifier
- `unified-agent.sh` - ⭐ Single agent architecture
- `planner-loop-interactive.sh` - Interactive planner
- `reviewer-loop-interactive.sh` - Interactive reviewer
- `planner-loop-tmux.sh` - Tmux-compatible planner
- `reviewer-loop-tmux.sh` - Tmux-compatible reviewer

### Modified Core Scripts
- `planner-loop.sh` - ✅ Now generic, continuous, tmux-compatible
- `reviewer-loop.sh` - ✅ Now generic, verifies completion

### Fix Scripts
- `wake-up-planner.sh` - Wake stuck planner
- `nuclear-fix.sh` - Force implementation
- `diagnose-stuck.sh` - Comprehensive diagnostics
- `check-tmux-windows.sh` - Tmux window contents
- `direct-implement.sh` - Direct starter

### Documentation
- `GENERIC_LOOPS_GUIDE.md` - Complete loops guide
- `FIX_STUCK_PLANNER.md` - Troubleshooting
- `LOOP_MODES.md` - Mode comparison
- `MENU_CHANGES.md` - Menu updates

### Updated
- `start-here.sh` - Menu v2.0 with new scripts
- Various backup files for safety

---

## 🚀 Migration Guide

### For Current Stuck Situation

```bash
cd /Users/mchaouachi/agent-system
git pull origin claude/fix-planner-implementation-stuck-011CUnivgURzCzxghnaLrUNX

# Option 1: Wake up existing planner
./wake-up-planner.sh

# Option 2: Restart with generic loops
tmux kill-session -t agent_system_spec
./launch-agents-from-spec.sh /path/to/project spec-name

# Option 3: Use unified agent (RECOMMENDED)
./unified-agent.sh /path/to/project /path/to/spec.md feature-name
```

### For Future Use

Just use the unified agent:

```bash
./unified-agent.sh PROJECT_PATH SPEC_FILE FEATURE_NAME
```

Or use the updated menu:
```bash
./start-here.sh
# Choose option 4 to launch from spec
```

---

## ✅ Testing

### Tested Scenarios
- [x] Generic loops work with spec 999-fix-remaining-tests
- [x] Tmux compatibility verified (no raw mode errors)
- [x] Completion verification works correctly
- [x] Interactive mode shows Claude UI properly
- [x] Unified agent completes full workflow
- [x] Wake-up-planner fixes stuck sessions
- [x] Menu v2.0 launches all scripts correctly

### Test Commands
```bash
# Test completion checker
./check-completion.sh /path/to/project /path/to/spec.md true

# Test unified agent
./unified-agent.sh /path/to/project /path/to/spec.md test

# Test diagnostics
./diagnose-stuck.sh /path/to/project
```

---

## 🎓 Benefits

1. **No More Stuck Implementations**
   - Continuous loops until verified complete
   - Multiple iterations if needed
   - Automatic recovery mechanisms

2. **Universal Solution**
   - Works with ANY spec.md format
   - Parses success criteria dynamically
   - Not hardcoded for specific tasks

3. **Fully Autonomous**
   - Runs until actually done
   - Makes own decisions
   - No manual intervention required (unless using interactive mode)

4. **Transparent & Controllable**
   - Can see Claude UI (interactive mode)
   - Can manually interact when needed
   - Full logging of all activity

5. **Simple Architecture**
   - Unified agent solves communication problem
   - "It's just text" - straightforward processing
   - Easy to understand and debug

---

## 📊 Commits Summary

1. Fix stuck planner implementation issue (initial fixes)
2. Add wake-up-planner.sh (works with existing tmux)
3. Implement generic agent loops (universal solution)
4. Add PR body for documentation
5. Update start-here.sh menu to v2.0
6. Fix tmux raw mode error (piped prompts)
7. Add diagnostic script (check tmux windows)
8. Add interactive loop mode (full Claude UI)
9. Fix check-completion.sh syntax error
10. Add unified agent (single session architecture)

**Total:** 10 commits, major architectural improvement

---

## ⚠️ Breaking Changes

None! The new system is **backward compatible**:
- Old scripts still exist (can use via custom command)
- Existing workflows continue to work
- New features are additive

---

## 🔮 Future Enhancements

Possible improvements:
- Auto-switch from interactive to piped mode if idle
- Web UI for monitoring agents
- Multi-project support
- Agent collaboration (multiple unified agents)

---

## 🙏 Acknowledgments

This PR addresses feedback about:
- Stuck planner issues
- Lack of transparency (no Claude UI visible)
- Planner/reviewer communication problems
- "Why all these limitations?" → Simplified architecture

**The unified agent is the answer: one session, transparent, simple, works.**

---

## 📝 Recommendation

**Merge this PR** to get:
- ✅ Fix for stuck planner
- ✅ Generic loops that work with any task
- ✅ Unified agent architecture
- ✅ Better transparency and control
- ✅ Simpler, more maintainable code

The agent system now actually works as intended! 🚀
