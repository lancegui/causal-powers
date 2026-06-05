---
name: question-framing
description: Use BEFORE starting any data analysis, metric, model, or causal study — the moment someone asks "what's the trend", "is X driving Y", "how many users", "did the policy work", "build me a dashboard metric", or hands you a dataset to "look into". Pins down the estimand/metric definition, population, unit of observation, and the actual decision the number informs before a single line of code is written. Use this even when the request feels clear, because vague metric definitions ("active users", "the effect of X") are the root cause of analyses that answer the wrong question precisely.
---

# Question Framing

## Overview

The most expensive analytics mistake is not a wrong number — it's a *right answer to the wrong question*. It survives every validation check, reconciles perfectly, reproduces exactly, and is still useless, because the metric measured something other than what the decision needed.

This is the analytics counterpart of brainstorming a feature before building it. Before you load data, you nail down what you're actually being asked and what a good answer would change.

**Core principle:** Define the estimand and the decision before you touch the data — because once you see the data, your definition will quietly bend to fit what's easy to compute.

## The framing brief

Produce a short written brief — a few lines, not a document — that answers these. Each one is a place analyses go wrong:

1. **The decision.** What action does this number inform, and who takes it? If no decision rides on it, scope it down or drop it. "Interesting" is not a spec.
2. **The estimand / metric, exactly.** Not "engagement" but "median sessions per 7-day-active user, per calendar week, in the US." Not "the effect of the pricing change" but "the change in 30-day retention for users who saw the new price vs. those who didn't." Pin the **numerator, denominator, unit, and time window**.
3. **Population and filters.** Who is in and who is out? New vs. existing? Which date range? Which segments? Every filter is an assumption — name it.
4. **Unit of observation.** Per user? per session? per transaction? per user-week? Most double-counting and most wrong denominators trace to a fuzzy unit of analysis.
5. **What would change the answer / decision.** What result would flip the decision? If *any* number leads to the same action, you don't need the analysis. This also tells you the precision you actually need.

For a **causal** question, add three more and hand off to `causal-identification`:

6. **Treatment** — what intervention, defined precisely, and when.
7. **Counterfactual** — compared to *what*? "Effect" is meaningless without the comparison condition.
8. **Estimand type** — ATE, ATT, LATE, intent-to-treat? They answer different questions and a stakeholder usually has one in mind without knowing the name.

## Watch for the silent reframe

The danger isn't refusing to define the question — it's defining it, then letting it drift. You write "30-day retention," discover the data only cleanly supports 28-day windows, and silently switch. Now you're answering a slightly different question and nobody agreed to it. When the data forces a change to the definition, **surface it and re-confirm**, don't absorb it.

## Surface hidden disagreement early

Stakeholders routinely use the same word for different things. "Active users," "revenue," "churn," and "conversion" each have several incompatible definitions in common use. The cheapest moment to discover that you and the requester mean different things is *before* the analysis, by stating your definition back and asking "is this what you mean?" — not in the meeting where you present a number that contradicts theirs because you each counted differently.

When the request is genuinely ambiguous, **state your assumption explicitly and present the competing interpretations** rather than silently picking one and computing it. "Churn could mean cancelled-this-month or no-activity-in-30-days; these give different numbers — which do you want?" costs one sentence now and saves a re-run later. Don't hide the ambiguity by resolving it quietly in your head; an assumption the requester never saw is the one that turns out wrong.

## Red flags — STOP and frame

- You're about to load data and you can't state the denominator of the metric in one sentence.
- The request is a noun, not a question: "user engagement", "the sales data", "churn." Turn it into a decision.
- "Effect of X" with no stated comparison group or counterfactual.
- Two stakeholders in the thread who would each define the key metric differently, and nobody has noticed.
- You're choosing the metric definition based on what's easy to compute rather than what the decision needs.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "The question is obvious, just let me dig in." | The questions that feel obvious are exactly the ones where your definition and the requester's quietly differ. |
| "I'll define the metric once I see what's in the data." | Then the data defines the question, and you'll answer whatever is convenient rather than what matters. |
| "They just want a number." | A number with an unstated definition is a number with an unstated bug. |
| "Framing is overhead, the analysis is the real work." | An analysis that answers the wrong question is 100% waste, however rigorous. |

## Relationship to sibling skills

- For a confirmatory study, turn the brief into a locked **`pre-analysis-plan`** before seeing outcomes.
- Once the question is framed, enforce the metric definition with **`data-contracts`**.
- For causal questions, hand the treatment/counterfactual/estimand to **`causal-identification`**.

## The bottom line

```
Good analysis  →  the decision, the exact metric, the population, the unit, and what would flip it — all named before code
Otherwise      →  a precise answer to a question nobody asked
```
