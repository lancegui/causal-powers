#!/usr/bin/env bash
# Harness for scripts/install-codex.sh: fake source tree + --project target;
# asserts only real skills (dirs containing SKILL.md) install, stale junk is
# pruned on refresh, and the managed block is version-stamped + idempotent.
# Run: bash scripts/test-install-codex.sh
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/cp-install-test-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
fails=0
check() { # $1 desc  $2 cmd...
  local d="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "PASS  $d"; else echo "FAIL  $d"; fails=$((fails+1)); fi
}

# fake source: one real skill, one junk workspace dir, minimal metadata; the
# installer resolves SRC from its own location, so plant a copy inside.
SRC="$WORK/src"
mkdir -p "$SRC/skills/real-skill" "$SRC/skills/junk-workspace/iteration-1" "$SRC/hooks" "$SRC/.claude-plugin" "$SRC/scripts"
printf -- '---\nname: real-skill\ndescription: Use when testing.\n---\n# Real\n' > "$SRC/skills/real-skill/SKILL.md"
printf 'not a skill\n' > "$SRC/skills/junk-workspace/iteration-1/notes.md"
printf '# Card\ndiscipline text\n' > "$SRC/hooks/session-context.md"
printf '{"name": "causal-powers", "version": "9.9.9"}\n' > "$SRC/.claude-plugin/plugin.json"
cp "$ROOT/scripts/install-codex.sh" "$SRC/scripts/install-codex.sh"

TARGET="$WORK/target"; mkdir -p "$TARGET"
run_install() { bash "$SRC/scripts/install-codex.sh" --project "$TARGET" "$@"; }

run_install >/dev/null 2>&1
check "installs the real skill"        test -f "$TARGET/.agents/skills/real-skill/SKILL.md"
check "skips SKILL.md-less dirs"       test ! -e "$TARGET/.agents/skills/junk-workspace"
check "managed block written"          grep -q "discipline text" "$TARGET/AGENTS.md"
check "block is version-stamped"       grep -q "causal-powers:v9.9.9" "$TARGET/AGENTS.md"

# refresh must prune junk an older (unfiltered) installer copied, and stay idempotent
mkdir -p "$TARGET/.agents/skills/junk-workspace"
printf 'stale\n' > "$TARGET/.agents/skills/junk-workspace/notes.md"
run_install >/dev/null 2>&1
check "refresh prunes stale junk dir"  test ! -e "$TARGET/.agents/skills/junk-workspace"
check "refresh idempotent (1 block)"   test "$(grep -c 'causal-powers:begin' "$TARGET/AGENTS.md")" = 1

echo "----"
[ "$fails" -eq 0 ] && echo "ALL PASS" || echo "$fails FAILURE(S)"
exit "$fails"
