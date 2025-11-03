#!/bin/bash

# Quick Start Guide - Copy and paste these commands!

cat << 'EOF'

╔═══════════════════════════════════════════════════════════════╗
║     🤖 AUTONOMOUS AGENT SYSTEM - QUICK START GUIDE 🤖        ║
╚═══════════════════════════════════════════════════════════════╝

Follow these steps to get your agents running in 5 minutes:

═══════════════════════════════════════════════════════════════
STEP 1: Install Prerequisites
═══════════════════════════════════════════════════════════════

# Install tmux
Ubuntu/Debian: sudo apt install tmux jq
macOS:         brew install tmux jq

# Install Codex CLI (see official instructions)
codex auth login


═══════════════════════════════════════════════════════════════
STEP 2: Download This System
═══════════════════════════════════════════════════════════════

# Navigate to where you saved the agent-coordination-system folder
cd /path/to/agent-coordination-system

# Make scripts executable (if not already done)
chmod +x *.sh


═══════════════════════════════════════════════════════════════
STEP 3: Initialize Your Project
═══════════════════════════════════════════════════════════════

# Replace with your actual project path
./setup.sh /path/to/your/project

# Example:
# ./setup.sh ~/my-web-app


═══════════════════════════════════════════════════════════════
STEP 4: Launch the Agents
═══════════════════════════════════════════════════════════════

# Basic launch
./launch-agents.sh /path/to/your/project "Your task description"

# Example:
# ./launch-agents.sh ~/my-web-app "Create a REST API for user authentication"


═══════════════════════════════════════════════════════════════
STEP 5: Watch Them Work!
═══════════════════════════════════════════════════════════════

The system will automatically open 4 tmux windows:

Window 0 (Ctrl+b 0): 🎯 Planner Agent  - Creates proposals
Window 1 (Ctrl+b 1): ✅ Reviewer Agent - Reviews & approves
Window 2 (Ctrl+b 2): 📊 Monitor        - Real-time dashboard
Window 3 (Ctrl+b 3): 📝 Logs           - Activity log


═══════════════════════════════════════════════════════════════
COMMON TMUX COMMANDS
═══════════════════════════════════════════════════════════════

Ctrl+b 0, 1, 2, 3  - Switch between windows
Ctrl+b n           - Next window
Ctrl+b p           - Previous window
Ctrl+b d           - Detach (agents keep running)
Ctrl+b z           - Zoom current pane
Ctrl+b [           - Scroll mode (q to exit)

Reattach later:
tmux attach -t agent_system


═══════════════════════════════════════════════════════════════
TO INTERVENE
═══════════════════════════════════════════════════════════════

1. Switch to agent window: Ctrl+b 0 or Ctrl+b 1
2. Type your message: "Wait! I need to review this first."
3. Press Enter

The agent will respond and wait for your instructions.


═══════════════════════════════════════════════════════════════
TO STOP
═══════════════════════════════════════════════════════════════

./stop-agents.sh


═══════════════════════════════════════════════════════════════
EXAMPLE: COMPLETE WORKFLOW
═══════════════════════════════════════════════════════════════

# 1. Setup
./setup.sh ~/my-app

# 2. Launch
./launch-agents.sh ~/my-app "Add user authentication"

# 3. Watch Window 0 - Planner creates 3 proposals
#    (JWT, Sessions, OAuth)

# 4. Watch Window 1 - Reviewer evaluates and chooses JWT

# 5. Watch Window 0 - Planner implements JWT approach

# 6. Check Window 2 - Monitor shows progress

# 7. Check Window 3 - Logs show all activity

# 8. (Optional) Intervene if needed

# 9. Wait for completion

# 10. Stop
./stop-agents.sh


═══════════════════════════════════════════════════════════════
WHAT TO EXPECT
═══════════════════════════════════════════════════════════════

Timeline for a typical task:

00:00 - Give task to Planner
00:05 - Planner analyzes and creates 3 proposals
00:06 - Planner writes to coordination/task_proposals.json
00:07 - Status: "awaiting_review"

[30 second pause while Reviewer checks file]

00:30 - Reviewer sees new proposals
00:35 - Reviewer evaluates all options
00:40 - Reviewer chooses best approach
00:41 - Reviewer updates with status: "approved"

[30 second pause while Planner checks file]

01:00 - Planner sees approval
01:05 - Planner starts implementation
01:10 - Planner logs progress updates
02:00 - Planner completes implementation
02:01 - Status: "completed"


═══════════════════════════════════════════════════════════════
TROUBLESHOOTING
═══════════════════════════════════════════════════════════════

Problem: Agents not starting
→ Check: codex auth login

Problem: No communication between agents
→ Check logs: tail -f /your/project/coordination/logs/notifications.log
→ Check status: cat /your/project/coordination/task_proposals.json | jq .

Problem: Agents waiting forever
→ They check files every 30 seconds - be patient!
→ Or manually verify JSON files are valid: jq . file.json

Problem: Permission errors
→ Edit launch-agents.sh and add: --dangerously-skip-permissions
   (Only if you trust the agents!)


═══════════════════════════════════════════════════════════════
NEED HELP?
═══════════════════════════════════════════════════════════════

📖 Read the full README.md for detailed information
📋 Check EXAMPLE_TASKS.md for task ideas
🐛 Review the Troubleshooting section in README.md


═══════════════════════════════════════════════════════════════

Ready to start? Run this:

    ./setup.sh /path/to/your/project
    ./launch-agents.sh /path/to/your/project "Your task here"

Happy autonomous coding! 🚀

═══════════════════════════════════════════════════════════════

EOF
