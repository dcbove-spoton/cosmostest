#!/bin/bash
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
PERMISSIONS_FILE="$HOOK_DIR/../permissions.json"
COMMAND=$(jq -r '.tool_input.command')

# Convert each deny glob pattern to a regex and check against the command
while IFS= read -r pattern; do
  # Convert glob * to regex .* and escape spaces
  regex="^$(echo "$pattern" | sed 's/\*/.*/')"
  if echo "$COMMAND" | grep -qE "$regex"; then
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Command blocked by hook (matched deny pattern)"
      }
    }'
    exit 0
  fi
done < <(jq -r '.shell.deny[]' "$PERMISSIONS_FILE")

exit 0
