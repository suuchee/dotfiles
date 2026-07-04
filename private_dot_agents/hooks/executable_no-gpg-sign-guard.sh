#!/usr/bin/env bash
# no-gpg-sign-guard.sh - PreToolUse hook that forces agent commits/tags to be unsigned.
#
# Canonical hook at ~/.agents/hooks/no-gpg-sign-guard.sh.
# Wrappers in ~/.claude/hooks (and future ~/.cursor/hooks) set HOOK_FORMAT.
#
# 方針: エージェントは署名しない (see ~/.claude/skills/git/references/signing.md)。
#   - `git commit ...` に `--no-gpg-sign` が含まれない場合は deny する
#     （commit.gpgsign=true 環境で意図せず署名処理が走るのを防ぐため）。
#   - `git merge / cherry-pick / revert` も commit.gpgsign=true では署名コミットを
#     作成するため同様に deny する。コミットを作らない形態（--abort / --quit /
#     --skip / -n / --no-commit、merge の --ff-only / --squash）と、オプションを
#     追加できない --continue は素通し。
#   - `git tag ...` に署名系オプション（-s / --sign / -u / --local-user）が
#     含まれる場合は deny する。軽量タグ・`-a` の注釈タグは素通し。
#   - 上記以外の Bash コマンドは素通し。
#   入力 JSON を解釈できない場合は素通しする (fail-open)。

set -euo pipefail

HOOK_FORMAT="${HOOK_FORMAT:-claude}"

DENY_COMMIT="no-gpg-sign-guard: エージェントは署名なしでコミットするポリシー。git commit に --no-gpg-sign を付けて再実行してください (--amend も同様)。詳細: ~/.claude/skills/git/references/signing.md"

DENY_TAG="no-gpg-sign-guard: エージェントは署名タグを作らないポリシー。-s / --sign / -u / --local-user を外して軽量タグまたは -a による注釈タグとして再実行してください。詳細: ~/.claude/skills/git/references/signing.md"

emit_deny() {
  local reason="$1"
  case "$HOOK_FORMAT" in
    cursor)
      jq -n --arg msg "$reason" '{"permission": "deny", "agent_message": $msg}'
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

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -z "$CMD" ] && exit 0

# Split into tokens by whitespace. Keep it simple — same heuristic level as safe-rm.
# Complex quoting/metachar cases fall through to allow; the intent is to catch
# the common `git commit ...` / `git tag ...` forms Claude actually emits.
# shellcheck disable=SC2206
TOKENS=($CMD)

# Walk tokens to find the first `git commit` or `git tag` invocation.
# Also handle a leading `git -c foo=bar commit ...` form by skipping -c NAME=VAL pairs.
i=0
n=${#TOKENS[@]}
while [ "$i" -lt "$n" ]; do
  tok="${TOKENS[$i]}"
  if [ "$tok" != "git" ]; then
    i=$((i + 1))
    continue
  fi

  # Advance past `git` and global options that take a value
  # (`-c key=val` / `-C path` / `--git-dir path` / `--work-tree path`,
  #  and their attached forms `-cX` / `-CX` / `--git-dir=X` / `--work-tree=X`).
  j=$((i + 1))
  while [ "$j" -lt "$n" ]; do
    t="${TOKENS[$j]}"
    if [ "$t" = "-c" ] || [ "$t" = "--config" ] || [ "$t" = "-C" ] || [ "$t" = "--git-dir" ] || [ "$t" = "--work-tree" ]; then
      j=$((j + 2))
      continue
    fi
    case "$t" in
      -c?*|-C?*|--git-dir=*|--work-tree=*)
        j=$((j + 1))
        continue
        ;;
    esac
    break
  done

  [ "$j" -ge "$n" ] && break
  sub="${TOKENS[$j]}"

  case "$sub" in
    commit|merge|cherry-pick|revert)
      # Look for --no-gpg-sign anywhere after the subcommand (until the next
      # `&&`/`;`/`|` — tokenized already, so we just scan remaining tokens).
      has_flag=0
      k=$((j + 1))
      while [ "$k" -lt "$n" ]; do
        t2="${TOKENS[$k]}"
        case "$t2" in
          --no-gpg-sign|--no-gpg-sign=*) has_flag=1; break ;;
          "&&"|"||"|";"|"|") break ;;
        esac
        # merge / cherry-pick / revert: コミットを作らない形態と、オプションを
        # 追加できない --continue は署名処理が走らない（または対処不能）ので素通し。
        if [ "$sub" != "commit" ]; then
          case "$t2" in
            --abort|--quit|--skip|--continue|-n|--no-commit)
              has_flag=1
              break
              ;;
            --ff-only|--squash)
              if [ "$sub" = "merge" ]; then
                has_flag=1
                break
              fi
              ;;
          esac
        fi
        k=$((k + 1))
      done
      if [ "$has_flag" -eq 0 ]; then
        if [ "$sub" = "commit" ]; then
          emit_deny "$DENY_COMMIT"
        else
          emit_deny "no-gpg-sign-guard: エージェントは署名なしでコミットするポリシー。git $sub は commit.gpgsign=true の環境で署名コミットを作成するため、--no-gpg-sign を付けて再実行してください。詳細: ~/.claude/skills/git/references/signing.md"
        fi
      fi
      ;;
    tag)
      # Deny if any signing flag appears in this tag invocation.
      k=$((j + 1))
      while [ "$k" -lt "$n" ]; do
        case "${TOKENS[$k]}" in
          -s|--sign|-u|--local-user|--local-user=*) emit_deny "$DENY_TAG" ;;
          "&&"|"||"|";"|"|") break ;;
        esac
        k=$((k + 1))
      done
      ;;
  esac

  i=$((j + 1))
done

exit 0
