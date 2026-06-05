# Causal Powers — Economic Judgment + Consolidation/Voice

**Date:** 2026-06-05
**Status:** Approved for implementation
**Scope:** reduced-form microeconomics. Explicitly NOT building out
inference/clustering depth, randomization inference, simulation, or power
(deprioritized by the user as macro/methods machinery).

## Problem

The family encodes process discipline (a careful RA) but almost no economic
judgment (a senior professor). It never asks: is the magnitude plausible, is the
effect economically (not just statistically) significant, what's the mechanism,
how does it compare to known estimates, and — for reduced-form designs — "what's
your experiment?" It is also getting long and formulaic (Red Flags +
Rationalizations tables in all 10 skills) and its voice is "careful," not senior.

## Decisions

1. **Weave economic judgment into existing skills** (no new skill):
   `question-framing` (ex ante), `result-verification` (ex post, the bulk),
   `causal-identification` (design-first + red-lines).
2. **Encode the practice, not numeric thresholds.** Canonical red-lines appear as
   illustrations, never as laws — so it generalizes across micro subfields and
   doesn't go stale.
3. **Consolidation + voice pass** across all 10 skills, surgically.

## Changes

### `question-framing` — ex ante economic prior
Add a compact beat: before computing, predict like an economist — the **sign**
theory implies, the **rough magnitude** in interpretable units, and the
**mechanism** (channel X→Y). Name what result would *surprise* you. Surgical; do
not restructure (the skill already works well).

### `result-verification` — ex post professor's read (largest addition)
Expand the thin "sanity-check vs benchmark" into an economist's reading:
- Convert to **interpretable units** (elasticity, semi-elasticity, % of mean, SD).
- **Economic vs statistical significance** — big enough to matter? A
  significant-but-tiny effect and a precise zero are both economically "no effect."
- **Magnitude plausibility / back-of-envelope** — implied behavioral response,
  dollar amount, share of a known total.
- **Mechanism consistency** — sign/size match the posited channel; auxiliary
  predictions borne out.
- **Benchmark vs known estimates** — if 10× off the literature, explain why.

### `causal-identification` — design-first judgment + bad controls
- **"What's your experiment?"** (Angrist–Pischke): name the source of variation
  as if randomized, before modeling.
- Add the **bad-controls** red-line: conditioning on post-treatment variables,
  mediators, or colliders (currently missing; central to reduced-form micro).
- Frame existing pitfalls (staggered TWFE, weak IV) as illustrative red-lines.

### Consolidation + voice pass (all 10, surgical)
- Trim Red Flags + Rationalizations tables to the sharpest 3–4 each (main length
  saver).
- Cut cross-reference repetition and redundant restatement.
- Rewrite in a senior-economist register: research-design-first,
  magnitude-obsessed, mechanism-first, anti-robustness-theater, terse, skeptical
  of "significant ∴ true."
- Light touch on `question-framing` and `pre-analysis-plan` (trim only).

## Housekeeping
- Bump to **0.5.0**; update README; reinstall. Skill count unchanged
  (gateway + 10).

## Out of scope
- Inference/clustering buildout, randomization inference, Monte-Carlo simulation,
  power/MDE, literature-retrieval automation, auto-generated exhibits. (Some may
  return later; not now.)
