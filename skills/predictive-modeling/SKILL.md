---
name: predictive-modeling
description: >-
  Use whenever the GOAL is a prediction that drives an action — predict, score, rank, flag, classify, forecast, or detect anomalies on units ("which pharmacy is likely diverting opioids", "which claim to audit", "who's likely to churn", "rank by risk"). Route by GOAL, not algorithm: a prediction deliverable is this skill even when a random forest does the work; a causal effect stays in causal-identification even when ML does the heavy lifting (double/debiased ML, causal forests, ML propensity scores). Covers clean-label, proxy/weak-label, unsupervised/anomaly (no label), and ranking/triage regimes in R, Julia, or Python. A high validation score is not a working model until leakage is ruled out and the split mirrors deployment. NOT for one-off data-QA outlier checks while cleaning a dataset — that's data-contracts; uplift/CATE-for-targeting runs BOTH this skill's evaluation gates and causal-identification's design.
---

# Predictive Modeling

## Overview

Causal identification asks *what an intervention did*; structural estimation asks *what a world we haven't seen would do*. Prediction asks something narrower: *given what I can observe about a unit now, what is likely true of it — so I can act on it.* Score the claim, rank the account, flag the pharmacy. The deliverable is a number on a unit that drives a decision; the model is a means, not the point.

The **signature failure of this discipline is leakage.** A feature that encodes the answer — a timestamp that exists only after the outcome, a row that appears in both train and test — makes the model look *brilliant* in validation and *fail on the units you actually act on*. The harness says 0.99 AUC; deployment says coin flip, and nothing in the loss curve tells you so.

There is a **twin failure**: reading the model as causal. The boosting machine ranks "prior audit flag" as the top feature, and the analyst writes "prior flags drive diversion." It does no such thing — the feature *correlates* with the label; the model uses it to predict, not because it causes anything. A predictive model is a correlation engine pointed at an action, and treating its internals as mechanism is how a triage tool becomes a false causal story.

**Core principle:** *a prediction is trustworthy only if it was evaluated the way it will be deployed.* Everything below serves that one sentence — the split, the leakage probe, the calibration, the baseline — and a model that scores well under any other evaluation has told you nothing about the units you will act on.

## Why are you modeling? — choose the arm before you fit

This is the fork. One question decides which of three families you're in, and they lead to three different workflows:

| What you actually need | The deliverable | Workflow |
|---|---|---|
| An effect that **occurred** — "did the policy work?", "what did the price cut do?" | A causal estimate inside the data | **`causal-identification`** |
| A world you **haven't observed** / a welfare number — "what price would the merged firm set?" | A counterfactual outside the data | **`structural-estimation`** |
| To **predict / score / rank / flag** units to drive an action | A number on a unit | **here** |

**Route by goal, not algorithm.** The method doesn't decide the arm; the deliverable does. A random forest that ranks pharmacies by diversion risk is *this* skill even though it's "ML." The converse, where the line gets crossed most often: **double/debiased ML, causal forests, and ML-estimated propensity scores are NOT this skill — they are `causal-identification`.** When ML does the heavy lifting *in service of a causal estimand*, the goal is still an effect — the concern there is **honest cross-fitting** (nuisance models fit on data disjoint from where their predictions enter the moment condition), hand it back. If your "prediction" has a treatment variable whose coefficient is the point, you're in the wrong arm. **Uplift/CATE-for-targeting is BOTH arms:** the score *is* a causal effect (`causal-identification`'s Design Card) AND a deployed ranking (this skill's deployment-matched evaluation) — run both gates.

**First question:** *what decision does the prediction drive, and what does a false positive vs. a false negative cost?* If you can't name the action and the asymmetry, you don't have a prediction problem yet — you have a curiosity, and a curiosity has no metric.

## Write the Prediction Spec — immediately, and keep it living

A predictive model's modeling choices — the label, the split, the metric, the threshold — silently decide what *every* downstream number means. So **the moment you understand the problem, write it down as a Prediction Spec** and get the user's sign-off before fitting anything, before a leaked feature has quietly defined success. (Write-to-file, sign-off, mid-pipeline-reconstruct: `analysis-checkpoints`'s locked-document gate; reconstructing here means especially rows 3 and 5, where the silent failure lives.)

The spec has **seven rows**:

1. **Decision + who acts + cost asymmetry.** What action does the score trigger, and what does a false positive cost relative to a false negative? This sets the metric *and* the threshold.
2. **Target / label + regime.** What exactly are you predicting, and which of the four regimes (next section) are you in? A vague label is a vague model.
3. **Unit + prediction time — the "as-of" firewall.** What is one row, and *at what moment* is the prediction made? Every feature must be knowable strictly **before** that moment — leakage is, almost always, a feature that didn't exist yet as-of prediction time.
4. **Features + leakage audit.** For each feature, affirm it's available as-of the prediction time and isn't a proxy for the label — a row in the spec, not an afterthought.
5. **Split design matched to deployment** — temporal if you predict the future, grouped if you act on new entities (new pharmacy, new patient), both if both; random *only* if neither holds. **This is the heart of the spec — the analog of per-parameter identification in the structural card.** A blank or a thoughtless "random 80/20" here is the single most common cause of a number that doesn't survive deployment.
6. **Metric tied to the decision + baseline to beat.** The metric follows from row 1 (precision-at-capacity when capacity is fixed; calibration when probabilities feed a cost calculation; recall when misses are catastrophic) — and name the **trivial baseline** the model has to beat, or it isn't earning its complexity.
7. **Method + why** — simplest-that-works first. A regularized logistic / a single tree is the baseline model, not the fallback; reach for boosting or deep nets only once the simple model is beaten *honestly*.

**The spec is living**, but a **load-bearing change** (label, split, metric, threshold) still routes through `analysis-checkpoints`, never a silent edit — changing the threshold after seeing the ROC decides how many false positives the user will tolerate, theirs to make.

## The label decides the regime

What you can call "the label" determines what validation even *means*. There are four regimes; name yours in row 2 of the spec. Full detail for each — the split, the metric, the honesty check — is in **`references/prediction-regimes.md`**; the essence of each:

- **Clean label.** You observe the true outcome for past units (the claim *was* fraudulent; the customer *did* churn). The discipline is the split and the leakage audit, not the label itself.
- **Proxy / weak label.** You observe a stand-in, not the thing — "was audited and found," not "was fraudulent." Say so in the spec: the proxy carries its own selection (you only see audits of units someone already suspected), so metrics computed on it are valid only *within the labeled subpopulation* — extrapolating past that needs a stated assumption or a selection-corrected estimator.
- **No label / anomaly.** No outcome at all — you flag units that look unusual. Answer before any code: *how will you EVER validate this?* Unusual is not actionable, and an unsupervised model has no score to be right or wrong against.
- **Ranking / triage.** No calibrated probability needed — just the *top k* worth acting on, because capacity is fixed. The metric is precision-at-k / precision-at-capacity; the model's job is to fill the queue, not classify the world.

## Prove the evaluation is honest — before you trust any metric

This is the proof step — the analog of structural estimation's Monte-Carlo recovery: there you prove the *algorithm recovers truth*; here you prove the *evaluation is honest*, before believing any score. It's `data-contracts` discipline applied to the **eval harness** — assert these, then **freeze the harness as a regression baseline** (commit the probe script, pin the permutation/baseline result) so a later refactor can't silently reintroduce leakage. None of this is optional, and all of it precedes reporting a number.

- **Permutation / null probe — run this first.** Shuffle the labels **within the split structure you'll evaluate under** and refit the whole pipeline (recipe + the imbalanced-data trap: `references/leakage-and-splits.md` §3; no-label/anomaly analog — injected known positives: `references/prediction-regimes.md` card 3). Performance **must collapse to no better than the trivial baseline (base rate / majority-class)**, not "chance" — a shuffled-label model can still post high accuracy on imbalanced data by predicting the majority class. If it still beats the baseline, the harness is leaking.
- **"Too-good-to-be-true = leakage."** A near-perfect score (0.99 AUC on a hard problem) is a leakage alarm, not a triumph — flag any single feature that alone predicts near-perfectly and investigate before you celebrate.
- **Deployment-mirroring holdout.** Evaluate on the split row 5 specifies (temporal / grouped / both). **Never tune on the test set** — use **nested CV**, and for temporal/grouped data the *inner* tuning fold must respect the same structure as the outer one (`references/leakage-and-splits.md` §4), or leakage sneaks back through the tuning loop. Tuning on test inflates the number by exactly the amount you then can't reproduce.
- **Calibration.** If the probability feeds a decision, a well-*ranked* model can still be badly *calibrated* (its 0.8 isn't 80%) — check the reliability curve, recalibrate (Platt / isotonic) if load-bearing. Optional if you only need the ranking; say which you need.
- **Beat the trivial baseline.** Compare against row 6's baseline. A model that doesn't beat "predict the base rate" or "keep the current rule" isn't earning its complexity or opacity — report that, don't bury it.

Recipes, split mechanics, and the leakage taxonomy: **`references/leakage-and-splits.md`**.

## Prediction is not causation

The headline guardrail of this arm. A predictive model tells you *which units* to act on; it does **not** tell you *why*, and the moment you read it as mechanism you've left the discipline.

- **Feature importance and SHAP describe what the MODEL USES, not what CAUSES the outcome.** "Prior-flag is the top feature" means the model leans on prior-flag to predict — not that prior flags cause diversion, and not that changing a unit's prior-flag would change its outcome. These are model-attribution tools, not effect estimates, and **no intervention claim** comes out of a predictive model. If someone wants to *act on the cause* rather than triage by the score, that is `causal-identification`, full stop — a "which lever to pull" ask is a causal question wearing a prediction task's clothes; don't answer it by reading off importances, and don't quantify an expected effect from them either.
- **Distribution-shift validity caveat.** A predictive model is valid **only on the population it was trained and validated on.** Score pharmacies in one state, deploy in another with different prescribing norms, and the correlations it learned may not hold. Name the population in the spec and don't extrapolate past it.
- **The anomaly special case — anomalous ≠ rogue.** An outlier *looks unusual*, which is not the same as *doing wrong*; a brand-new high-volume specialty pharmacy is anomalous and legitimate. Without ground truth you **cannot compute precision or recall.** Validate instead by **injecting known cases** and checking they surface, **expert review of the top-k**, and **stability** across reasonable parameter choices — frame the output as **triage, not classification**.
- **Consequential-decision note.** When the flag points at a real entity for enforcement, audit, or denial, check **base rates** (at a 0.5% true rate even a great model floods the queue with false positives) and **subgroup error** (accurate overall, systematically wrong for a subpopulation), and hold the line that **a human acts on a SCORE, not a verdict.**

## Choosing or changing the spec is the user's decision

Picking the label, split, metric, threshold, or method — and changing any of them once results are in view — is `analysis-checkpoints` territory. The danger window is *after* results: the model underperforms, so the impulse is to relabel "audited-and-found" as "fraudulent," loosen the temporal split to random, or slide the threshold until precision looks good — every one is a checkpoint, the prediction-arm twin of redesign-as-bug-fix.

## Tooling (R / Python / Julia)

Existing methods only — this arm *uses* the ML toolbox, it does not invent estimators.

| Task | R | Python | Julia |
|---|---|---|---|
| Framework / workflow | `tidymodels` (recipes + rsample + parsnip) | `scikit-learn` (`Pipeline`, `*SearchCV`) | `MLJ.jl` |
| Regularized linear / GLM | `glmnet` | `scikit-learn` (`LogisticRegression`, `ElasticNet`) | `MLJLinearModels.jl` |
| Random forest | `ranger` | `scikit-learn` (`RandomForest*`) | `MLJ.jl` (`DecisionTree`) |
| Gradient boosting | `xgboost` | `xgboost`, `lightgbm` | `XGBoost.jl`, `EvoTrees.jl` |
| Temporal / grouped CV | `rsample` (`sliding_*`, `group_vfold_cv`) | `TimeSeriesSplit`, `GroupKFold` | `MLJ.jl` resampling |
| Model attribution (**not causal**) | `DALEX`, `iml` | `shap`, `sklearn.inspection` | `ShapML.jl` |
| Calibration | `probably` | `CalibratedClassifierCV`, `sklearn.calibration` | `MLJ.jl` |
| Anomaly / unsupervised | `isotree`, `solitude` | `IsolationForest`, `LocalOutlierFactor` | `OutlierDetection.jl` |

The model-attribution row (SHAP / DALEX) carries the standing caveat above: it explains the **model**, never the world. Reach for the simplest row first; boosting and its opacity only once the simple model is honestly beaten.

## Red flags — STOP

- A **random split** where deployment is **temporal or grouped** — the most common silent killer.
- **Tuning on the test set** — hyperparameters selected on the data used for the honest estimate, no nested CV.
- A **near-perfect score** taken as a triumph instead of a leakage alarm.
- **No permutation/null probe** — trusted before randomized-label performance was shown to collapse to the trivial baseline, not merely "to chance."
- Feature importance / SHAP read as **causal** — "feature X drives the outcome," an intervention claim from a correlation engine.
- A **proxy label treated as truth** — "was audited and found" reported as "is fraudulent," selection unstated.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "99% AUC, so the model works." | A near-perfect score on a hard problem is a leakage alarm. Run the permutation probe and hunt the feature before you celebrate. |
| "A random split is the standard." | Only if deployment is random. Predicting the future → split by time; acting on new entities → split by group. |
| "The model trains on randomized labels too, but that's fine." | If shuffled labels still score, information is leaking through the harness — a broken eval, full stop. |
| "I just tuned on the test set to save a fold." | Your reported number is the one you can't reproduce. Tuning needs its own fold; use nested CV. |
| "Feature X is the top predictor, so X drives the outcome." | Importance is what the *model uses*, not what *causes* anything. Want the why? `causal-identification`. |
| "We don't have the real label, but the proxy is close enough." | Say you're predicting the proxy and carry its selection bias — a proxy reported as truth is a mislabeled model. |

## The Process

1. **Confirm you are in the prediction arm, then write and approve the spec.**
   - **(1a) Confirm the arm.** Is the goal a *prediction* (a number on a unit that drives an action), not an *effect* or a "why"? If it's really an effect, stop and route to `causal-identification` — settle this first; it is the fork, not a spec row.
   - **(1b) Write the Prediction Spec and get sign-off** — decision + cost asymmetry, label + regime, unit + prediction time, features + leakage audit, deployment-matched split, metric + baseline, method. Mandatory before any fitting.
2. **Spec approved → invoke `executing-analysis-plans`** — fan the CV folds, candidate models, and subsample cuts to parallel subagents rather than one slow serial loop.
3. **Prove the evaluation is honest before trusting any metric** — permutation/null probe, deployment-mirroring holdout (nested CV when tuning), calibration if load-bearing, beat-the-baseline. Freeze the harness as a regression baseline.
4. **If a metric looks suspicious → invoke `wrong-number-debugging`, suspecting leakage first** — bisect to the feature or join carrying the answer before blaming anything else.
5. **Estimation + honest eval complete → offer `result-verification`** before reporting (the user's call) — reproduce from a clean state, confirm the split mirrored deployment, confirm no internals are reported as causal.
6. **If the label, split, metric, threshold, or method needs changing after seeing results → STOP and invoke `analysis-checkpoints`.** The user's decision, never a silent re-cut to make a number look better.

## The bottom line

```
Prediction claim  →  honest eval (permutation probe + deployment-matched split + beat-the-baseline),
                     calibrated if probabilities drive the decision, internals NOT read as causal
Otherwise         →  a confident number that fails on the units you actually act on
```
