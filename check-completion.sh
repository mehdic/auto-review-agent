#!/bin/bash
# Generic completion checker - works with any spec.md file
# Parses "Definition of Done" and "Success Criteria" to determine if work is complete

PROJECT_PATH="$1"
SPEC_FILE="$2"
VERBOSE="${3:-false}"

if [ -z "$PROJECT_PATH" ] || [ -z "$SPEC_FILE" ]; then
    echo "Usage: $0 <project_path> <spec_file> [verbose]"
    exit 2
fi

if [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: Spec file not found: $SPEC_FILE"
    exit 2
fi

log() {
    if [ "$VERBOSE" = "true" ]; then
        echo "$1"
    fi
}

# Ask Claude to evaluate completion based on the spec
log "Checking completion against spec: $SPEC_FILE"

cd "$PROJECT_PATH" 2>/dev/null || true

# Create prompt file to avoid heredoc issues in tmux
PROMPT_FILE="/tmp/check_completion_$$_prompt.txt"
cat > "$PROMPT_FILE" << 'ENDPROMPT'
You are a completion checker agent.

Read the specification file: SPEC_FILE_PLACEHOLDER

Your task: Determine if the work described in this specification is COMPLETE.

Look for these sections in the spec:
1. "Definition of Done"
2. "Success Criteria"
3. "Acceptance Scenarios"

Then evaluate the CURRENT STATE of the project at: PROJECT_PATH_PLACEHOLDER

For example:
- If spec says "All 183 tests passing", run the tests and check
- If spec says "Feature X implemented", verify the feature exists
- If spec says "API endpoint /foo working", test the endpoint
- If spec says "Build succeeds", run the build

Respond with EXACTLY ONE LINE:
- If ALL success criteria are met: "COMPLETE"
- If ANY criteria not met: "INCOMPLETE: <brief reason>"

Do not provide explanations beyond that one line.
Evaluate the actual current state, don't assume anything.

IMPORTANT: After your response line, write exactly: BAZINGA
ENDPROMPT

# Replace placeholders
sed -i.bak "s|SPEC_FILE_PLACEHOLDER|$SPEC_FILE|g" "$PROMPT_FILE"
sed -i.bak "s|PROJECT_PATH_PLACEHOLDER|$PROJECT_PATH|g" "$PROMPT_FILE"

# Run Claude with prompt file
FULL_OUTPUT=$(cat "$PROMPT_FILE" | claude 2>/dev/null)

# Clean up
rm -f "$PROMPT_FILE" "$PROMPT_FILE.bak"

# Extract result (look for COMPLETE or INCOMPLETE line, ignoring BAZINGA)
RESULT=$(echo "$FULL_OUTPUT" | grep -E "^(COMPLETE|INCOMPLETE)" | head -1)

log "Result: $RESULT"

# Check the result
if echo "$RESULT" | grep -qi "^COMPLETE"; then
    [ "$VERBOSE" = "true" ] && echo "✅ Work is COMPLETE"
    exit 0
else
    [ "$VERBOSE" = "true" ] && echo "❌ Work is INCOMPLETE: $RESULT"
    exit 1
fi
