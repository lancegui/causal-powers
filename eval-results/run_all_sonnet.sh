#!/bin/zsh
set -u
SC="/Users/lancegui/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/bd8efbe2-397c-4a43-80e8-758dcc2752c2/9c1da002-8471-48c4-92a7-2ffea3f739d7/skills/skill-creator"
REPO=~/Developer/causal-powers
MODEL=claude-sonnet-4-6
cd "$SC" || exit 1

for skill in causal-identification wrong-number-debugging data-contracts; do
  echo "################## $skill ($(date)) ##################"
  python3 -m scripts.run_loop \
    --eval-set "$REPO/evals/trigger/$skill.json" \
    --skill-path "$REPO/skills/$skill" \
    --model "$MODEL" \
    --max-iterations 4 \
    --verbose \
    --report none \
    --results-dir "$REPO/eval-results/$skill" \
    2>&1
  echo "################## DONE $skill (exit $?) ##################"
done
echo "ALL_DONE"
