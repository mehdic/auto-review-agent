#!/bin/bash
# Quick installer for the Agent System Command Center

echo "═══════════════════════════════════════════════════════════"
echo "     AGENT SYSTEM COMMAND CENTER - INSTALLER"
echo "═══════════════════════════════════════════════════════════"
echo ""

AGENT_DIR="/Users/mchaouachi/agent-system"
DOWNLOADS_DIR="/Users/mchaouachi/Downloads"

# Check if agent-system directory exists
if [ ! -d "$AGENT_DIR" ]; then
    echo "Creating agent-system directory..."
    mkdir -p "$AGENT_DIR"
fi

# Copy all scripts from current directory to agent-system
echo "Installing scripts to $AGENT_DIR..."

# Main menu script
if [ -f "start-here.sh" ]; then
    cp start-here.sh "$AGENT_DIR/"
    chmod +x "$AGENT_DIR/start-here.sh"
    echo "✓ Installed start-here.sh"
fi

# Core scripts
scripts=(
    "setup.sh"
    "launch-agents-from-spec.sh"
    "launch-agents.sh"
    "launch-agents-strict.sh"
    "agent-autofix.sh"
    "check-agent-progress.sh"
    "agent-manager.sh"
    "monitor.sh"
    "planner-loop.sh"
    "reviewer-loop.sh"
    "monitor-loop.sh"
    "setup-logging.sh"
    "view-logs.sh"
    "force-implementation.sh"
    "start-implementation.sh"
    "force-proposals.sh"
    "fix-launch-script.sh"
    "apply-file-fix.sh"
    "stop-agents.sh"
    "QUICKSTART.sh"
    "CREATE_TEST_SPEC.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        cp "$script" "$AGENT_DIR/"
        chmod +x "$AGENT_DIR/$script"
        echo "✓ Installed $script"
    fi
done

# Documentation
docs=(
    "COMPLETE_DOCUMENTATION.md"
    "AGENT_SYSTEM_GUIDE VERY IMPORTANT MAIN DOC.md"
    "QUICK_REFERENCE.md"
    "QUICK_REFERENCE2.md"
    "README.md"
    "SPEC_BASED_WORKFLOW.md"
    "STRICT_MODE_GUIDE.md"
    "SCRIPT_REFERENCE.md"
)

echo ""
echo "Installing documentation..."
for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        cp "$doc" "$AGENT_DIR/"
        echo "✓ Installed $doc"
    fi
done

# Create prompts directory if needed
if [ ! -d "$AGENT_DIR/prompts" ]; then
    mkdir -p "$AGENT_DIR/prompts"
    echo "✓ Created prompts directory"
fi

# Copy prompt files if they exist
if [ -f "prompts/planner_agent_spec.txt" ]; then
    cp prompts/*.txt "$AGENT_DIR/prompts/"
    echo "✓ Installed prompt files"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                 INSTALLATION COMPLETE!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "🎉 The Agent System Command Center has been installed!"
echo ""
echo "📍 Location: $AGENT_DIR"
echo ""
echo "🚀 To start using it:"
echo "   cd $AGENT_DIR"
echo "   ./start-here.sh"
echo ""
echo "📝 Quick Commands:"
echo "   Check status:  ./agent-manager.sh check"
echo "   Auto-fix:      ./agent-autofix.sh"
echo "   Full menu:     ./start-here.sh"
echo ""
echo "📖 Documentation available in start-here.sh option 19"
echo ""
echo "═══════════════════════════════════════════════════════════"
