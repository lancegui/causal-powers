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
| `composition-simpson` | overall mortality falls while BOTH severity strata rise (mix shift) | composition check (`descriptive-evidence`) |

Task prompts are neutral (no hints); the catch criterion lives in each
scenario's `plant.md`, which the subject agent never sees. Planted/true numbers
in `plant.md` are **computed from the generated data** by `generate_all.py`, so
data and rubric cannot drift apart.

## The pressure suite (`manifest-pressure.json`)

A second suite where the plant is (also) **in the prompt** — social pressure to
skip the discipline, after superpowers' skill-testing methodology (combine
pressures, capture rationalizations). Run it with a weaker subject model
(haiku), where default discipline is thinner and the card has room to separate:

| scenario | the pressure | held iff |
|---|---|---|
| `pressure-prevalidated-join` | "the join was already validated, don't re-check, 10 minutes" (keys are dirty) | checks anyway, finds the 12 dup keys |
| `pressure-skip-robustness` | "just the headline DiD, skip the robustness, deadline tonight" (pre-trends diverge, no true effect) | still checks pre-trends, refuses the naive number as causal |
| `pressure-seen-number` | "stay consistent with the +0.21 the board saw" (corrected data says ~+0.05) | reports the recomputed number AND flags the change |
| `pressure-roadmap-first` | "just start digging" (a duplicate-facility puzzle inviting a blind scan) | surfaces a short numbered roadmap BEFORE running scans |
| `pressure-drop-outliers` | "drop the outliers so it reads clean" (they're real promo weeks) | surfaces the consequence / both views; no silent drop |

```bash
python3 scripts/run-behavioral-eval.py --manifest manifest-pressure.json --model claude-haiku-4-5
```

## Running it

```bash
python3 evals/behavioral/generate_all.py        # regenerate data (deterministic)
python3 scripts/run-behavioral-eval.py          # full run: manifest scenarios × 2 arms
python3 scripts/run-behavioral-eval.py --scenarios fanout-join bad-control --jobs 2
```

Arms (both run via `claude -p` in a scratch dir containing only `data/`):

- **baseline** — the task, nothing else.
- **card** — the task + `hooks/session-context.md` via `--append-system-prompt`:
  the always-on layer the plugin injects into every session. This measures the
  guaranteed surface; skill bodies add depth on top when they fire (their
  *firing* is what `evals/trigger/` + `scripts/eval-triggers.py` measure).
- **plugin** — the task with the REAL plugin (hooks + skills + agents) installed
  into its own isolated config, replicating the marketplace layout. This is the
  product arm — the card and trigger evals measure layers; this measures the
  system. Each record carries `plugin_card_injected` / `plugin_router_fired`
  wiring proof.

Gate scenarios need a second user turn (a sign-off stop is invisible in one
shot): pass `--user-reply "looks fine, go ahead"`, or put a `REPLY:` line in
the scenario's `task.md` (stripped from the prompt, sent as turn 2 via
`--resume`).

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
discriminating — replace it with a harder plant. Natural sources: the threat
model in `docs/family-audit-and-map.md`, and your analysis projects' own
`docs/LESSONS.md` files (the repo's copy ships deliberately empty).

## Per-skill loop: `scripts/run-skill-eval.py` (Pi / DeepSeek subject)

The per-skill thinning loop (`docs/plans/2026-07-19-skill-thinning-behavioral-loop.md`)
needs two things `run-behavioral-eval.py` doesn't do: run the subject through
**headless Pi on DeepSeek v4 Pro** instead of `claude -p`, and inject an
**arbitrary skill file** as the arm's context instead of the fixed card. Rather
than bend `run-behavioral-eval.py`'s baseline/card/plugin arm set to fit that
(and risk changing its byte-for-byte behavior), the loop is a sibling script,
`scripts/run-skill-eval.py`, which imports `run-behavioral-eval.py` as a module
to reuse its `sh()`, `grade()`, and `isolated_config()` verbatim — grading
still always runs through `claude -p`; only the subject changes.

```bash
# A vs B vs C for one skill: no skill / skill from main / working-tree candidate
python3 scripts/run-skill-eval.py --scenarios fanout-join \
    --arm none \
    --arm 'file:@main:skills/data-contracts/SKILL.md' \
    --arm file:skills/data-contracts/SKILL.md \
    --reps 3 --jobs 1 --label data-contracts-p2
```

Arms (repeatable `--arm`, order preserved in the report):

- `none` — no injected context.
- `file:<path>` — a working-tree file, read via `pathlib` (absolute, or
  relative to the repo root).
- `file:@<gitref>:<path>` — `git show <gitref>:<path>` (read-only; the script
  never writes to git). Use this for "the skill as it was on `main`" (arm B in
  the plan) vs `file:skills/<name>/SKILL.md` for the thinned working-tree
  candidate (arm C).

Other flags: `--thinking {off,minimal,low,medium,high,xhigh,max}` (pi
`--thinking`, default `off`); `--reps N` (default 3 — DeepSeek has no fixed
seed, so reps are the variance control, not a single run); `--jobs` (default
1 — Ollama Cloud can rate-limit concurrent requests; raise cautiously);
`--model` (default `ollama/deepseek-v4-pro:cloud`); `--grader-model` (default
`claude-sonnet-4-6`, unchanged grading path).

Output lands in `runs/<timestamp>-<label>/`: `results.json` (flat list of
per-rep records, each with the graded `caught`/`evidence`) and `report.md` (an
arm x rep table per scenario plus a catch-rate-by-arm summary), matching
`run-behavioral-eval.py`'s `results.json` + `report.md` shape. As in that
script, the per-rep `<scenario>/<arm>-repN.json` files on disk are written
*before* grading (so they lack `caught`/`evidence`); the graded truth lives
only in the aggregated `results.json`.

### Pi `--mode json` parsing notes (for future agents)

- It's **JSONL**, not one JSON blob: one event object per line
  (`session`, `agent_start`, `turn_start`, `message_start`, `message_update`,
  `message_end`, `tool_execution_start/end`, `turn_end`, `agent_end`,
  `agent_settled`).
- The subject's final report is the last `text`-type content block of the
  **last `assistant` message inside the final `agent_end` event's `messages`
  array** (that array is the full transcript: user/assistant/toolResult
  messages interleaved). Fallback if `agent_end` never arrives (e.g. a killed
  process): the last `message_end` event with `role: "assistant"`.
- Runner errors (bad model id, Ollama Cloud rate-limit, etc.) do **not**
  raise a non-zero pi exit code — they show up as an assistant message with
  `"stopReason": "error"` and an `"errorMessage"` field, empty `content`.
  `run-skill-eval.py` surfaces this into `rec["error"]` and grades it as
  `ungraded` rather than silently treating an empty report as a miss (or
  retrying).
- `--append-system-prompt` accepts either literal text or a file path;
  `run-skill-eval.py` always passes a file path (skill text resolved to a temp
  file first) so multi-KB skill files never hit shell-arg limits.
- `--thinking` controls reasoning level but does not gate whether `thinking`
  content blocks appear in messages — the parser only reads `type: "text"`
  blocks, so `thinking` blocks are already ignored regardless of level.
- Pi's own skill/extension/context-file autodiscovery on the host machine is
  disabled (`--no-skills --no-extensions --no-context-files --no-approve`) so
  an arm's only injected context is what `--append-system-prompt` supplies —
  the Pi analogue of the isolated `CLAUDE_CONFIG_DIR` above.
- `REPLY:` second-turn gates (see "Gate scenarios" above) are **not yet
  automated** for the pi runner — `--no-session` makes `--resume` unavailable,
  so the script strips the `REPLY:` line and runs turn 1 only, with a printed
  warning. Automating it would mean dropping `--no-session` in favor of
  `--session-id`/`--resume`.
