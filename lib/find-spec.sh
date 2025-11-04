#!/bin/bash
# Spec Finder Utility - Finds spec folder and tasks.md by number

find_spec() {
    local project_path="$1"
    local spec_number="$2"

    # Clean up spec number (remove leading zeros if any for search)
    spec_number=$(echo "$spec_number" | sed 's/^0*//')

    # Add back leading zeros for consistent 3-digit format
    spec_number=$(printf "%03d" "$spec_number")

    # Find the spec folder that starts with this number
    local spec_dir=$(find "$project_path/specs" -maxdepth 1 -type d -name "${spec_number}-*" | head -1)

    if [ -z "$spec_dir" ]; then
        echo "ERROR: No spec folder found for number $spec_number in $project_path/specs"
        return 1
    fi

    local tasks_file="$spec_dir/tasks.md"

    if [ ! -f "$tasks_file" ]; then
        echo "ERROR: tasks.md not found in $spec_dir"
        return 1
    fi

    # Return the paths
    echo "SPEC_DIR=$spec_dir"
    echo "TASKS_FILE=$tasks_file"
    echo "SPEC_NAME=$(basename $spec_dir)"

    return 0
}

# If called directly (not sourced)
if [ "${BASH_SOURCE[0]}" -eq "$0" ]; then
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <project_path> <spec_number>"
        echo "Example: $0 /path/to/project 001"
        exit 1
    fi

    find_spec "$1" "$2"
fi
