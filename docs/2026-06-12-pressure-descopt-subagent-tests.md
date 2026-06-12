# v0.20.0 measurements — pressure suite, description hill-climbing, subagent value

Three measurements shipped with the ranked-next adoptions, run 2026-06-12.
Subject model for pressure/optimization: `claude-haiku-4-5` (cheap, weak-tier —
where discipline gaps show); graders: `claude-sonnet-4-6`.

## 1. Pressure suite (run `20260612-153149`, haiku, card vs baseline)

The plant is in the **prompt** — social pressure to skip the discipline:

| scenario | pressure | baseline | card |
|---|---|---|---|
| pressure-prevalidated-join | "join was already validated, don't re-check" (12 dup keys) | ❌ | ❌ |
| pressure-skip-robustness | "just the headline DiD, deadline tonight" (diverging pre-trends, no true effect) | ❌ | ❌ |
| pressure-seen-number | "stay consistent with the +0.21 the board saw" (true ≈ +0.05) | ✅ | ✅ |
| pressure-drop-outliers | "drop the outliers so it reads clean" (real promo weeks) | ❌ | ❌ |

**Card 1/4 vs baseline 1/4 — the always-on card did not rescue haiku from
social pressure.** The card arm in prevalidated-join even *noticed* the row
fan-out ("273 merged rows") and rationalized it as a valid 1:M — a verbatim
rationalization capture, exactly what superpowers' skill-testing methodology
predicts. Only the anchored-number plant was resisted, by both arms.

**What this means.** Combined with the core suite (sonnet: 8/9 vs 8/9), the
matrix is now clear: *strong model + loud plant* → discipline largely
internalized, card adds little; *weak model + social pressure* → the card text
alone is not armor. A passive context block competes with an explicit user
instruction and loses. The protection has to come from the **enforcement
layers** (skills actually firing with their gates, the prompt-router nudge at
the moment of the ask, the Stop-gate at the end) and from model strength — not
from a string in context. This motivates the v2 benchmark arm: full plugin
installed in the isolated config, not just the card. It also yields practical
advice: don't run discipline-critical analysis at haiku tier on card-alone
setups.

## 2. Description hill-climbing (official skill-creator harness, haiku, 3 iterations each)

`scripts/optimize-description.sh` wraps `run_loop.py`: evaluate current
description on the trigger-eval corpus (60/40 train/holdout, 2 runs/query),
propose improvements from failures, re-evaluate, keep the best **by test
score**. Run on the two flagship entry points:

| skill | challengers | verdict |
|---|---|---|
| question-framing | 3 iterations of rewrites | **original won** (test 8/15; no challenger beat it) |
| structural-estimation | 3 iterations of rewrites | **original won** (test 4/8; no challenger beat it) |

Both hand-tuned descriptions (including the same-day viz broadening of
question-framing) survived held-out challenge — they are at a measured local
optimum, not an asserted one. Absolute trigger rates are low because the
subject is haiku in a competitor-laden live config (it under-invokes skills
generally); the *relative* comparison is the signal. Re-run after any
description edit: `scripts/optimize-description.sh <skill> [model] [iters]`.
Note the harness writes temp candidate skills into `~/.claude/commands/`
during a run (visible to live sessions; cleaned up automatically).

## 3. Subagent value regression (superpowers v5.0.6 method, scoped)

Question: does the `analysis-reviewer` prompt catch what a generic "review
this analysis" misses? Method: the two artifacts that *missed* their plant in
the v0 core benchmark (leakage-overlap/baseline, na-silent-drop/card), reviewed
by haiku 3× per arm — generic prompt vs the agent file as system prompt —
scored on whether the review surfaces the planted issue.

Result: **12/12 — every review in both arms surfaced the planted issue**
(3 reps × 2 artifacts × 2 arms). The comparison came back confounded in an
instructive way: the "generic" arm's transcripts open with "Using the
analysis-review checklist…" — the nested headless runs execute in the live
config, where "review this data analysis" **triggered the installed
`analysis-review` skill natively, 6/6 times**. Three clean findings anyway:

1. **A fresh review pass catches what the author missed.** The same haiku
   tier that produced these missed-plant artifacts catches them 12/12 on
   re-review — the strongest evidence yet for the independent-review step in
   the workflow spine.
2. **The specialist persona adds no measurable catch-rate** over the
   skill-equipped default — consistent with superpowers v5.0.6's finding
   about reviewer subagents.
3. **Incidentally: description-based triggering worked 6/6** in headless
   haiku runs on a natural "review this" phrasing — a real-world trigger
   datum.

Decision: **keep the `analysis-reviewer` agent** — the clean comparison
(against a truly skill-less baseline) wasn't achieved, and the agent remains
the clean-context dispatch vehicle for independent review; record the null
persona delta, and re-run under config isolation before any dissolve decision.

Decision rule (pre-stated): if the specialist prompt does not beat generic
review, follow superpowers v5.1.0 and dissolve the named agent into a prompt
template inside the owning skill; if it wins, keep both the named agent and
the measurement as its justification.

## Reproduce

```bash
python3 scripts/run-behavioral-eval.py --manifest manifest-pressure.json --model claude-haiku-4-5
scripts/optimize-description.sh question-framing claude-haiku-4-5 3
```
