#!/usr/bin/env bash
# Description hill-climbing for one skill, via the official skill-creator
# harness (anthropics/skills): evaluates the current description against the
# skill's trigger-eval corpus, asks a model to propose improvements from the
# failures, re-evaluates train + held-out test, and iterates — returning the
# best description BY TEST SCORE (anti-overfit).
#
# Usage:
#   scripts/optimize-description.sh <skill-name> [model] [max-iterations]
#   scripts/optimize-description.sh question-framing claude-haiku-4-5 3
#
# Notes:
# - Eval set = evals/trigger/<skill>.json (the same corpus the trigger CI uses;
#   the [{query, should_trigger}] format is what run_loop expects natively).
# - The harness writes TEMP candidate skills into ~/.claude/commands/ during
#   the run (they appear in live sessions' skill lists and are cleaned up per
#   iteration) and measures triggering against YOUR live config — installed
#   plugins compete, which is realistic and constant across candidates.
# - The winner is NOT auto-applied: read the report, then update the skill's
#   frontmatter yourself and re-run scripts/eval-triggers.py for the router CI.

set -euo pipefail
SKILL="${1:?usage: optimize-description.sh <skill-name> [model] [max-iterations]}"
MODEL="${2:-claude-haiku-4-5}"
ITERS="${3:-3}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVAL="${ROOT}/evals/trigger/${SKILL}.json"
SKILL_DIR="${ROOT}/skills/${SKILL}"
[ -f "$EVAL" ] || { echo "no eval set: $EVAL"; exit 1; }
[ -d "$SKILL_DIR" ] || { echo "no skill: $SKILL_DIR"; exit 1; }

SC="$(ls -d "$HOME"/.claude/plugins/cache/*/skill-creator/*/skills/skill-creator 2>/dev/null | head -1)"
[ -n "$SC" ] || { echo "skill-creator plugin not found (install it via /plugin)"; exit 1; }

OUT="${TMPDIR:-/tmp}/cp-descopt-${SKILL}"
mkdir -p "$OUT"
echo "optimizing ${SKILL} (model=${MODEL}, iterations=${ITERS}) -> ${OUT}"
cd "$SC"
exec python3 -m scripts.run_loop \
  --eval-set "$EVAL" --skill-path "$SKILL_DIR" \
  --model "$MODEL" --max-iterations "$ITERS" --runs-per-query 2 --num-workers 8 \
  --results-dir "$OUT" --report "$OUT/report.html" --verbose
