---
name: using-causal-powers
description: Use when starting any data analysis, statistics, econometrics, or causal-inference task in R, Julia, or Python — establishes the Causal Powers discipline and routes to the right skill (question-framing, pre-analysis-plan, data-contracts, wrong-number-debugging, result-verification, causal-identification, analysis-review). Invoke this whenever someone asks you to analyze data, compute a metric, clean or merge datasets, fit a model, estimate an effect, or check a number — even if they only say "analyze this", "what's the trend", or "did it work" — so the right discipline skill fires before you touch the data.
---

# Using Causal Powers

## The creed

A number you computed but never validated is a guess wearing a lab coat. In software the dangerous bug throws a stack trace; in data analysis it runs clean and hands you a confident, wrong answer. Causal Powers is a family of skills that make the silent failures of data work loud — *before* they reach a stakeholder.

## The rule

For any analysis task, **invoke the relevant discipline skill before acting** — before exploring the data, before writing the transform, before reporting the number. Process skills (framing the question, planning, debugging) come before implementation. Even a 1% chance a skill applies means you check it.

## The family — and when each fires

| Skill | Use it when… |
|---|---|
| **`question-framing`** | Before any analysis — to pin the estimand/metric, population, unit, and the decision the number informs. The "what are we actually measuring" skill. |
| **`pre-analysis-plan`** | Before a *confirmatory* study (experiment readout, policy eval, anything with stakes) — lock hypotheses, primary spec, and robustness suite before seeing outcomes. |
| **`data-contracts`** | Whenever you load, transform, clean, **join/merge**, aggregate, or model — assert invariants and join cardinality, reconcile totals, freeze baselines. The everyday workhorse. |
| **`wrong-number-debugging`** | The moment a number looks wrong, surprising, or won't reconcile — bisect the pipeline to the bad step instead of patching the symptom. |
| **`result-verification`** | Before reporting, presenting, or calling it done — reconcile, reproduce from a clean state, attack with robustness, tie figures to prose. |
| **`causal-identification`** | Any causal claim or design (DiD, event study, IV, RDD, matching, FE, synthetic control) — state and test the identification assumptions; run the mandatory robustness battery. |
| **`analysis-review`** | Reviewing an analysis (yours or another's) for the silent-failure classes, or receiving review feedback and verifying it. |

## The typical flow

```
question-framing  →  [pre-analysis-plan if confirmatory]  →  data-contracts (load/clean/join/aggregate)
   →  [causal-identification if causal]  →  [wrong-number-debugging when something's off]
   →  result-verification  →  [analysis-review before it ships]
```

Most work flows from **exploration** (hunt for the answer; validate every input and intermediate) into a **reusable, contracted rule** (lock it down with tests and a frozen baseline). The mistake is staying in exploration forever and shipping it as if it were production.

## Instruction priority

These skills override default behavior, but **user instructions always win**. If the user (or a project's CLAUDE.md) says to skip a step, follow the user — they're in control. The skills tell you *how* to do rigorous analysis when rigor is wanted.

## The bottom line

You are not slowing the analysis down. You are refusing to be confidently wrong — which is the only failure mode in data work that actually costs anything.
