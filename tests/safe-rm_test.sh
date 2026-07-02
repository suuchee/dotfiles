#!/usr/bin/env bash
# Regression tests for safe-rm.sh.
#
# Locks down which shell commands the hook rewrites to trash (allow), which it
# refuses (deny), and which it leaves untouched (pass-through, exit 0 no output),
# for both HOOK_FORMAT=claude and HOOK_FORMAT=cursor output shapes.
#
# Framework-free: pipes JSON into the hook on stdin and asserts on stdout.
# Exits non-zero and lists the failing cases if any assertion fails.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../private_dot_agents/hooks/executable_safe-rm.sh"

if [ ! -f "$HOOK" ]; then
  echo "FATAL: hook not found at $HOOK" >&2
  exit 1
fi

pass=0
fail=0
skip=0
declare -a failures=()

ok() {
  pass=$((pass + 1))
  printf 'PASS  %s\n' "$1"
}
ng() {
  fail=$((fail + 1))
  failures+=("$1 :: $2")
  printf 'FAIL  %s :: %s\n' "$1" "$2"
}
note_skip() {
  skip=$((skip + 1))
  printf 'SKIP  %s :: %s\n' "$1" "$2"
}

# Build a Claude/Cursor style hook payload with an arbitrary command string.
mk_json() { jq -nc --arg c "$1" '{tool_input: {command: $c}}'; }

# run_hook FORMAT JSON -> sets OUT (stdout) and RC (exit code)
run_hook() {
  local fmt="$1" json="$2"
  OUT=$(printf '%s' "$json" | HOOK_FORMAT="$fmt" bash "$HOOK")
  RC=$?
}

jget() { printf '%s' "$1" | jq -r "$2" 2>/dev/null; }

# Which trash command must exist for allow cases on this host?
case "$(uname -s)" in
  Darwin) TRASH_BIN="trash" ;;
  Linux) TRASH_BIN="trash-put" ;;
  *) TRASH_BIN="" ;;
esac
TRASH_AVAILABLE=0
if [ -n "$TRASH_BIN" ] && command -v "$TRASH_BIN" >/dev/null 2>&1; then
  TRASH_AVAILABLE=1
fi

# check_allow FORMAT CMD EXPECTED_NEW_CMD DESC
check_allow() {
  local fmt="$1" cmd="$2" expected="$3" desc="$4"
  if [ "$TRASH_AVAILABLE" -ne 1 ]; then
    note_skip "$desc" "trash command '$TRASH_BIN' not installed on this host"
    return
  fi
  run_hook "$fmt" "$(mk_json "$cmd")"
  local perm out_cmd msg
  if [ "$fmt" = "cursor" ]; then
    perm=$(jget "$OUT" '.permission')
    out_cmd=$(jget "$OUT" '.updated_input.command')
    msg=$(jget "$OUT" '.agent_message')
  else
    perm=$(jget "$OUT" '.hookSpecificOutput.permissionDecision')
    out_cmd=$(jget "$OUT" '.hookSpecificOutput.updatedInput.command')
    msg=$(jget "$OUT" '.systemMessage')
  fi
  if [ "$perm" = "allow" ] && [ "$out_cmd" = "$expected" ] && [ -n "$msg" ] && [ "$msg" != "null" ]; then
    ok "$desc"
  else
    ng "$desc" "perm='$perm' cmd='$out_cmd' msg='$msg' (want allow / '$expected')"
  fi
}

# check_deny FORMAT CMD DESC
check_deny() {
  local fmt="$1" cmd="$2" desc="$3"
  run_hook "$fmt" "$(mk_json "$cmd")"
  local perm reason
  if [ "$fmt" = "cursor" ]; then
    perm=$(jget "$OUT" '.permission')
    reason=$(jget "$OUT" '.agent_message')
  else
    perm=$(jget "$OUT" '.hookSpecificOutput.permissionDecision')
    reason=$(jget "$OUT" '.hookSpecificOutput.permissionDecisionReason')
  fi
  if [ "$perm" = "deny" ] && [ -n "$reason" ] && [ "$reason" != "null" ]; then
    ok "$desc"
  else
    ng "$desc" "perm='$perm' reason='$reason' (want deny + reason)"
  fi
}

# check_passthrough FORMAT CMD DESC  (raw command string; JSON built here)
check_passthrough() {
  local fmt="$1" cmd="$2" desc="$3"
  run_hook "$fmt" "$(mk_json "$cmd")"
  if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
    ok "$desc"
  else
    ng "$desc" "rc=$RC out='$OUT' (want exit 0 + no output)"
  fi
}

# check_passthrough_raw FORMAT RAW_STDIN DESC  (stdin passed verbatim)
check_passthrough_raw() {
  local fmt="$1" raw="$2" desc="$3"
  OUT=$(printf '%s' "$raw" | HOOK_FORMAT="$fmt" bash "$HOOK")
  RC=$?
  if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
    ok "$desc"
  else
    ng "$desc" "rc=$RC out='$OUT' (want exit 0 + no output)"
  fi
}

for fmt in claude cursor; do
  # --- tier-1 allow: simple rm rewritten to trash, flags stripped ---
  check_allow "$fmt" 'rm foo.txt bar.txt' 'trash foo.txt bar.txt' "[$fmt] rm two files -> trash"
  check_allow "$fmt" 'rm -rf build/' 'trash build/' "[$fmt] rm -rf dir -> trash (flag stripped)"
  check_allow "$fmt" 'rm --force --recursive dir' 'trash dir' "[$fmt] long flags stripped"
  check_allow "$fmt" 'rm -f *.o' 'trash *.o' "[$fmt] rm -f glob -> trash (glob preserved)"

  # --- tier-1 deny: metacharacters / quotes / dash-file after -- ---
  check_deny "$fmt" 'rm "my file.txt"' "[$fmt] quoted arg -> deny"
  check_deny "$fmt" 'rm foo.txt; rm -rf /tmp/x' "[$fmt] semicolon compound -> deny"
  check_deny "$fmt" 'rm -rf dir1 && rm -rf dir2' "[$fmt] && compound -> deny"
  # shellcheck disable=SC2016  # literal '$' is the point: the hook must deny it
  check_deny "$fmt" 'rm $TMPFILE' "[$fmt] variable expansion -> deny"
  check_deny "$fmt" 'rm -- -myfile' "[$fmt] dash-file after -- -> deny"

  # --- tier-2 deny: indirect rm / find deletions ---
  check_deny "$fmt" 'cd /tmp && rm -rf x' "[$fmt] tier-2 rm after && -> deny"
  check_deny "$fmt" 'sudo rm -rf /var/cache/foo' "[$fmt] tier-2 sudo rm -> deny"
  check_deny "$fmt" "find . -name '*.pyc' | xargs rm" "[$fmt] tier-2 xargs rm -> deny"
  check_deny "$fmt" '/bin/rm -rf x' "[$fmt] tier-2 absolute-path rm -> deny"
  check_deny "$fmt" "find . -name '*.pyc' -delete" "[$fmt] tier-2 find -delete -> deny"
  check_deny "$fmt" 'find . -name "*.log" -exec rm {} \;' "[$fmt] tier-2 find -exec rm -> deny"
  # Known false positive (documented): 'rm' inside a quoted commit message after ';'.
  # The heuristic does not parse quotes, so this errs toward deny (safe direction).
  check_deny "$fmt" 'git commit -m "chore; rm unused"' "[$fmt] tier-2 known FP: ; rm in quotes -> deny"
done

# --- pass-through: not a delete, or rm as a mere substring / subcommand ---
for fmt in claude cursor; do
  check_passthrough "$fmt" 'echo hello' "[$fmt] non-rm command -> pass-through"
  check_passthrough "$fmt" 'docker rm -f mycontainer' "[$fmt] docker rm subcommand -> pass-through"
  check_passthrough "$fmt" 'npm rm lodash' "[$fmt] npm rm subcommand -> pass-through"
  check_passthrough "$fmt" 'git rm old.txt' "[$fmt] git rm subcommand -> pass-through"
  check_passthrough "$fmt" 'echo "rm -rf /"' "[$fmt] rm only inside echo string -> pass-through"
done

# --- input handling: invalid JSON must not crash, just pass through ---
check_passthrough_raw claude 'not valid json {{{' "[claude] invalid JSON stdin -> pass-through"
check_passthrough_raw cursor 'not valid json {{{' "[cursor] invalid JSON stdin -> pass-through"

echo
echo "----------------------------------------"
echo "pass=$pass fail=$fail skip=$skip"
if [ "$fail" -gt 0 ]; then
  echo "FAILURES:"
  for f in "${failures[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
echo "ALL TESTS PASSED"
exit 0
