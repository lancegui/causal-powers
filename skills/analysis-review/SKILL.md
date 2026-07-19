---
name: analysis-review
description: Use when reviewing a data analysis, notebook, script, model, or result — your own before you ship it, a colleague's before it's published, or one handed to you to "check" or "sanity-check" — in R, Julia, Python, or Stata. Hunts specifically for the silent-failure classes that pass code review but produce wrong answers — unchecked joins, leakage, fished specifications, unreconciled totals, undefined metrics, identification gaps, and structural-model failures (non-identified parameters, no recovery test, counterfactuals with prices held fixed). Use when the user says "review this analysis", "can you check my notebook", "does this look right", "sanity-check these numbers", "before I send this", or is about to accept someone else's analytical result. Also use when receiving review feedback on your own analysis, to verify the critique rather than reflexively agreeing.
---

# Analysis Review

## Overview

Code review asks "is this code correct?" Analysis review asks a harder question: "is this *conclusion* correct?" — and the two come apart completely. Analytics code can be clean, idiomatic, well-tested, and pass any software review while delivering a confidently wrong number, because the bugs that matter here don't live in the syntax. They live in a join that fanned out, a metric nobody defined, a feature that leaked the target, a specification that was fished. This skill is a review lens aimed at exactly those.

**Core principle:** Review the path from data to claim, not just the code. The question is never "does it run?" — it's "would I bet the decision on this number?"

**"Review it" re-fires this skill every time — including mid-session.** A design you reviewed last week, or earlier in this conversation, doesn't stay reviewed: a new cut, a re-run, or a fresh "does this look right?" is a new artifact to review from scratch. Don't answer from loaded context ("I already looked at this") — re-run the checklist against *this* result.

## Reviewing an analysis — the checklist

Start from **`result-verification`'s verification checklist** — reconcile to source, reproduce from a clean state with a fixed seed, joins/cardinality, missingness, units/grain, artifacts tied to prose — run it, don't re-derive it here. Review adds the adversarial lens (below), plus what that checklist doesn't cover:

**The claim**
- Is the **metric/estimand defined** precisely enough that you could recompute it the same way? (If "active users" or "the effect" is undefined, stop here — see `question-framing`.)
- Does the **conclusion actually follow** from the number, or is it a causal claim resting on a descriptive estimate?

**Models & causal claims**
- **Leakage:** any feature that encodes the target, any train/test overlap, any future information in a predictor? Leakage is the most common reason a model metric is "too good."
- **Identification:** for any causal claim, is the design named and are its assumptions stated and tested? (Hand off to `causal-identification` — parallel trends, first-stage F, manipulation test, balance.)
- **Specification search:** were the reported specs chosen before or after seeing results? Are the robustness checks the complete set, or a flattering subset? (See `pre-analysis-plan`.)
- **Structural models:** is each parameter's identification stated — what variation or moment moves it? Was the estimator shown to recover known parameters (a Monte-Carlo recovery test), or is a converged optimizer being taken as proof of identification? Is any counterfactual computed by *re-solving equilibrium* rather than holding prices fixed? Is the conduct/distribution assumption flagged as load-bearing and untestable? (Hand off to `structural-estimation`.)

**Prediction models** (when the deliverable is a score / flag / ranking, not an effect — the `predictive-modeling` arm):
- The class-by-class hunt list — leakage variants, deployment-mismatched splits, tuning-on-test, importance-read-as-causal, proxy labels, missing baselines, anomalous-read-as-guilty — lives in **`agents/analysis-reviewer.md`**, which the reviewer agent carries. Don't restate it here; dispatch the agent (below) or open that file when reviewing inline.

## Run it as an independent agent

**For your OWN analysis, pre-ship, dispatching the `analysis-reviewer` agent is
REQUIRED — an inline self-review does not satisfy this skill.** You cannot supply
your own independence: the reviewer's value is fresh context hunting what the
author rationalized, and it returns concrete findings with severity rather than
a rubber stamp. Reviewing someone else's work, you already are the fresh
context — inline is fine. Either way, use it in addition to, not instead of,
reviewing as you go.

## Review like an adversary, not a proofreader

The useful question isn't "can I follow this?" — it's "how would this be wrong, and what would I check to find out?" For each headline number, form the specific failure hypothesis (this total looks high → maybe the join fanned out) and ask for the evidence that rules it out (show me the row counts). A review that only confirms the code is readable has reviewed the wrong thing. If you can't see the intermediate checks, the right response is "show me the reconciliation," not "looks good."

## How to request a review (so it's worth something)

If you're the author, make the analysis reviewable:
- State the **question, metric definition, and decision** up front (the `question-framing` brief).
- Show the **invariant checks** you ran — the join row-counts, the reconciliation, the missingness counts — not just the final chart.
- Flag what's **confirmatory vs. exploratory**, and which robustness checks you ran.
- Point the reviewer at the **load-bearing assumption** and ask them to attack it specifically.

A review of a polished output with no visible checks can only catch typos. Hand over the checks.

## Receiving review feedback — verify, don't perform

When someone critiques your analysis, the failure mode is reflexive agreement: "good catch, fixing now" to a critique you haven't verified. That's as bad as reflexive defense. The discipline is to **check the claim against the data**:
- If they say "this join looks like it double-counts," go run the row-count check and see. Confirm it bites before you change anything.
- If the critique is technically wrong, show the evidence that it's wrong — politely, with the reconciliation, not with an opinion.
- A critique you can't yet evaluate gets investigated, not agreed to. Performative agreement ships the bug with a thank-you attached.

## Red flags — STOP

- A review that signed off on "clean, readable code" without ever seeing a single data-integrity check.
- A headline number with no reconciliation and no row-count checks around its joins, presented as final.
- A model metric that's suspiciously good and no one has looked for leakage.
- A causal claim whose identification assumptions were never stated.
- Robustness checks that are exactly the ones that agreed with the headline.
- Agreeing to a review comment (or rejecting it) without running the check that would settle it.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "The code is clean, so the analysis is fine." | Clean code computes the wrong thing just as reliably as messy code. Review the data path. |
| "I trust the author, they're careful." | Careful people fan out joins too. The check costs a minute; trust isn't a row-count. |
| "It's just an internal review, ship it." | The internal number drives the decision. Internal is exactly when nobody else will catch it. |
| "They flagged it, so it must be wrong — fixing." | Maybe. Verify it against the data first; agreeing without checking can introduce a new bug. |
| "There's no time to ask for the intermediate checks." | Then there's no time to know whether the number is real. Reviewing only the output is reviewing nothing. |
| "result-verification already covered all of this." | Verification proves the number reproduces and reconciles. Review hunts what reproducibility can't catch — leakage, bad controls, fished specs. Different failure classes; both run. |

## The Process

1. **Run the checklist against *this* artifact** — claim, data path, models/causal claims, reproducibility. Don't answer from loaded context.
2. **For each headline number, form the failure hypothesis and demand the evidence that rules it out** — row-counts, reconciliation, missingness, leakage check, identification statement.
3. **Route every finding to a fixing skill — never stop at "here are my notes":**
   - Wrong number / unreconciled total / fanned-out join → **STOP and invoke `wrong-number-debugging`** to bisect to the bad step.
   - Design issue — identification gap, fished spec, structural misspecification → **STOP and invoke `analysis-checkpoints`** to route the decision to the user (it in turn hands to `causal-identification`, `pre-analysis-plan`, or `structural-estimation`).
4. **Log each confirmed finding's failure class** — one line per finding to the project's `docs/LESSONS.md` (symptom, cause, the check that would have caught it; create the file if absent). A review that only fixes this artifact fixes one artifact; the logged pattern hardens every future one (`result-verification` → "Capture what bit you").
5. **If it's clean** — metric defined, joins checked, totals reconciled, leakage ruled out, identification stated, reproduces from a clean seed → **return to `result-verification`** to ship.

## The bottom line

```
Reviewed analysis  →  metric defined, joins checked, totals reconciled, leakage ruled out, identification stated, reproduces clean
Otherwise          →  you reviewed the spelling, not the answer
```
