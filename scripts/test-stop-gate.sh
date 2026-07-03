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

# 1: real-world deliverable names, no verification -> block
T="$WORK/t1.jsonl"; { write_line Write "$PROJ/output/tab_did_main.tex"; write_line Write "$PROJ/figures/fig1_trend.png"; } > "$T"
run_case "deliverable-paths-block" block "$T" "s1-$$"

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

# 5: results write + verification skill invoked but NOTHING ran after -> block
#    (invoking the skill alone is not evidence)
T="$WORK/t5.jsonl"; { write_line Write "$PROJ/results-summary.md"; skill_line "causal-powers:result-verification"; } > "$T"
run_case "verified-without-evidence-blocks" block "$T" "s5-$$"

echo "----"
[ "$fails" -eq 0 ] && echo "ALL PASS" || echo "$fails FAILURE(S)"
exit "$fails"
