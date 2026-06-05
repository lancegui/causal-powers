---
name: executing-analysis-plans
description: Use once an analysis brief or pre-analysis plan is APPROVED and it's time to actually run the analysis — build the dataset, estimate the primary specification, run the robustness suite, placebo tests, and alternative designs, then assemble the results. Drives execution through the plan step by step, validating each step (data-contracts) and stopping for the user at consequential decisions (analysis-checkpoints), and fans the INDEPENDENT pieces (robustness specs, competing designs, subsample cuts, placebo tests, multiple outcomes) out to parallel subagents instead of running them one slow serial loop. Use whenever the user says "ok run it", "execute the plan", "now do the analysis", "run all the specs", "do the robustness checks", or you've just gotten sign-off on a plan and need to carry it out.
---

# Executing Analysis Plans

## Overview

A plan that's been approved is a commitment, and execution is where it either gets honored or quietly abandoned. This skill takes over once `question-framing` (and, for confirmatory work, `pre-analysis-plan`) have produced an **approved** plan, and carries it out: build, estimate, stress-test, assemble. It is the analytics counterpart of executing an implementation plan — including dispatching independent work to parallel subagents.

**Core principle:** Execute the approved plan faithfully, validating as you go and parallelizing what's independent. Autonomy here is for *carrying out the agreed plan fast and thoroughly* — not for changing it. Any departure is a checkpoint, not a step.

## Prerequisite: there is an approved plan

Don't start here from a cold "analyze this." If there's no approved brief/PAP yet, go back to `question-framing` (and `pre-analysis-plan` for confirmatory work) and get sign-off first. Executing a plan nobody approved is just the behind-the-back problem wearing a schedule.

## The sequential spine vs. the parallel fan-out

The single biggest execution mistake is running everything in one slow serial loop — or, worse, parallelizing things that actually depend on each other. Split the plan into its dependent spine and its independent leaves.

**Sequential spine (must run in order — each depends on the last):**
1. Build / clean / join the analysis dataset → **validate with `data-contracts`** (row counts, join cardinality, reconciliation). Nothing downstream is trustworthy until this passes.
2. Construct the treatment, outcome, and key covariates → validate ranges, missingness, leakage.
3. Estimate the **primary specification** (the one pre-committed in the PAP) → this is *the* number.

**Parallel fan-out (independent — dispatch to subagents, run concurrently):**
Once the validated dataset and primary spec exist, these typically don't depend on each other and should run in parallel, one subagent per task:
- each **robustness specification** (alternative controls, functional form, clustering level, window);
- each **placebo / falsification test**;
- each **alternative design** (e.g. run Design A and Design B side by side);
- each **subsample / heterogeneity cut**;
- each **secondary outcome**;
- **sensitivity analyses** (Oster δ, e-values, bandwidth sweeps).

They all read the *same* validated dataset and the *same* pre-specified recipe, so they're embarrassingly parallel. Use superpowers' **`dispatching-parallel-agents`** / **`subagent-driven-development`** for the mechanics; this skill tells you *what* in an analysis is safe to fan out and *what each subagent must carry*.

## What every dispatched subagent must carry

A parallel subagent is a place for silent errors and silent redesigns to hide, so constrain it:

- **The exact, pre-specified task** — the precise spec/test from the approved plan, not "explore X." It executes a recipe; it does not choose the recipe.
- **The data contracts to assert** — the same `data-contracts` invariants, so a fanned-out spec can't quietly run on a corrupted subset.
- **A structured result to return** — coefficient, SE, N, the diagnostics, and a pass/fail on its contracts — so you can assemble them without re-reading ten transcripts.
- **The checkpoint rule** — if the subagent hits a decision that would change the design, sample, spec, or estimand (e.g. its diagnostic fails and the "fix" is a redesign), it **reports back and stops**; it does not resolve it. That decision returns to you and then to the user via `analysis-checkpoints`.

## Between every step: validate, then checkpoint

Execution is not "run to the end and show the user." After each spine step and as fan-out results land:

- **Validate** the result against its contract (`data-contracts`); reconcile totals; if a number looks wrong, switch to `wrong-number-debugging`.
- **Checkpoint** any consequential decision that surfaced (`analysis-checkpoints`) — execution is exactly when "the data surprised us, let's change the design" arises, and that is the user's call, not a step you take to keep moving.

## Synthesis

When the fan-out completes, assemble — don't just dump:
- Build the **robustness table**: primary estimate beside every alternative, so stability (or fragility) is visible at a glance.
- **Reconcile across specs**: if the headline swings under a reasonable alternative, that's a finding to surface, not a result to bury.
- Note which subagents' contracts **failed** — a robustness spec that violated an invariant is not a clean "it's robust."
- Hand off to **`result-verification`** before any of this is reported.

## Red flags — STOP

- Starting execution with no approved plan to execute.
- Running the whole robustness suite in a serial loop when each spec is independent (slow, and you'll cut it short).
- Parallelizing steps that actually depend on each other (e.g. estimating before the dataset is validated).
- A subagent that resolved a design/sample/spec decision on its own instead of reporting it back.
- Improvising new specifications mid-execution that weren't in the plan, without surfacing them.
- Presenting fanned-out results without reconciling them or checking each one's contracts.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "I'll just run everything in one script, it's simpler." | One serial script over a dozen independent specs is slow enough that you'll truncate the suite. Fan them out and run the whole thing. |
| "The subagents can figure out the spec." | An under-specified subagent invents its own analysis — the parallel version of deciding behind the user's back. Hand each one the exact recipe. |
| "A robustness check failed its data contract, but the coefficient looks fine." | A spec that ran on corrupted data isn't evidence of robustness; it's noise. The contract failing is the result. |
| "The data suggested a better spec, so I added it." | Adding it silently is specification search. Surface it as a checkpoint; run it labeled as exploratory if approved. |
| "I'll show all the results at the end." | Then a wrong intermediate poisons everything after it unseen. Validate each step as it lands. |

## Relationship to sibling skills

- Runs **after** an approved **`question-framing`** brief and **`pre-analysis-plan`**; if there's no approval, go get it first.
- Every spine step and every fanned-out spec validates with **`data-contracts`**.
- Consequential decisions that surface during execution stop at **`analysis-checkpoints`**; wrong numbers go to **`wrong-number-debugging`**; design changes to **`causal-identification`**.
- Keep the per-step code minimal and surgical with **`analysis-craft`**.
- Synthesized results go to **`result-verification`** before reporting, and to **`analysis-review`** before they ship.

## The bottom line

```
Executing well  →  approved plan worked top to bottom, spine validated in order, independent specs fanned out to subagents, every result reconciled, deviations stopped for the user
Otherwise        →  a serial half-run of an unapproved plan, with the robustness suite quietly truncated
```
