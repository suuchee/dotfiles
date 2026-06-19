#!/usr/bin/env bash
# safe-rm.sh - Intercept rm commands and redirect to trash on macOS/Linux
#
# Shared hook for Claude Code (PreToolUse) and Cursor (preToolUse).
# Set HOOK_FORMAT=claude|cursor via the wrapper in ~/.claude/hooks or ~/.cursor/hooks.
#
# rm <files...> → trash (macOS) / trash-put (Linux)
# -r / -rf 等のフラグは剥がして trash に渡す（trash はディレクトリも再帰でゴミ箱送り）。

set -euo pipefail

HOOK_FORMAT="${HOOK_FORMAT:-claude}"

INPUT=$(cat)

if echo "$INPUT" | jq -e '.tool_input.command' >/dev/null 2>&1; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')
elif echo "$INPUT" | jq -e '.command' >/dev/null 2>&1; then
  COMMAND=$(echo "$INPUT" | jq -r '.command')
else
  exit 0
fi

# Only intercept commands starting with "rm " (not rmdir, etc.)
if [[ ! "$COMMAND" =~ ^rm[[:space:]] ]]; then
  exit 0
fi

# Extract file paths: strip "rm" and any flags (-r, -rf, -f, -i, -v, etc.)
FILES=$(echo "$COMMAND" | sed -E 's/^rm[[:space:]]+//' | sed -E 's/(^|[[:space:]])-[a-zA-Z]+//g' | xargs)

if [ -z "$FILES" ]; then
  exit 0
fi

OS=$(uname -s)
case "$OS" in
  Darwin)
    NEW_CMD="trash $FILES"
    ;;
  Linux)
    NEW_CMD="trash-put $FILES"
    ;;
  *)
    case "$HOOK_FORMAT" in
      cursor)
        jq -n --arg os "$OS" '{
          "permission": "deny",
          "agent_message": ("Unknown OS (" + $os + "): rm was not redirected to trash")
        }'
        ;;
      *)
        echo "{\"systemMessage\": \"Unknown OS ($OS): rm was not redirected to trash\"}"
        ;;
    esac
    exit 0
    ;;
esac

MSG="rm → trash: $NEW_CMD"

case "$HOOK_FORMAT" in
  cursor)
    jq -n --arg cmd "$NEW_CMD" --arg msg "$MSG" '{
      "permission": "allow",
      "updated_input": {"command": $cmd},
      "agent_message": $msg
    }'
    ;;
  *)
    jq -n --arg cmd "$NEW_CMD" --arg msg "$MSG" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "updatedInput": {"command": $cmd}
      },
      "systemMessage": $msg
    }'
    ;;
esac
