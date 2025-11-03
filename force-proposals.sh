#!/bin/bash
PROJECT_PATH="/Users/mchaouachi/IdeaProjects/StockMonitor"

# Clear the proposals file
echo '{}' > "$PROJECT_PATH/coordination/task_proposals.json"

# Remove any status that might confuse the planner
rm -f "$PROJECT_PATH/coordination/active_work_registry.json"
echo '{"agents": {}}' > "$PROJECT_PATH/coordination/active_work_registry.json"

echo "✅ Reset coordination files"
echo "Now restart the agents:"
echo "./launch-agents-from-spec.sh $PROJECT_PATH 999"
