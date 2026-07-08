#!/bin/bash
# inject-opus48-rules.sh - SessionStart hook
#
# Opus 4.8 で観測される不安定な挙動（割り込みマーカー・ツールエラー・compaction を
# 新規のユーザー要求と誤認する等）を抑えるための信頼性ルールを、セッションのモデルが
# opus-4-8 のときだけメインコンテキストへ注入する。他モデルには無関係なので注入しない。
#
# ルール本文は opus48-reliability-rules.md を単一ソースとして参照する（サブエージェント
# へは hook では注入せず、4.8 のとき同ファイルの内容を手動でプロンプトに同梱する運用。
# 詳細は ~/.claude/CLAUDE.md「自律実行とサブエージェント」を参照）。
#
# stdin : SessionStart hook の JSON（.model に解決済みモデル ID が入る）
# stdout: hookSpecificOutput.additionalContext（.model が opus-4-8 のときのみ）

set -euo pipefail

RULES_FILE="${HOME}/.claude/hooks/opus48-reliability-rules.md"

input="$(cat)"
model="$(printf '%s' "$input" | jq -r '.model // empty')"

# opus-4-8 系のみ対象。エイリアス(opus)や将来の別バージョンには反応させない。
case "$model" in
  *opus-4-8*) ;;
  *) exit 0 ;;
esac

if [ ! -f "$RULES_FILE" ]; then
  printf 'reliability rules file not found: %s\n' "$RULES_FILE" >&2
  exit 0
fi

jq -n --rawfile ctx "$RULES_FILE" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
