# Start-Here Menu Updates (v2.0)

## Summary of Changes

The `start-here.sh` menu has been updated to reflect the new generic agent loops and remove outdated scripts.

## What's New

### Added Scripts (marked with [NEW])

**Option 8: Diagnose Stuck**
- Script: `diagnose-stuck.sh`
- Purpose: Comprehensive diagnostic tool that analyzes why agents are stuck
- Shows: proposals status, running processes, tmux state, file changes, with specific recommendations

**Option 13: Wake Up Planner**
- Script: `wake-up-planner.sh`
- Purpose: Wake up stuck planner in existing tmux session (tmux-aware)
- Best for: When agents are running but planner is idle

**Option 14: Nuclear Fix**
- Script: `nuclear-fix.sh`
- Purpose: Force implementation regardless of current state
- Best for: When wake-up-planner doesn't work

### Updated Documentation Section

Added new documentation to the list:
- `GENERIC_LOOPS_GUIDE.md` - Complete guide to generic agent loops (v2.0)
- `FIX_STUCK_PLANNER.md` - Troubleshooting guide for stuck planners

### Updated Header

Changed from "Start Here Menu" to "Generic Autonomous Agents v2.0" to reflect the new architecture.

Added footer message:
```
💡 New in v2.0: Generic loops work with ANY spec.md
   Agents continue until completion verified!
```

## What Was Removed

### Removed Scripts (Outdated/Redundant)

**Option 13 (old): Force Implementation**
- Script: `force-implementation.sh`
- Reason: Hardcoded for test fixing, replaced by generic `wake-up-planner.sh`
- Status: **REMOVED** from menu (file kept for backward compatibility)

**Option 14 (old): Start Implementation**
- Script: `start-implementation.sh`
- Reason: Very simple, redundant with wake-up-planner.sh
- Status: **REMOVED** from menu (file kept for backward compatibility)

**Option 15 (old): Force Proposals**
- Script: `force-proposals.sh`
- Reason: Generic loops handle proposal creation automatically
- Status: **REMOVED** from menu (still accessible via custom command if needed)

**Option 16 (old): Fix Launch Script**
- Script: `fix-launch-script.sh`
- Reason: Command-too-long issue fixed in generic loops
- Status: **REMOVED** from menu (obsolete)

**Option 17 (old): Apply File Fix**
- Script: `apply-file-fix.sh`
- Reason: File-based approach now standard in generic loops
- Status: **REMOVED** from menu (obsolete)

## Menu Structure Comparison

### Old Menu (21 options)
```
SETUP & INITIALIZATION (1-3)
LAUNCH AGENTS (4-6)
MONITORING & DEBUGGING (7-11)
FIXING & RECOVERY (12-18)  ← 7 options, many redundant
UTILITIES (19-21)
```

### New Menu (19 options)
```
SETUP & INITIALIZATION (1-3)
LAUNCH AGENTS (4-6)
MONITORING & DEBUGGING (7-12)  ← Added diagnose-stuck
FIXING & RECOVERY (13-16)      ← Streamlined to 4 focused options
UTILITIES (17-19)
```

## Benefits

1. **Cleaner Menu**: Removed 2 redundant/obsolete options
2. **Better Organization**: New scripts logically placed
3. **Clear Indicators**: [NEW] tag for recent additions
4. **Future-Proof**: Generic scripts work with any task
5. **Easier Navigation**: Fewer options, more focused

## Migration Notes

**Backward Compatibility:**
- Old scripts still exist on disk
- Can be run via "Option 19: Run Custom Command"
- No breaking changes to existing workflows

**Recommended Migration:**
- Use `wake-up-planner.sh` instead of `force-implementation.sh`
- Use `diagnose-stuck.sh` before trying fixes
- Use `nuclear-fix.sh` as last resort

## Updated Workflows

### Stuck Planner Workflow (New)
```
1. Option 8: Diagnose Stuck  → Understand the problem
2. Option 13: Wake Up Planner → Try gentle wake-up
3. Option 14: Nuclear Fix    → Force if needed
```

### Old Stuck Planner Workflow (Deprecated)
```
1. Option 13: Force Implementation ❌ Hardcoded
2. Option 14: Start Implementation ❌ Too simple
3. Option 17: Apply File Fix       ❌ Obsolete
```

## Files Modified

- `start-here.sh` - Main menu script (updated)
- `start-here.sh.backup` - Backup of original (for safety)

## Testing

To test the new menu:
```bash
cd /Users/mchaouachi/agent-system
./start-here.sh
```

All new options (8, 13, 14) should work correctly with generic loops.

---

**Version:** 2.0
**Date:** 2024-11-04
**Changes:** Removed 5 outdated options, added 3 new options, updated docs
