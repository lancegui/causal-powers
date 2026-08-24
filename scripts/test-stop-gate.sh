#!/usr/bin/env bash
# Deterministic harness for hooks/stop-gate: synthetic single-line JSONL
# transcripts + a temp opt-in project, asserting block / no-block on stdout.
# Run: bash scripts/test-stop-gate.sh   (exit 0 = all cases pass)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$ROOT/hooks/stop-gate"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/cp-stopgate-test-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
fails=0

# one-line JSONL entries in the canonical transcript shape
write_line() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"%s","input":{"file_path":"%s","content":"x"}}]}}\n' "$1" "$2"; }
skill_line() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"%s"}}]}}\n' "$1"; }
bash_line()  { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"Rscript verify.R"}}]}}\n'; }

run_case() { # $1 name  $2 expect: block|silent  $3 transcript-file  $4 session-id
  # env -u LANG -u LC_ALL mirrors the hook runtime (C locale) — a UTF-8 dev shell
  # masks locale-dependent grep behavior (the [^\n] bug shipped exactly that way).
  local out; out="$(printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s"}' "$4" "$3" "$PROJ" \
    | env -u LANG -u LC_ALL bash "$GATE")"
  local got="silent"; printf '%s' "$out" | grep -q '"decision": *"block"' && got="block"
  if [ "$got" = "$2" ]; then echo "PASS  $1"; else echo "FAIL  $1 (expected $2, got $got)"; fails=$((fails+1)); fi
}

PROJ="$WORK/proj"; mkdir -p "$PROJ"; : > "$PROJ/analysis-plan.md"

# 1: real-world deliverable names, no verification -> SILENT.
#    result-verification is user-invoked; the hook records it in the ledger but
#    must never block on it. This case guards against re-adding that gate.
T="$WORK/t1.jsonl"; { write_line Write "$PROJ/output/tab_did_main.tex"; write_line Write "$PROJ/figures/fig1_trend.png"; } > "$T"
run_case "deliverable-paths-never-block" silent "$T" "s1-$$"

# 2: results write + verification skill + execution after -> silent
T="$WORK/t2.jsonl"; { write_line Write "$PROJ/results-summary.md"; skill_line "causal-powers:result-verification"; bash_line; } > "$T"
run_case "verified-with-evidence-silent" silent "$T" "s2-$$"

# 3: plan + script writes only -> silent (analysis-plan.md is not a deliverable)
T="$WORK/t3.jsonl"; { write_line Write "$PROJ/analysis-plan.md"; write_line Edit "$PROJ/scripts/clean.R"; } > "$T"
run_case "plan-and-scripts-silent" silent "$T" "s3-$$"

# 4: debugging fired, LESSONS.md then edited -> lesson gate satisfied, silent
T="$WORK/t4.jsonl"; { skill_line "causal-powers:wrong-number-debugging"; write_line Edit "$PROJ/docs/LESSONS.md"; } > "$T"
run_case "lesson-written-silent" silent "$T" "s4-$$"

# 4b: debugging fired, no lesson -> nudge (block)
T="$WORK/t4b.jsonl"; skill_line "causal-powers:wrong-number-debugging" > "$T"
run_case "lesson-missing-nudges" block "$T" "s4b-$$"

# 5: results write + verification skill invoked but NOTHING ran after -> silent
#    (the ledger records verified=0 here, but an unverified result never blocks)
T="$WORK/t5.jsonl"; { write_line Write "$PROJ/results-summary.md"; skill_line "causal-powers:result-verification"; } > "$T"
run_case "verified-without-evidence-still-silent" silent "$T" "s5-$$"

# 6: a Write to a non-deliverable path (scratch note) -> silent
#    (must NOT match the wrote_results detector; nothing else fires either)
T="$WORK/t6.jsonl"; write_line Write "$PROJ/sandbox/scratch_notes.txt" > "$T"
run_case "non-deliverable-write-silent" silent "$T" "s6-$$"

# 7: a Write to a non-LESSONS docs file, after debugging fired -> still nudges
#    (must NOT satisfy the lessons_touched detector just because docs/ was touched)
T="$WORK/t7.jsonl"; { skill_line "causal-powers:wrong-number-debugging"; write_line Write "$PROJ/docs/lessons-draft.md"; } > "$T"
run_case "near-miss-lessons-filename-still-nudges" block "$T" "s7-$$"

# --- Detector-level regression tests -----------------------------------
# The cases above only see block/silent outcomes from the whole hook, which
# can mask a broken detector if other logic happens to net out the same
# result. These tests isolate the wrote_results and lessons_touched grep
# patterns directly (extracted live from hooks/stop-gate, so they can't drift
# out of sync with what actually ships) and separately reconstruct the
# pre-fix (buggy) patterns purely as a historical regression check — never
# used at runtime, never re-added to the hook.
#
# Root cause recap (see hooks/stop-gate's own comment for the full version):
# POSIX gives backslash no escaping power inside a bracket expression, so
# [^\n] means "not backslash, not the letter n" -- two literal characters --
# not "not a newline". BSD grep (macOS, and this hook's own no-LANG/no-LC_ALL
# runtime) takes that reading strictly, so [^\n] silently broke both
# detectors in production (every real transcript line has an 'n' in the
# ,"input":{ gap between the tool name and file_path). GNU grep's glibc
# engine treats \n inside brackets as a real newline escape in many locales,
# so the identical pattern can look correct in a typical GNU/Linux dev shell
# and only fail once it reaches this hook's locale-less runtime -- which is
# exactly how the bug shipped unnoticed.

extract_grep_pattern() { # $1 = variable this detector sets, e.g. wrote_results=1
  sed -n "s/.*grep -Eq '\(.*\)' && $1.*/\1/p" "$GATE" | head -1
}
WROTE_RESULTS_RE="$(extract_grep_pattern 'wrote_results=1')"
LESSONS_RE="$(extract_grep_pattern 'lessons_touched=1')"
if [ -z "$WROTE_RESULTS_RE" ] || [ -z "$LESSONS_RE" ]; then
  echo "FAIL  detector-pattern-extraction (could not extract from $GATE -- hook shape changed?)"
  fails=$((fails+1))
fi

# Pre-fix patterns, preserved ONLY as a regression fixture (this is what
# hooks/stop-gate looked like before commit 1904c2c; DO NOT copy these back
# into the hook).
WROTE_RESULTS_RE_BUGGY='"name":[[:space:]]*"(Write|Edit|NotebookEdit)"[^\n]*"file_path":[[:space:]]*"[^"]*(results?|summary|findings|estimates|tables?)[^"]*\.(md|csv|tex|txt|html)"'
LESSONS_RE_BUGGY='"name":[[:space:]]*"(Write|Edit)"[^\n]*"file_path":[[:space:]]*"[^"]*LESSONS\.md"'

check_re() { # $1 label  $2 regex  $3 fixture-line  $4 expect: match|nomatch
  # Same C-locale runtime as run_case above -- this is the exact condition
  # under which the buggy pattern failed silently in production.
  local got="nomatch"
  printf '%s\n' "$3" | env -u LANG -u LC_ALL grep -Eq "$2" && got="match"
  if [ "$got" = "$4" ]; then echo "PASS  $1"; else echo "FAIL  $1 (expected $4, got $got)"; fails=$((fails+1)); fi
}

REAL_DELIVERABLE_LINE="$(write_line Write "$PROJ/output/results_summary.md")"
WRONG_TOOL_LINE="$(printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{"file_path":"%s"}}]}}\n' "$PROJ/output/results_summary.md")"
NON_DELIVERABLE_PATH_LINE="$(write_line Write "$PROJ/scratch/notes.txt")"
LESSONS_EDIT_LINE="$(write_line Edit "$PROJ/docs/LESSONS.md")"
NEAR_MISS_LESSONS_LINE="$(write_line Write "$PROJ/docs/lessons-draft.md")"

# (a) fixed detectors: fixture that MUST match, fixture that must NOT.
check_re "wrote_results(fixed)-matches-real-deliverable" "$WROTE_RESULTS_RE" "$REAL_DELIVERABLE_LINE" match
check_re "wrote_results(fixed)-no-match-wrong-tool" "$WROTE_RESULTS_RE" "$WRONG_TOOL_LINE" nomatch
check_re "wrote_results(fixed)-no-match-non-deliverable-path" "$WROTE_RESULTS_RE" "$NON_DELIVERABLE_PATH_LINE" nomatch
check_re "lessons(fixed)-matches-LESSONS-edit" "$LESSONS_RE" "$LESSONS_EDIT_LINE" match
check_re "lessons(fixed)-no-match-near-miss-filename" "$LESSONS_RE" "$NEAR_MISS_LESSONS_LINE" nomatch

# (b) the fixture the buggy pattern misses but the fixed pattern catches --
# this is the test that would have caught the original bug before it shipped.
check_re "wrote_results(BUGGY)-misses-real-deliverable-regression" "$WROTE_RESULTS_RE_BUGGY" "$REAL_DELIVERABLE_LINE" nomatch
check_re "lessons(BUGGY)-misses-LESSONS-edit-regression" "$LESSONS_RE_BUGGY" "$LESSONS_EDIT_LINE" nomatch

echo "----"
[ "$fails" -eq 0 ] && echo "ALL PASS" || echo "$fails FAILURE(S)"
exit "$fails"
