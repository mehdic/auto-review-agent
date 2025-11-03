# 🎯 AGENT SYSTEM - QUICK REFERENCE CARD

## 🚀 START COMMAND
```bash
cd /Users/mchaouachi/agent-system
./start-here.sh
```

## ⌨️ MENU OPTIONS - QUICK REFERENCE

### MOST USED (Memorize These!)
```
7  - Check Progress      → See what's happening
12 - Auto Fix           → Fix any issues  
8  - Monitor            → Live dashboard
4  - Launch From Spec   → Start agents
```

### SETUP
```
1  - Setup Project      → First time setup
2  - Quick Start        → Wizard
3  - Create Test Spec   → Make test spec
```

### LAUNCH
```
4  - Launch From Spec   → With spec file ⭐
5  - Launch Standard    → No spec
6  - Launch Strict      → Quality mode
```

### MONITOR
```
7  - Check Progress     → Full report ⭐⭐⭐
8  - Monitor System     → Live view ⭐⭐
9  - Agent Manager      → Quick tool ⭐
10 - View Logs          → Browse logs
11 - Setup Logging      → Enable logs
```

### FIX
```
12 - Auto Fix           → Smart fixer ⭐⭐⭐
13 - Force Implement    → Force start
14 - Start Implement    → Simple start
15 - Force Proposals    → Create proposals
18 - Stop Agents        → Kill all
```

### INFO
```
19 - Documentation      → View docs
20 - Show Paths        → Configuration
21 - Custom Command    → Run any script
0  - Exit              → Quit menu
```

---

## 🔥 QUICK COMMANDS (No Menu)

```bash
# Check what's happening
./agent-manager.sh check

# Fix problems
./agent-manager.sh fix
# OR
./agent-autofix.sh

# Emergency restart
./agent-manager.sh restart

# View agents live
tmux attach -t agent_system_spec
# Then: Ctrl+b 0 (planner)
#       Ctrl+b 1 (reviewer)  
#       Ctrl+b 2 (monitor)
#       Ctrl+b d (detach)
```

---

## 📊 STATUS GUIDE

| Status | What It Means | Do This |
|--------|--------------|---------|
| `idle` | Not started | Option 4 |
| `awaiting_review` | Waiting for approval | Option 12 or wait |
| `approved` | Ready to work | Option 12 if stuck |
| `implementing` | Working! | Let it run |

---

## 🚨 TROUBLESHOOTING STEPS

1. **ALWAYS FIRST**: Option 7 (Check Progress)
2. **IF STUCK**: Option 12 (Auto Fix)  
3. **STILL STUCK**: Option 13 (Force Implementation)
4. **LAST RESORT**: Option 9 → restart

---

## 📁 KEY FILES

**Scripts Location**:
```
/Users/mchaouachi/agent-system/
```

**Project Files**:
```
/Users/mchaouachi/IdeaProjects/StockMonitor/
├── specs/999-fix-remaining-tests/spec.md
└── coordination/task_proposals.json
```

**Check Test Progress**:
```bash
cd /Users/mchaouachi/IdeaProjects/StockMonitor
mvn test | grep "Tests run:"
```

---

## ⚡ POWER USER TIPS

### Morning Routine
1. `./start-here.sh` → 7 (Check)
2. If issues → 12 (Auto Fix)
3. Then → 8 (Monitor)

### Quick Status Check
```bash
cat /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json | grep status
```

### Watch Files Change
```bash
watch -n 5 'find /Users/mchaouachi/IdeaProjects/StockMonitor -name "*.java" -mmin -5'
```

### Emergency Reset
```bash
tmux kill-server
echo '{}' > /Users/mchaouachi/IdeaProjects/StockMonitor/coordination/task_proposals.json
./start-here.sh → Option 4
```

---

## 🎯 REMEMBER

- **Option 7** = Check what's wrong
- **Option 12** = Fix it automatically
- **Option 8** = Watch it work
- **Option 4** = Start fresh

**Golden Rule**: Check (7) → Fix (12) → Monitor (8)

---

## 📝 NOTES SECTION

Current Spec Number: _________
Current Status: _____________
Tests Passing: _____ / 183
Last Action: _______________
Next Step: _________________

---

*Keep this card handy! 90% of tasks use options 4, 7, 8, and 12.*
