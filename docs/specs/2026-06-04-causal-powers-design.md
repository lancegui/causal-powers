# Causal Powers — Design Spec

**Date:** 2026-06-04
**Status:** Approved for implementation

## Purpose

A self-contained Claude Code plugin: a "superpowers for data analytics, causal
inference, and econometrics" skill family. It adapts the *discipline* of the
superpowers software skills to the failure modes that are specific to data work
— where the dangerous bug is **silent** (the code runs clean and hands you a
confident, wrong answer) rather than loud (a stack trace).

This supersedes the earlier single skill `~/.claude/skills/validation-driven-analysis/`,
which will be **deleted** once `data-contracts` lands.

Three-language scope throughout: **R, Julia, Python**.

## Why a separate family (the core thesis)

In software the dangerous bug throws. In analysis it stays quiet:

- A join fans out 1-to-many and revenue triples.
- One `NA` / `missing` / `NaN` poisons a mean, or is silently dropped and biases it.
- Units off by 100× (dollars vs cents, proportion vs percent).
- A timezone / date-floor shifts events into the wrong day.
- A surprise factor level quietly creates a new group.
- Train/test overlap makes a model metric a fantasy.
- An identification assumption fails and the "effect" is confounding.

None raise an error. So the discipline moves from TDD's *"assert the answer
first"* (impossible — the answer is the unknown) to **"assert everything around
the answer that must hold regardless of the answer,"** and — for causal work —
**"state and defend the identification assumptions before estimating."**

## Naming

- **Umbrella:** Causal Powers (parallel to "superpowers").
- **Style:** functional, minimal-cuteness skill names.

## Architecture

Self-contained plugin, mirroring how `superpowers` is built.

```
~/Developer/causal-powers/            # git repo
├── .claude-plugin/
│   └── plugin.json                   # name, version, description, author
├── README.md
├── docs/specs/2026-06-04-causal-powers-design.md
└── skills/
    ├── using-causal-powers/SKILL.md      # gateway: map + creed + routing
    ├── question-framing/SKILL.md         # ← brainstorming analog
    ├── pre-analysis-plan/SKILL.md        # ← spec-driven / writing-plans analog
    ├── data-contracts/SKILL.md           # ← TDD analog (+ up-front provenance)
    ├── wrong-number-debugging/SKILL.md   # ← systematic-debugging analog (+ provenance back-trace)
    ├── result-verification/SKILL.md      # ← verification-before-completion analog
    ├── causal-identification/SKILL.md    # ← econometrics core (no software analog)
    └── analysis-review/SKILL.md          # ← requesting/receiving-code-review analog
```

Installed locally as a plugin (local marketplace add + install). Each skill
carries an **aggressive auto-trigger `description`** so it fires even on vague
asks ("analyze this", "what's the trend", "clean this up").

### Mapping to superpowers

| Superpowers / agent-skills | Causal Powers analog | In scope |
|---|---|---|
| `using-superpowers` | `using-causal-powers` | ✅ |
| `brainstorming` | `question-framing` | ✅ |
| `spec-driven-development` + `writing-plans` | `pre-analysis-plan` | ✅ |
| `test-driven-development` | `data-contracts` | ✅ |
| `systematic-debugging` | `wrong-number-debugging` | ✅ |
| `verification-before-completion` | `result-verification` | ✅ |
| (no software analog) | `causal-identification` | ✅ |
| `requesting/receiving-code-review` | `analysis-review` | ✅ |
| worktrees, parallel-agents, writing-skills, finishing-branch, subagent-dev, executing-plans | domain-agnostic | reuse superpowers as-is |

## Per-skill scope

### `using-causal-powers` (gateway)
One-screen map. The shared creed ("a number you never validated is a guess
wearing a lab coat"). Lists the 7 skills and a decision tree for which to
invoke. Process skills (framing, pre-analysis-plan, debugging) route before
implementation. Mirrors `using-superpowers`.

### `question-framing` (← brainstorming)
Before touching data: pin the **estimand / metric definition**, population,
unit of observation, the **decision the number informs**, and what would change
that decision. For causal work, force the estimand (ATE/ATT/LATE), treatment,
and counterfactual to be named. Output: a short analysis brief. Kills ambiguous
metrics ("active users", undefined denominators).

### `pre-analysis-plan` (← spec-driven / writing-plans)
Pre-registration discipline: lock hypotheses, estimand, primary/secondary
specs, sample/exclusions, and the **robustness suite** *before* seeing outcomes.
Prevents specification search and p-hacking. Distinguish confirmatory
(pre-registered) from exploratory (clearly labeled) analysis. Output: a written
PAP the later work is checked against.

### `data-contracts` (← TDD, + up-front provenance)
Core loop: `CONTRACT → CHECK IT BITES → COMPUTE → RECONCILE → FREEZE`.
Two regimes: **exploration** (validate inputs, check every intermediate; no
test-first theater) vs **reusable rule** (real test-first with a tiny known-answer
fixture). Invariant catalog: cardinality/joins, keys & nulls, ranges/domains,
totals reconcile, categories, types/units, missingness, temporal, determinism,
leakage.

- **Join-cardinality discipline (first-class section):** declare 1:1 / 1:m /
  m:1 / m:m *before* every merge; assert row counts before & after; use
  `validate=` (pandas merge), relationship/`multiple=` checks (dplyr joins),
  explicit key-uniqueness asserts (Julia).
- **Up-front provenance:** document each column's source + expected derivation
  as part of the contract (data dictionary / lineage notes); note what was
  dropped/recoded upstream.
- **See it bite:** prove each check fails on deliberately broken data.
- **Freeze:** snapshot validated results as golden/reference outputs; diff on
  re-run so silent drift becomes a loud failure.
- R/Julia/Python cheat-sheet (assertions, schema/contract libs, reconcile with
  float-aware comparison).

### `wrong-number-debugging` (← systematic-debugging, + provenance back-trace)
When a clean-running number is surprising/wrong: **systematic bisection** of the
pipeline, not guess-and-patch. **Provenance back-tracing:** binary-search the
transform chain to the step where the number went bad; build a minimal repro on
a subset; compare against a known-good intermediate; reconcile stage by stage.
Silent-culprit checklist (fan-out joins, NA poisoning, units, timezone, surprise
factor levels, leakage). Root cause before fix.

### `result-verification` (← verification-before-completion)
Before reporting or claiming "done": reconcile totals to source, **reproduce
from a clean kernel/session with a fixed seed**, run the robustness suite (alt
specs, subsamples, outlier sensitivity), sanity-check against an external
benchmark, confirm figures/tables match the numbers in the text. Evidence
before assertion: paste the reconciliation output, never "looks right."

### `causal-identification` (econometrics core)
State the identification strategy and assumptions *before* estimating.
Per-design assumption + diagnostic checklists:
- **DiD / event study:** parallel pre-trends (plot + test), no anticipation,
  staggered-adoption bias → modern estimators (Callaway–Sant'Anna, Sun–Abraham,
  `did2s`), treatment timing.
- **IV:** first-stage strength (F), exclusion (argue; untestable), monotonicity,
  weak-IV-robust inference.
- **RDD:** continuity at cutoff, no manipulation (McCrary density), bandwidth
  sensitivity, covariate smoothness, donut.
- **Matching / regression adjustment:** overlap / common support, balance (SMD)
  tables, unconfoundedness caveat.
- **Panel FE:** within-variation, SE clustering.

Robustness + placebo tests + sensitivity-to-confounders (Oster δ, e-values) are
**default, not optional**. Reconcile the causal estimate against descriptive
facts. Stack tooling: R (`fixest`, `did`, `rdrobust`, `ivreg`), Python
(`linearmodels`, `doubleml`, `differences`, `statsmodels`), Julia
(`FixedEffectModels.jl`, `RegressionTables.jl`).

### `analysis-review` (← requesting/receiving-code-review)
Peer-review an analysis (your own or another's) for the silent-failure classes:
unchecked joins, leakage, fragile/searched specs, unreconciled totals,
identification gaps, undefined metrics. Both sides: how to *request* a review
(what to hand over) and how to *receive* one (verify, don't perform agreement).

## Cross-cutting conventions (every skill)

- Aggressive auto-trigger `description` so skills fire on vague asks.
- Three-language parity: R / Julia / Python idioms, not a bolted-on framework.
- "See it bite" / evidence-before-assertion ethos throughout.
- Each skill ends with a **Red Flags** table and a **Common Rationalizations**
  table (reusing the strong format from the old `validation-driven-analysis`).
- Skills cross-reference siblings by name.

## Build approach

1. `data-contracts` first (richest; mine old `validation-driven-analysis`).
2. The other process/implementation skills.
3. `causal-identification` (densest domain content).
4. `using-causal-powers` gateway last (it indexes the others).
5. `plugin.json` + `README.md`.
6. Local install + smoke test that descriptions trigger on representative asks.
7. Delete `~/.claude/skills/validation-driven-analysis/`.

Implementation goes through the **`skill-creator`** skill (not `writing-plans`),
since the deliverables are skills.

## Out of scope (for now)

- Re-creating domain-agnostic superpowers (worktrees, parallel agents, etc.).
- A dedicated standalone `data-provenance` skill (folded into `data-contracts`
  up-front and `wrong-number-debugging` back-trace instead).
- Publishing to a public marketplace (local install only for now).
