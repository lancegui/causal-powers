---
name: causal-identification
description: Use whenever an analysis makes or implies a CAUSAL claim — "the effect of", "X caused Y", "the policy raised", "the treatment increased", "because we did X, Y changed" — or whenever you're running difference-in-differences, event studies, instrumental variables, regression discontinuity, matching, synthetic control, or panel fixed-effects models. Forces the identification strategy and its assumptions to be stated and tested BEFORE estimating, and treats the design-specific diagnostics (parallel trends, first-stage strength, manipulation tests, balance) as mandatory — placebo and sensitivity checks are a user-approved ~3-check shortlist, not an automatic battery. Use in R, Julia, or Python even when the user just says "regress Y on X", "did it work", or "estimate the impact" — a regression coefficient is not a causal effect until the design earns it.
---

# Causal Identification

## Overview

A regression coefficient is a correlation with good posture. It becomes a causal effect only when a *design* rules out the other explanations — and that design rests on assumptions no amount of clean data or tight standard errors can supply. The fatal error is silent: the code runs, the coefficient is significant, the sign is plausible, and it's still confounding wearing the costume of an effect.

**Core principle:** State the identification assumptions before you estimate, and test the ones that are testable. The estimate is only as credible as the assumption you can't test.

Before any model, answer the Angrist–Pischke question: **if you could run the ideal randomized experiment, what would it be — and what real-world variation are you using as a stand-in?** Name the source of variation in one sentence and argue it's as good as random, or you have a regression hoping to be an identification strategy.

## The Design Card — sign-off before estimation

A causal claim locks a **Design Card** — invoke `analysis-state-management`, write it to `docs/analysis/` (or point to the PAP), get sign-off before estimating. (Structural → model card, prediction → Prediction Spec — same gate, different document; mechanics owned by `analysis-checkpoints`.) Fields:

- **Causal question + estimand** — ATT/ATE/LATE, for which population.
- **Design + source of variation** — the "what's your experiment?" answer, one sentence.
- **The untestable assumption**, in plain language, and why it's plausible *here*.
- **Diagnostics planned** — the design-specific tests you'll run before reading the estimate.
- **Robustness shortlist** — the ~3 checks aimed at the main threat (approval-gated, see below).
- **Primary spec** — outcome, treatment, FE/controls (each control with its confounding story), SEs/clustering.

Entering mid-stream ("just run the DiD") does not waive the card: "the user already said regress Y on X" names the *spec*, not the *design* — reconstruct the card from context in ≤10 lines and confirm before estimating.

## The discipline

1. **Name the design and the source of variation:** what's treated vs. control, and *why* is the control a valid counterfactual? If you can't name the design, you don't have identification — you have a regression.
2. **State the assumptions out loud**, especially the untestable one — every design has a load-bearing assumption you can't verify from data (exclusion, parallel trends, continuity, unconfoundedness). Name it and argue why it holds here.
3. **Test the testable implications** (the diagnostics below). **Borderline diagnostics are a checkpoint, not a green light** — a first-stage F of 8, a mildly sloped pre-trend, balance that *almost* resolves: surface these, don't proceed past them silently.
4. **Estimate** with inference appropriate to the design (clustering, weak-IV-robust, etc.).
5. **Attack it** — propose the ~3 threat-relevant robustness/placebo checks, get approval, then run them (see "Robustness, placebo, sensitivity" below — not the whole catalogue).
6. **Reconcile** the causal estimate with the raw descriptive picture. An effect that's invisible in the raw data and only appears after heavy modeling deserves suspicion.

## Presenting a design — spell it out

A design presented to the user is a decision document. Every presentation of a specification — in a plan, a checkpoint, a results write-up — carries five things:

- **The estimating equation, written out.** Display math (or plain text), not a name-drop: $y_{it} = \beta D_{it} + \alpha_i + \gamma_t + \varepsilon_{it}$ — with **every subscript defined** (what is $i$, what is $t$, what population, what period) and **the level of variation stated**: what level treatment varies at, what level the outcome is measured at, what the fixed effects absorb, what level you cluster at and why. "TWFE DiD" is a family, not a specification.
- **The economic intuition.** Nearly every model and estimator has one — the comparison in plain language and why it recovers the effect ("adopting counties are compared to never-adopters in the same month, netting out anything fixed about a county and anything common to a month; identification rests on the two groups trending together absent the policy"). If you can't state the intuition, you don't understand the design well enough to run it. Convince the reader; don't assert.
- **The literature precedent.** Name the published design this follows — the nearest antecedent, top-5-journal focus (AER, QJE, JPE, ECMA, ReStud, plus the field's flagship). **Don't invent a design when the literature has one.** A specification with no named precedent is a flag: either you haven't done the literature review (do it — `econ-writing:literature-review` when the stakes warrant a real one) or the design is genuinely novel, which you state explicitly and justify as a deliberate departure the user signs off on.
- **No shorthand.** Never refer to a specification, hypothesis, or plan node by a bare internal id — "a1", "h1", "spec 3" mean nothing to a reader who didn't watch the plan being built. Restate what it is in words every time ("the reviewer-capacity event study"); an id may follow in parentheses, never stand alone.
- **Interpretable from the start.** State up front what units $\beta$ will be in and what magnitude would be economically meaningful (ties to the reporting red-line).

## Choosing or changing the design is the user's decision

A failed diagnostic (pre-trends violated, weak first stage) or a newly discovered threat is `analysis-checkpoints` territory, not a silent upgrade: surface the **threat, candidate remedies, and your recommendation** — "parallel trends is violated; switch to triple-difference, restrict the sample, or report with a caveat" — and let the user decide.

## Per-design assumptions and diagnostics

Tag discipline: **Test** items are *diagnostics* — run before/with
estimation, no approval needed. **Robustness** items (and every placebo)
belong to the approval-gated ~3-check shortlist (see "Robustness, placebo,
sensitivity" below). Don't reclassify a placebo as a diagnostic to skip the
checkpoint, or a pre-trend test as robustness to stall it.

### Difference-in-differences / event study
- **Load-bearing assumption:** parallel trends — treated and control would have moved together absent treatment. Untestable directly; argue it.
- **Test:** pre-treatment trends (event-study coefficients; flat, insignificant leads support but don't prove parallel trends), **anticipation** (effects before treatment), and **no compositional change** in the panel around treatment.
- **Staggered adoption is a trap:** with variation in treatment timing, two-way fixed effects (TWFE) is biased by "forbidden comparisons" of late-treated to already-treated units. Use a modern estimator: **Callaway–Sant'Anna, Sun–Abraham, Borusyak et al., de Chaisemartin–D'Haultfœuille, `did2s`** — not vanilla TWFE.
- **Inference:** cluster SEs at the treated unit (e.g., state), and worry about too-few clusters.

### Instrumental variables
- **Relevance (testable):** report the **first-stage F**; a weak instrument (F < 10 rule of thumb, prefer Olea–Pflueger) biases 2SLS and its SEs — use **weak-instrument-robust inference** (Anderson–Rubin) when in doubt.
- **Exclusion (untestable):** the instrument affects the outcome *only* through the treatment. Cannot be tested — argue it substantively; the whole IV stands or falls here.
- **Monotonicity:** no "defiers" — needed for the estimate to be a valid **LATE** (effect on compliers), not ATE.

### Regression discontinuity
- **Continuity (load-bearing):** units just above and just below the cutoff are comparable; potential outcomes are continuous at the threshold.
- **No manipulation:** units can't precisely sort around the cutoff — test with a **McCrary / density test** for a jump in the running variable.
- **Robustness:** **bandwidth** sensitivity (a principled bandwidth via `rdrobust`), **covariate smoothness** at the cutoff, a **donut** spec excluding points near it, and placebo cutoffs away from the real one.

### Matching / regression adjustment / propensity scores
- **Unconfoundedness (untestable):** selection into treatment is on observables only — the strongest assumption in the toolkit, argue it hard.
- **Overlap / common support (testable):** treated and control propensity distributions overlap. Trim or stop if they don't.
- **Balance (testable):** post-matching/weighting covariate balance — report **standardized mean differences** (rule of thumb |SMD| < 0.1), not just t-tests.

### Panel fixed effects
- Identify off **within-unit variation** — confirm there is enough of it; a near-time-invariant regressor is barely identified.
- FE controls only **time-invariant** confounders; time-varying confounders still bite.
- Cluster SEs at the appropriate level.

### Synthetic control
- **Load-bearing assumption:** no anticipation, and the treated unit's counterfactual lies in the convex hull of a genuinely comparable donor pool. Good pre-period fit is necessary but **does not guarantee** the post-period counterfactual.
- **Inference:** placebo/permutation across donor units (the RMSPE ratio), not a naïve p-value; report how extreme the treated unit's gap is in the placebo distribution.

### ML in service of a causal effect (double/debiased ML, causal forests, ML propensity)
The estimator changed, not the assumptions:
- **Cross-fit nuisance models** (outcome, propensity) on folds disjoint from where their predictions enter the moment condition, or the bias leaks back in.
- **Report overlap/positivity and nuisance diagnostics** (fit quality, propensity distribution) — ML propensities pushed to 0/1 are a design failure, not just a modeling detail; report more than the final θ and its SE.
- **Use the orthogonalized/debiased score** — never read the estimate off a plug-in coefficient from the ML fit.
- **CATE heterogeneity ≠ a targeting license** — deploying causal-forest scores needs the same unconfoundedness argument as the ATE, plus `predictive-modeling`'s deployment-matched evaluation.
- **The Design Card still applies** — ML can't repair a design; unconfoundedness/exclusion still carries the estimate.

## Bad controls — the quiet killer of reduced-form work

Adding a control can *create* bias as easily as remove it. The rule: only condition on variables determined **before** treatment — and even that is necessary, not sufficient: a pre-treatment collider (M-bias) or a bias-amplifying near-instrument is still a bad control. Every control needs a confounding story, not just a timestamp. A control that is itself an outcome of the treatment reopens the very confounding you're trying to close.

- **Post-treatment controls / mediators.** Controlling for a channel the treatment works through (e.g. "effect of education on wages, controlling for occupation") nets out part of the effect — usually toward zero, sometimes unpredictably. If it could plausibly have been *affected* by treatment, it is not a control.
- **Colliders.** Conditioning on (or selecting the sample on) a variable that both treatment and outcome cause induces a spurious association where none existed.
- **Selection on the outcome.** Filtering the sample on the dependent variable (or anything downstream of it) manufactures correlation.

"I added more controls and it got more robust" is not reassurance — more controls can mean more bias. Each control needs a reason it's pre-determined, not just a wish to be thorough.

## Robustness, placebo, sensitivity — not optional

These are part of the estimate, not a courtesy — but **robustness is an argument, not an inventory.** "Mandatory" means the *threat-relevant* checks, not the whole per-design catalogue: three checks that probe the real threat beat thirty that probe nothing, and a sprawling robustness table reads as a *tell* of weak identification. **Propose the ~3-check shortlist with rationales and get approval before running it** — a checkpoint, not an autonomous fan-out (`executing-analysis-plans`, `analysis-checkpoints`).
- **Placebo / falsification:** an effect on an outcome that shouldn't be affected, or in a period before treatment, signals that the design is picking up confounding.
- **Sensitivity to unobserved confounding:** how strong would an omitted confounder have to be to overturn the result? Use **Oster's δ**, **Rosenbaum bounds**, or **e-values** — a result that flips under a mild plausible confounder is not robust.
- **Specification stability:** the effect shouldn't hinge on one control or one functional form (run the pre-committed suite from `pre-analysis-plan`).

## Tooling (R / Julia / Python)

| Design | R | Python |
|---|---|---|
| FE / DiD (TWFE) | `fixest::feols` | `linearmodels.PanelOLS`, `pyfixest` |
| Staggered DiD | `did` (Callaway–Sant'Anna), `did2s`, `fixest::sunab` | `differences`, `pyfixest` |
| IV | `fixest::feols`, `ivreg` | `linearmodels.IV2SLS` |
| RDD | `rdrobust`, `rddensity` (McCrary) | `rdrobust` (py) |
| Matching / PS | `MatchIt`, `WeightIt`, `cobalt` (balance) | `causalinference`, `dowhy`, `econml` |
| Sensitivity | `sensemakr` (Oster/Cinelli), `rbounds` | `sensemakr` (py) |

Julia: `FixedEffectModels.jl` covers FE/DiD and IV; little else has a mature
implementation. When a stack lacks one (much of staggered-DiD and RDD
outside R), say so — call out to R or implement explicitly rather than
silently falling back to biased TWFE.

## Red flags — STOP

- Reporting "the effect of X" from a regression with no named design and no stated counterfactual.
- A staggered-treatment DiD estimated with plain TWFE and no mention of the bias.
- An IV with no reported first-stage F, or treating LATE as if it were ATE.
- An RDD with no manipulation/density test.
- Matching that reports significance but never reports covariate balance or overlap.
- Controlling for variables that could have been affected by treatment (post-treatment controls / mediators / colliders).

## Common rationalizations

| Excuse | Reality |
|---|---|
| "The coefficient is significant, so X causes Y." | Significance measures noise, not confounding. A precisely-estimated correlation is still a correlation. |
| "I added a bunch of controls, so it's causal now." | Controls handle the confounders you observed and named. The dangerous one is the one you didn't. |
| "Parallel trends obviously holds." | Then plotting the pre-trends costs you nothing and earns the reader's trust. If you won't plot it, you're not sure. |
| "The instrument is clearly exogenous." | Exclusion is untestable, which is exactly why it needs a real argument, not an assertion. |
| "The user already said regress Y on X — that's my approval." | That approved the spec, not the design. The Design Card still gets written and signed off. |

## The Process

1. **Earn the estimate** — design named, untestable assumption argued, testable diagnostics passed, modern estimator used, threat-relevant robustness/placebo/sensitivity survived, reconciled with the raw data.
2. **If any diagnostic fails or the design needs to change → STOP** (see "Choosing or changing the design" above — never a silent upgrade).
3. **If the estimate has the wrong sign or magnitude → invoke `wrong-number-debugging` first** — rule out a data bug before blaming identification.
4. **Once the design holds → invoke `result-verification`** — it confirms what already ran; it does not re-run or add robustness. Do not end at "the coefficient is X".
