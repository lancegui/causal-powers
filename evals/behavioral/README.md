# Behavioral benchmark — planted silent failures

The trigger evals (`evals/trigger/`) test whether the right skill *fires*. This
benchmark tests the thing the plugin actually promises: **does the discipline
catch silent failures that produce confident, wrong answers?** Each scenario is
a small, realistic task whose data contains one deliberately planted failure
from the family's threat model:

| scenario | planted failure | discipline under test |
|---|---|---|
| `fanout-join` | duplicate join keys inflate revenue +26% | join cardinality (`data-contracts`) |
| `silent-filter-total` | upstream rollup silently excludes refunds | totals reconciliation |
| `unit-mismatch` | EUR prices in cents → 100× error | units/magnitude red-line |
| `na-silent-drop` | top-coded missing wages bias a group mean | missingness audit |
| `leakage-overlap` | 90 test rows duplicated from train | leakage check |
| `bad-control` | post-treatment mediator offered as a "control" | bad-controls red-line (`causal-identification`) |
| `pretrend-violation` | diverging pre-trends, zero true effect | parallel-trends test |
| `spatial-silent-drop` | 9 facilities outside every polygon vanish | spatial join reconciliation |
| `nonidentified-param` | constant price → elasticity not identified | identification (`structural-estimation`) |

Task prompts are neutral (no hints); the catch criterion lives in each
scenario's `plant.md`, which the subject agent never sees. Planted/true numbers
in `plant.md` are **computed from the generated data** by `generate_all.py`, so
data and rubric cannot drift apart.

## Running it

```bash
python3 evals/behavioral/generate_all.py        # regenerate data (deterministic)
python3 scripts/run-behavioral-eval.py          # full run: 9 scenarios × 2 arms
python3 scripts/run-behavioral-eval.py --scenarios fanout-join bad-control --jobs 2
```

Arms (both run via `claude -p` in a scratch dir containing only `data/`):

- **baseline** — the task, nothing else.
- **card** — the task + `hooks/session-context.md` via `--append-system-prompt`:
  the always-on layer the plugin injects into every session. This measures the
  guaranteed surface; skill bodies add depth on top when they fire (their
  *firing* is what `evals/trigger/` + `scripts/eval-triggers.py` measure).

Both arms run under an **isolated `CLAUDE_CONFIG_DIR`** (credentials are copied
from `~/.claude/.credentials.json`, or extracted from the macOS keychain, into a
mode-600 file in the throwaway config dir) so locally installed plugins cannot
contaminate the baseline. The runner prints `isolated=False` loudly if it had to
fall back to the user config — treat such runs as invalid for comparison.

An LLM grader applies each `plant.md` criterion to the arm's final answer +
`result.md` and returns `caught` true/false with quoted evidence. Results land
in `runs/<timestamp>/{results.json,report.md}` with the subject model, grader
model, isolation status, and plugin git SHA recorded for provenance.

## Reading results

The headline is `caught: card X/9 vs baseline Y/9`. Three caveats to keep
honest: single-run arms are noisy (a scenario can flip run-to-run — prefer 3
reps before claiming a small delta); some plants are catchable by a strong
model's default caution (a baseline catch is *good news about the model*, not
bad news about the card); and the grader is itself a model — spot-check
`evidence` against the transcripts in `runs/` before publishing a number.

When a scenario is caught by baseline consistently, it has stopped
discriminating — replace it with a harder plant (the failure modes in
`docs/LESSONS.md` are the natural source).
