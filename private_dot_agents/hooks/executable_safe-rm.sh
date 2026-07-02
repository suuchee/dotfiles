#!/usr/bin/env bash
# safe-rm.sh - PreToolUse hook that redirects safe `rm` commands to the trash.
#
# Canonical hook at ~/.agents/hooks/safe-rm.sh.
# Wrappers in ~/.claude/hooks and ~/.cursor/hooks set HOOK_FORMAT (claude|cursor).
#
# 挙動:
#   tier-1（先頭コマンドが rm）:
#   - `rm <paths...>` （フラグは -rf / --force 等）は `trash <paths...>` (macOS) /
#     `trash-put <paths...>` (Linux) へ書き換えて allow する。trash はディレクトリも
#     再帰でゴミ箱送りするため、-r/-f 等のフラグは除去して渡す。
#   - シェルのメタ文字（; | & $ ` " ' \ ( ) < > と改行/CR）、`--` 越しのフラグ引数、
#     未知のフラグを含む rm は、安全に書き換えられないため deny する。
#     （例: `rm a; rm -rf b` を素朴に書き換えると 2 個目が実 rm のまま残り恒久削除される、
#      クォート付き `rm "my file"` が語分割で 2 引数に割れる、といった事故を防ぐ）
#   - ファイル引数の無い rm（`rm -i` 等）は素通しする。
#   - trash / trash-put が無い、または OS 不明の場合は deny する（安全側に倒す）。
#   tier-2（先頭が rm でない）:
#   - 複合コマンド・sudo/xargs 経由・絶対パス /bin/rm・find -delete/-exec rm 等、
#     間接的にファイルを消す形は書き換え不能なため deny のみ行う（書き換えはしない）。
#     クォート文脈は解釈しないヒューリスティックで、誤検知は deny（安全方向）に倒す。
#   - それ以外（rm を含まない普通のコマンド）は素通しする。
#   入力 JSON を解釈できない場合は素通しする（fail-open）。
#
# 発火は settings.json の `if: "Bash(rm:*)"` が制御する。Claude Code は複合コマンドを
# quote-aware で演算子分割し各サブコマンドを評価するので、ゲートは `cd x && rm ...` で
# 発火し、クォート内の rm（コミットメッセージ等）では発火しない。判定はゲートに委ね、
# スクリプトの正規表現マッチは補助（生文字列マッチは quote 非対応で誤検知しうる）。

set -euo pipefail

HOOK_FORMAT="${HOOK_FORMAT:-claude}"

DENY_COMPLEX="safe-rm hook: this rm command contains shell metacharacters (or unusual arguments) and cannot be safely rewritten. Move files to trash instead: use \`trash <paths...>\` (macOS) / \`trash-put <paths...>\` (Linux) directly, or re-run as a plain \`rm <paths...>\` command."

DENY_INDIRECT="safe-rm hook: this command deletes files in a form that cannot be safely rewritten to trash (compound command, sudo, xargs, find, or absolute-path rm). Move files to trash instead: \`trash <paths...>\` (macOS) / \`trash-put <paths...>\` (Linux), or re-run as a standalone plain \`rm <paths...>\` command (it will be rewritten to trash automatically)."

emit_deny() {
  local reason="$1"
  case "$HOOK_FORMAT" in
    cursor)
      jq -n --arg msg "$reason" '{
        "permission": "deny",
        "agent_message": $msg
      }'
      ;;
    *)
      jq -n --arg msg "$reason" '{
        "hookSpecificOutput": {
          "hookEventName": "PreToolUse",
          "permissionDecision": "deny",
          "permissionDecisionReason": $msg
        }
      }'
      ;;
  esac
  exit 0
}

emit_allow() {
  local cmd="$1"
  local msg="rm → trash: $cmd"
  case "$HOOK_FORMAT" in
    cursor)
      jq -n --arg cmd "$cmd" --arg msg "$msg" '{
        "permission": "allow",
        "updated_input": {"command": $cmd},
        "agent_message": $msg
      }'
      ;;
    *)
      jq -n --arg cmd "$cmd" --arg msg "$msg" '{
        "hookSpecificOutput": {
          "hookEventName": "PreToolUse",
          "permissionDecision": "allow",
          "updatedInput": {"command": $cmd}
        },
        "systemMessage": $msg
      }'
      ;;
  esac
  exit 0
}

INPUT=$(cat)

# 1. Extract the command (Claude: .tool_input.command, Cursor: .tool_input.command
#    or legacy .command). Invalid JSON / missing command → pass through.
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null) || exit 0
if [ -z "$COMMAND" ]; then
  exit 0
fi

# 2. tier-1 applies only when the first word is rm (not rmdir, not `cd .. && rm`).
#    Otherwise fall through to tier-2, which denies indirect rm without rewriting.
if [[ ! "$COMMAND" =~ ^[[:space:]]*rm[[:space:]] ]]; then
  # --- tier-2: refuse rm reached indirectly (cannot be safely rewritten) ---
  # Heuristic only; quote context is not parsed, so false positives err toward deny.
  NL=$'\n'
  # rm in command position: right after a separator (; & | ( ` newline), through a
  # command prefix (sudo/command/nohup/nice/time/env/xargs, flags allowed), or via an
  # absolute path (/bin/rm, /usr/bin/rm, /sbin/rm, ...).
  sep_class='[;&|(`'"$NL"']'
  cmd_rm_re='(^|'"$sep_class"')[[:space:]]*((sudo|command|nohup|nice|time|env|xargs)([[:space:]]+-[^[:space:]]+)*[[:space:]]+)*((/usr)?/s?bin/)?rm([[:space:]]|$)'
  if [[ "$COMMAND" =~ $cmd_rm_re ]]; then
    emit_deny "$DENY_INDIRECT"
  fi
  # find ... -delete / -exec rm ... (and -execdir/-ok/-okdir variants).
  find_word_re='(^|[^[:alnum:]_])find([^[:alnum:]_]|$)'
  find_action_re='-(exec|execdir|ok|okdir)[[:space:]]'
  find_delete_re='(^|[[:space:]])-delete([[:space:]]|$)'
  if [[ "$COMMAND" =~ $find_word_re ]] &&
    { [[ "$COMMAND" =~ $find_action_re ]] || [[ "$COMMAND" =~ $find_delete_re ]]; }; then
    emit_deny "$DENY_INDIRECT"
  fi
  exit 0
fi

# 3. Refuse anything containing shell metacharacters, quotes, escapes, or newlines:
#    once these are present, word-splitting the command is no longer safe.
# Each metacharacter is individually quoted so it is matched literally.
# shellcheck disable=SC1003  # *"'"* deliberately matches a literal single quote
case "$COMMAND" in
  *";"* | *"|"* | *"&"* | *'$'* | *'`'* | *'"'* | *"'"* | *'\'* | *"("* | *")"* | *"<"* | *">"* )
    emit_deny "$DENY_COMPLEX"
    ;;
esac
if [[ "$COMMAND" == *$'\n'* || "$COMMAND" == *$'\r'* ]]; then
  emit_deny "$DENY_COMPLEX"
fi

# 4. Word-split (safe now: no metacharacters) and classify tokens after leading rm.
read -ra TOKENS <<< "$COMMAND"

FILES=()
after_ddash=0
for ((i = 1; i < ${#TOKENS[@]}; i++)); do
  tok="${TOKENS[i]}"

  if [ "$after_ddash" -eq 1 ]; then
    # Everything after `--` is a filename. A `-`-leading name would need `--`
    # protection that trash may not support → deny rather than risk it.
    case "$tok" in
      -*) emit_deny "$DENY_COMPLEX" ;;
      *) FILES+=("$tok") ;;
    esac
    continue
  fi

  if [[ "$tok" == "--" ]]; then
    after_ddash=1
  elif [[ "$tok" =~ ^-[a-zA-Z]+$ ]]; then
    : # short flag bundle (-r, -rf, -f, -i, -v ...) → drop
  elif [[ "$tok" =~ ^--[a-zA-Z][a-zA-Z-]*(=[^[:space:]]*)?$ ]]; then
    : # long flag (--force, --recursive, --one-file-system=... ) → drop
  elif [[ "$tok" == -* ]]; then
    emit_deny "$DENY_COMPLEX" # unrecognized dash-argument
  else
    FILES+=("$tok")
  fi
done

# 5. No file operands (e.g. `rm -i`) → nothing to trash, pass through untouched.
if [ "${#FILES[@]}" -eq 0 ]; then
  exit 0
fi

# 6. Pick the trash command for this OS; deny if unavailable or OS is unknown.
OS=$(uname -s)
case "$OS" in
  Darwin) TRASH="trash" ;;
  Linux) TRASH="trash-put" ;;
  *)
    emit_deny "safe-rm hook: unsupported OS '$OS'; cannot determine a trash command. Move the files to the trash manually instead of using rm."
    ;;
esac

if ! command -v "$TRASH" >/dev/null 2>&1; then
  if [ "$TRASH" = "trash" ]; then
    emit_deny "safe-rm hook: \`trash\` is not installed, so rm cannot be redirected to the trash. Install it (\`brew install trash\`) and retry, or move the files to the trash manually."
  else
    emit_deny "safe-rm hook: \`trash-put\` is not installed, so rm cannot be redirected to the trash. Install trash-cli (\`apt install trash-cli\` or your package manager) and retry, or move the files to the trash manually."
  fi
fi

# 7. Rewrite to a plain `trash <files...>` (operands are metacharacter-free tokens).
NEW_CMD="$TRASH ${FILES[*]}"
emit_allow "$NEW_CMD"
