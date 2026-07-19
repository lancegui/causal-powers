---
name: executing-analysis-plans
description: Use once an analysis brief or pre-analysis plan is APPROVED and it's time to actually run the analysis — build the dataset, estimate the primary specification, run the robustness suite, placebo tests, and alternative designs, then assemble the results. Drives execution through the plan step by step, validating each step (data-contracts) and stopping for the user at consequential decisions (analysis-checkpoints), and, for the INDEPENDENT pieces (robustness specs, competing designs, subsample cuts, placebo tests, multiple outcomes), offers inline vs parallel-subagent dispatch up front — the execution mode is the user's call. Use whenever the user says "ok run it", "execute the plan", "now do the analysis", "run all the specs", "do the robustness checks", or you've just gotten sign-off on a plan and need to carry it out.
---

# Executing Analysis Plans

## Overview

A plan that's been approved is a commitment, and execution is where it either gets honored or quietly abandoned. This skill takes over once `question-framing` (and, for confirmatory work, `pre-analysis-plan`) have produced an **approved** plan, and carries it out: build, estimate, stress-test, assemble — including dispatching independent work to parallel subagents.

**Core principle:** Execute the approved plan faithfully, validating as you go and parallelizing what's independent. Autonomy here is for *carrying out the agreed plan fast and thoroughly*, not for changing it — any departure is a checkpoint, not a step.

## Prerequisite: there is an approved plan

Don't start here from a cold "analyze this." If there's no approved brief/PAP yet, go back to `question-framing` (and `pre-analysis-plan` for confirmatory work) first — executing a plan nobody approved is just the behind-the-back problem wearing a schedule.

**A new request on an already-locked plan still triggers this skill — re-fire, don't coast.** A re-run, a finer reporting cut, "now do the other radii / the facility-year version" is exactly this skill's job, and it still ends in `result-verification` before any result is written to a file. "The design was locked last week, I'll just run it" is how a new cut ships unverified — the lock covers the *design*, not this *run*. If the new cut changes the unit or estimand, it's a `question-framing`/`analysis-checkpoints` change first, not a re-run.

## The sequential spine vs. the parallel fan-out

The single biggest execution mistake is running everything in one slow serial loop — or, worse, parallelizing things that actually depend on each other. Split the plan into its dependent spine and its independent leaves.

**Sequential spine (must run in order — each depends on the last):**
1. Build / clean / join the analysis dataset. Unless it's a trivial load of one already-clean file, this is a phase, not a line: **delegate it to `data-preparation`**, which validates each cleaning step (`data-contracts`) and routes consequential decisions to `analysis-checkpoints`. Nothing downstream is trustworthy until that phase's reconciliation passes.
2. Construct the treatment, outcome, and key covariates → validate ranges, missingness, leakage.
3. Estimate the **primary specification** (the one pre-committed in the PAP) → this is *the* number.

**Parallel fan-out (independent — but chosen, not exhaustive):**
Once the validated dataset and primary spec exist, the supporting analyses are independent and *can* run concurrently — but "can run in parallel" is not "should all run." Pick the shortlist that earns its place (next section) and fan out **only those**, one subagent per task. Candidates to choose *from*:
- a **robustness specification** that probes the main threat (not every control permutation);
- the **placebo / falsification test** that would catch the confound you actually worry about;
- a genuinely **alternative design**, when one exists;
- a **pre-specified** subsample / heterogeneity cut (not a fishing sweep);
- the **secondary outcome** the mechanism predicts;
- the one **sensitivity analysis** that matters (Oster δ, e-value, bandwidth);
- for **structural** work: the **Monte-Carlo recovery reps**, the **multiple starting values** on the non-convex objective, and the **counterfactual scenarios** (one per mechanism) — same fan-out logic (`structural-estimation`).

**But choosing the execution *mode* is itself a checkpoint — present it, don't assume it — unless a topology has already decided it.**

**An approved phase IS the execution-mode consent when it carries a topology.** If an approved `docs/analysis/phases/<id>.yaml` already has a non-empty `topology.nodes` (schema owned by `analysis-state-management`, the normal case under causal-conductor on OpenCode), the user already made the inline-vs-fan-out call: **one leaf node per independent piece of work is the fan-out plan**, pre-approved. Map the shortlist onto those nodes and dispatch — don't re-ask, that's friction dressed up as diligence. **The ask-first rule below applies only when no topology exists yet.**

When no topology has already decided it, ask the user how they want the shortlist run:

- **Inline** — each chosen spec in turn, here in this session, every step fully observable as it goes.
- **Subagent dispatch** — one parallel subagent per spec, run concurrently.

Recommend **subagent dispatch** for genuinely independent specs (faster, and it isolates each spec's context from yours), but it is the user's call — inline keeps everything in view, which some prefer for a small or delicate run. Make this a real, up-front question, not a silent default.

Once the mode is settled: for **subagent dispatch**, hand each chosen task to the **`robustness-runner`** agent Causal Powers ships — it executes one pre-specified spec, asserts the data contracts, and returns a structured result, stopping if it hits a design decision (superpowers' **`dispatching-parallel-agents`** / **`subagent-driven-development`** cover the mechanics). A `robustness-runner` dispatch **is** one `topology.nodes` leaf-node dispatch, just named differently by layer — one node per call, never a multi-node prompt, the collapse the topology exists to prevent. For **inline**, run the chosen specs one at a time, applying the same data-contract assertions to each.

## Robustness is an argument, not an inventory

The parallel machinery makes running checks cheap, and cheap is exactly the trap: it turns the robustness suite into a free buffet. Don't. **More robustness checks do not mean more credibility** — a wall of specifications usually buries the one check that matters, and a senior reader treats a 30-column robustness table as a *tell* of weak identification, not a show of strength. Before running anything beyond the primary spec:

1. **Name the main threat** — the single most credible way this estimate could be confounding rather than effect.
2. **Choose the ~3 checks that would actually break the result if it's fragile** — the ones that probe *that* threat. A good robustness check has a real chance of failing; a cosmetic "add one more control" that cannot fail proves nothing.
3. **Propose the shortlist to the user** — each with a one-line rationale ("drop the cities with the 2016 recording jump — tests whether the recording change, not the policy, drives it") — and get approval *before* running.
4. Run only the approved set. Run more **only if the user asks**. (If the robustness suite was already locked in `pre-analysis-plan`, run *that* set as-is — the checkpoint is for **additions or deviations**, not a redundant re-ask of the pre-approved plan.)

Default to roughly three. This is judgment, not a quota — occasionally a design genuinely needs a fourth, and you should say so — but the instinct is parsimony, because the job is to *convince*, not to *exhaust*. Choosing which checks to run is itself a consequential decision, so it goes through the user (`analysis-checkpoints`), never a silent fan-out of everything imaginable.

## What every dispatched subagent must carry

A parallel subagent is a place for silent errors and silent redesigns to hide, so constrain it:

- **The exact, pre-specified task** — the precise spec/test from the approved plan, not "explore X." It executes a recipe; it does not choose the recipe.
- **The data contracts to assert** — the same `data-contracts` invariants, so a fanned-out spec can't quietly run on a corrupted subset.
- **A structured result to return** — coefficient, SE, N, the diagnostics, and a pass/fail on its contracts — so you can assemble them without re-reading ten transcripts.
- **The checkpoint rule** — if it hits a decision that would change the design, sample, spec, or estimand, it **reports back and stops** rather than resolving it; that decision routes to the user via `analysis-checkpoints`.

## Between every step: validate, then checkpoint

Execution is not "run to the end and show the user." After each spine step and as fan-out results land:

- **Validate** the result against its contract (`data-contracts`); reconcile totals; if a number looks wrong, switch to `wrong-number-debugging`.
- **Checkpoint** any consequential decision that surfaced (`analysis-checkpoints`) — execution is exactly when "the data surprised us, let's change the design" arises, and that's the user's call, not a step you take to keep moving.

## Keep durable state live, and compact at phase boundaries

A long analysis with many mid-step fixes drags context until auto-compaction fires at a random, lossy moment, losing gotchas and decisions you can't afford to lose. Don't wait for that: **actively maintain the plan/brief/model card as you go** — mark steps done, record the gotcha you just hit — a living document, not something you wrote once at the start.

Make the trigger **mechanical**, not a vibe: run the update-and-offer-compact routine **after each completed spine step and after the fan-out is assembled** (the checkpoints the skill already defines), not whenever a phase "feels" done. At each:

1. **Update `docs/analysis/` so it stands on its own** — invoke `analysis-state-management` and update whichever records changed (see its own "How To Update State" for which file). State lives in the repo, not the chat, and it must carry the decisions locked and why, the key insight so far, and the concrete next step as a resume-from-clean-slate instruction.
2. **Offer to compact**: "this is a clean point to `/compact` — `docs/analysis/index.yaml` points to the decisions, insight, and next step, so we resume on a clean slate without losing anything." You can't compact yourself (the user runs `/compact`), so *suggest* it — at real phase boundaries only, never mid-step, and easy to wave off.
3. On resume, follow `analysis-state-management`'s Resume Rule: `index.yaml` first, then only the records it names, continuing from `next_action`.

The test: **if the conversation were compacted right now, could a clean session pick up from `docs/analysis/index.yaml` plus the named records alone?** If not, the state isn't finished — write the missing state *before* you suggest the compact.

## Synthesis

When the fan-out completes, assemble — don't just dump:
- Build the **robustness table**: primary estimate beside every alternative, so stability (or fragility) is visible at a glance.
- **Reconcile across specs**: if the headline swings under a reasonable alternative, that's a finding to surface, not a result to bury.
- Note which subagents' contracts **failed** — a robustness spec that violated an invariant is not a clean "it's robust."
- Hand off to **`result-verification`** before any of this is reported.

## Red flags — STOP

- Starting execution with no approved plan to execute.
- **Fanning out an exhaustive *menu* of robustness checks instead of proposing the ~3 that probe the main threat and getting approval first.** More checks ≠ more credibility.
- Parallelizing steps that actually depend on each other (e.g. estimating before the dataset is validated).
- A subagent that resolved a design/sample/spec decision on its own instead of reporting it back.
- Improvising new specifications mid-execution that weren't in the plan, without surfacing them.
- Presenting fanned-out results without reconciling them or checking each one's contracts.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "More robustness checks make it more convincing." | Less — a wall of specs reads as theater and hides the one check that matters. Pick the few that could actually break the result. |
| "Running them is cheap now, so why not run them all?" | Cheap-to-run is the trap; the cost is the reader's trust and the buried signal. Propose ~3 and get approval. |
| "The subagents can figure out the spec." | An under-specified subagent invents its own analysis — deciding behind the user's back, in parallel. Hand each one the exact recipe. |
| "A robustness check failed its data contract, but the coefficient looks fine." | A spec run on corrupted data isn't robustness, it's noise. The contract failing is the result. |
| "The data suggested a better spec, so I added it." | That's specification search. Surface it as a checkpoint; run it labeled exploratory if approved. |
| "I'll show all the results at the end." | A wrong intermediate poisons everything after it unseen. Validate each step as it lands. |

## The Process

1. **Build / clean / join the dataset → delegate to `data-preparation`** (unless it's a trivial load of one already-clean file); it returns the clean, validated dataset.
2. **Validate every later spine step + fanned-out spec before trusting a number** → *invoke `data-contracts`*.
3. **Fork by design as you estimate** — reduced-form → *invoke `causal-identification`* for the robustness suite; structural → *invoke `structural-estimation`* for recovery reps, starts, and counterfactuals.
4. **Keep the code minimal and surgical on every write → invoke `analysis-craft`.**
5. **Any decision that changes design/sample/spec/estimand — or any number the user has already seen — STOP and invoke `analysis-checkpoints`.** A surprising result is a checkpoint, not a step; a number that looks wrong is `wrong-number-debugging`, not a silent patch.
6. **Spine + fan-out complete, before any result is written → invoke `result-verification`.** Don't end at "here are the results" — reconcile, reproduce, then hand off.
## The bottom line

```
Executing well  →  approved plan worked top to bottom, spine validated in order, independent specs fanned out to subagents, every result reconciled, deviations stopped for the user
Otherwise        →  a serial half-run of an unapproved plan, with the robustness suite quietly truncated
```
