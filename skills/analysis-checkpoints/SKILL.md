---
name: analysis-checkpoints
description: Use throughout the EXECUTION of any analysis — while running, debugging, modeling, or cleaning data — to decide which decisions you may make on your own and which you must STOP and bring to the user first. Forces a human-in-the-loop checkpoint before any consequential analytical choice: changing the research design, estimand, or identification strategy; deviating from the framed question or pre-analysis plan; dropping/filtering/winsorizing data or changing the sample; choosing between materially different specifications; redefining a metric; or changing any number the user has already seen. Use this whenever you catch yourself about to "just fix it", "upgrade the design", "drop the outliers", or otherwise decide something on the user's behalf — especially mid-debugging, where design changes get smuggled in as bug fixes.
---

# Analysis Checkpoints

## Overview

Autonomy is the point of a good analysis loop — and also its biggest hazard. You can iterate fast toward a goal, but the same momentum that makes you productive makes you redefine the goal mid-flight without noticing: a debugging session quietly becomes a redesign, an outlier "obviously" gets dropped, a near-vs-far DiD silently becomes a triple-difference. Each step felt like progress. Collectively, the user got an analysis they never agreed to.

**Core principle:** Loop autonomously *toward the agreed goal*. Never redefine the goal — the design, the sample, the spec, the estimand, the metric — behind the user's back. When execution wants to change any of those, that is a **checkpoint**, not a task: stop, surface it, and let the user decide.

This is the execution-time form of "Think Before Coding": don't decide silently, surface the tradeoff. The up-front skills (`question-framing`, `pre-analysis-plan`) establish the agreed goal; this skill protects it while the work runs.

## The line: your call vs. the user's call

The test is simple — **does this change what is being estimated, on what data, or a number the user has already seen?** If yes, it's the user's call.

### Decisions that REQUIRE a checkpoint — STOP and ask
- **Design / identification strategy.** Switching estimators or designs (near-vs-far DiD → triple-difference, OLS → IV, adding/removing a fixed effect that changes identification, changing the comparison group). This is the most commonly smuggled-in change.
- **Any deviation from the framed question or the pre-analysis plan.** The PAP exists precisely so these stops happen. A deviation is allowed — but disclosed and approved, never hidden.
- **The estimand.** ATE vs. ATT vs. LATE, the population, the time window.
- **The sample.** Dropping rows, filtering, winsorizing, trimming, excluding outliers, changing inclusion/exclusion rules, restricting to a subsample.
- **Materially different specifications or models** where there's a real tradeoff (functional form, control set, clustering level, missing-data handling, imputation).
- **Metric definition / units / grain.** Redefining the numerator or denominator, changing the unit of observation.
- **Any number the user has already seen** that your change would move.

### Decisions you may make autonomously — note it, don't ask
- **Mechanical data-bug fixes that *restore* the intended computation** — dedup a key that was always meant to be unique, correct a wrong join type, fix a units error, repair a broken date parse. These return the analysis to what was already agreed; they don't change the design. Always **report** what you fixed.
- **Code-craft choices** — variable names, how a transform is written, plot styling. (See `analysis-craft`.)

The dividing question between a fix and a redesign: *"Am I restoring the analysis we agreed on, or changing it?"* Restoring → proceed and report. Changing → checkpoint.

## How to run a checkpoint

When you hit one, stop and present — don't implement past it:

1. **Name the decision** plainly: "This is a change to the identification strategy."
2. **Show the evidence** that surfaced it: the diagnostic, the number, the failed check.
3. **Lay out the options** — at least two — each with its tradeoff and what it would change about the result.
4. **Give your recommendation and why** — you're not abdicating judgment, you're surfacing it for approval.
5. **WAIT.** Do not write the redesign, drop the rows, or re-estimate until the user chooses. Implementing "so it's ready for them to see" is the exact failure mode.

**Worked example (the kind that should always stop):**
> While debugging the high near-clinic effect I found the 2016 citywide recording jump is geographically uneven — Beverly's 2 mi ring is +66% in 2016 while its 0.5 mi ring is flat. A plain near-vs-far DiD would misread this as an acquisition effect.
> **Options:** (a) upgrade Design B to a triple-difference (add band×month FE to absorb the citywide near-vs-far differential) — most robust, but changes the pre-registered design; (b) keep Design B and add the differential as a documented caveat; (c) restrict to cities without the uneven jump.
> **My recommendation:** (a), because it directly removes the confound — but it's a deviation from the PAP, so it's your call.

That stops *before* the band×month FE is written. The earlier behavior — writing the triple-difference and presenting it as "the fix" — is what this skill exists to prevent.

## "Loop until verified" ≠ "loop until you like the number"

Goal-driven autonomy (from `analysis-craft` / the gateway) means: iterate freely toward **fixed, agreed success criteria**, and don't stop at "the code ran." It does **not** authorize changing the criteria, the design, or the sample to reach a result. If hitting the goal seems to require changing the goal, that's the loudest possible checkpoint — stop and say so.

## Red flags — STOP

- You're mid-debugging and about to "upgrade", "switch to", or "fix" the design/spec to make a number behave.
- You're about to drop, trim, or winsorize data the user didn't ask you to drop.
- A change you're making would move a number the user has already seen, and you weren't going to mention it until the end.
- You've started writing the redesigned model *before* the user agreed to redesign.
- You're treating a deviation from the PAP as an implementation detail.
- You catch yourself thinking "they'll obviously want this" — that's the rationalization that precedes deciding for them.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "It's clearly the right fix, I'll just do it." | If it changes the design or sample, "right" is the user's judgment to make. Surfacing it costs a paragraph; the wrong silent change costs their trust in every number. |
| "I'm just fixing a bug." | Restoring the agreed computation is a fix. Changing what's estimated is a redesign wearing a bug's clothes. Ask which one it is. |
| "I'll show them the redesigned version, that's clearer." | Then they're reviewing a fait accompli, not deciding. Present the options before you build one. |
| "Stopping breaks my flow." | Your flow is not the goal. An analysis the user didn't authorize is rework at best and a wrong decision at worst. |
| "Looping until verified means I keep going." | Toward the agreed goal — yes. By changing the goal — no. That's the line. |

## Relationship to sibling skills

- The agreed goal you're protecting is set by **`question-framing`** and locked by **`pre-analysis-plan`** — a checkpoint is often "this deviates from the PAP."
- **`wrong-number-debugging`** is where design changes most often get smuggled in as fixes; it routes those here.
- **`causal-identification`** decides *whether* a design change is warranted; this skill decides *who* gets to authorize it (the user).
- Restoring vs. redesigning parallels `analysis-craft`'s surgical-change discipline applied to the analysis itself, not just the code.

## The bottom line

```
Executing well  →  loop autonomously toward the agreed goal; stop and ask before changing the design, sample, spec, estimand, or any number already seen
Otherwise        →  an analysis the user never agreed to, assembled one reasonable-looking step at a time
```
