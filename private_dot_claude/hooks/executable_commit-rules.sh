#!/bin/bash
# commit-rules.sh - Inject commit operational rules before git commit
#
# PreToolUse:Bash hook
# Outputs commit rules as JSON systemMessage for Claude Code.

set -euo pipefail

RULES_FILE="${HOME}/.claude/skills/git/references/commit-rules.md"

if [ ! -f "$RULES_FILE" ]; then
  jq -n --arg path "$RULES_FILE" \
    '{"systemMessage": ("commit-rules.md not found: " + $path)}'
  exit 0
fi

jq -n --rawfile content "$RULES_FILE" \
  '{"systemMessage": ("コミット運用ルール:\n\n" + $content)}'
