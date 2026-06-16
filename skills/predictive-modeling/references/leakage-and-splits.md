# Leakage taxonomy and the split that defeats each

A predictive model's validation score is trustworthy only if it was earned the way
the model will be deployed. **Leakage** is the signature failure of this arm:
information about the answer reaches the model during training that *will not be
there at prediction time*, so the harness reports a number the deployment cannot
reproduce — 0.99 AUC in validation, coin-flip in production. This file is the
mechanics side of `SKILL.md`: the four leakage classes, the split that defeats
each, and a language-agnostic honest-evaluation harness skeleton with the
permutation-null recipe spelled out.

## Contents
1. The four leakage classes and their defeats
2. The honest-evaluation harness skeleton — ordered steps
3. The permutation-null recipe
4. Nested CV — and why the inner loop must respect time/group structure
5. Per-language one-liners (concept, not copy-paste)

---

## 1. The four leakage classes and their defeats

Each class is a different *way* the answer sneaks into training, and each has a
different split or pipeline discipline that shuts it out. They are not mutually
exclusive — a real pipeline usually has to defeat several at once.

| Leakage class | What it is | The tell | The defeat |
|---|---|---|---|
| **Target leakage** | A feature encodes the outcome or is recorded *after* it | one feature alone predicts near-perfectly; a feature that "shouldn't be that good" | **as-of feature cutoff** — only features knowable strictly before prediction time |
| **Temporal leakage** | Training on the future to predict the past | great CV, bad live performance; performance degrades the further out you predict | **time-based split / forward-chaining (rolling-origin) CV** |
| **Group leakage** | The same entity in both train and test | great CV, fails on genuinely new entities | **grouped split on the entity key (GroupKFold)** |
| **Preprocessing leakage** | A transform fit on all the data before splitting | a small but stubborn, hard-to-localize inflation | **fit every transform INSIDE the training fold only** |

### Target leakage

A feature that *is* the outcome wearing a different hat, or that only comes into
existence once the outcome is known. The canonical example: `case_closed_date` as a
feature for predicting `is_fraud`. The case only gets a closed-date *because* it was
adjudicated — the feature is a near-perfect predictor of the label and is **not
available at the moment you actually need to predict** (when the case is still
open). Subtler instances: an account's `lifetime_value` predicting `will_churn`
(value accrues *after* the churn decision); a `times_contacted_by_collections`
field predicting `will_default`; an updated-in-place status column that reflects the
current (post-outcome) state rather than the as-of state.

**Defeat — the as-of feature cutoff.** Pin the **prediction time** (row 3 of the
Prediction Spec) and admit a feature only if its value is **knowable strictly
before** that moment. For every feature, ask: *would this value exist, unchanged,
at prediction time?* If it is created, updated, or back-filled after the outcome,
it is out — or it must be reconstructed from a point-in-time snapshot of what was
known then. This is the single most important firewall in the discipline, because
target leakage is the class that produces the spectacular, too-good-to-be-true
scores.

### Temporal leakage

Training on rows from *after* the rows you score — letting the model peek at the
future. It happens whenever a random split shuffles a time-ordered dataset, so that
January's test rows are predicted by a model that trained on March, or whenever a
feature is computed over a window that extends past the prediction time (a rolling
mean that includes future periods, a target-encoded category whose encoding used
future labels).

**Defeat — time-based split / forward-chaining.** Order by time and **train on the
past, test on the future**, with a gap if features have a settling lag. For
cross-validation, use **forward-chaining (rolling-origin)**: fold 1 trains on
months 1–3 and tests on 4; fold 2 trains on 1–4, tests on 5; and so on. The
training window never contains a timestamp later than the test window. This mirrors
the only thing deployment can ever do — predict forward from what's already
happened.

### Group leakage

The same entity — pharmacy, patient, customer, device — appears in both the
training and the test set, so the model **memorizes the entity** rather than
learning a generalizable signal, and then fails on the genuinely new entities you
deploy on. If you have ten claims per pharmacy and split rows randomly, almost
every pharmacy lands on both sides; the model learns "this pharmacy" and scores
beautifully on held-out claims *from pharmacies it has already seen*.

**Defeat — grouped split on the entity key.** Split on the **group key** so all of
an entity's rows fall entirely on one side of the split (`GroupKFold` / group-
v-fold). Now the test set contains only entities the model has never seen, which is
exactly the deployment condition when you act on new units. If you both predict
forward *and* act on new entities, you need **time *and* group** respected together
(a grouped, time-ordered split).

### Preprocessing leakage

Fitting any data-dependent transform — a scaler's mean/SD, an imputer's fill value,
a feature selector's chosen columns, a **target encoder's category→label mapping**,
a PCA basis, a resampler — on the **full dataset before splitting**, so the
transform has already "seen" the test rows (and, for target encoders, the test
labels). The inflation is usually small but stubborn and maddening to localize,
because the model and features look innocent; the leak is in the plumbing.

**Defeat — fit transforms inside the training fold only.** Wrap every learned
transform and the model in a **pipeline that is fit per fold**: the scaler learns
its mean from the training rows only and merely *applies* it to the test rows; the
imputer's fill value comes from training only; the target encoder's mapping is fit
on training labels only. The test fold must be touched only by `transform`, never
by `fit`. This is what a `Pipeline` (sklearn) / `recipe` (tidymodels) / `MLJ`
machine buys you — it makes "fit only on train" structural rather than a thing you
have to remember.

---

## 2. The honest-evaluation harness skeleton — ordered steps

Language-agnostic; the order is load-bearing. This is the analog of structural
estimation's Monte-Carlo-recovery harness: run it, assert its properties, then
**freeze it as a regression baseline** so a later refactor can't silently
reintroduce leakage.

1. **Define the as-of cutoff.** Fix the prediction time and reconstruct every
   feature as it was knowable *before* that moment (defeats target leakage). This is
   a data step, done once, before any modeling — if a feature can't be pinned to a
   point-in-time value, it doesn't enter.

2. **Split mirroring deployment.** Choose the split by *how the model will be
   used*: **temporal** if you predict the future, **grouped** if you act on new
   entities, **both** if both, random *only* if you genuinely sample i.i.d. from the
   deployment population. This is the heart of the harness; a thoughtless random
   split is the most common cause of a number that doesn't survive deployment.

3. **Fit transforms + model inside the fold.** Everything learned from data — the
   scaler, imputer, selector, encoder, *and* the model — is fit on the **training
   portion of the current fold only** (defeats preprocessing leakage). Use a
   pipeline so this is structural.

4. **Score out-of-fold.** Produce predictions for each fold's held-out rows from a
   model that never saw them, and compute the metric (chosen in spec row 6) on
   those out-of-fold predictions. The out-of-fold scores, pooled, are your honest
   performance estimate.

5. **Permutation-null check.** Shuffle `y`, refit the *entire* pipeline, re-score.
   Performance **must collapse to no better than the trivial baseline** — and on
   imbalanced data the trivial baseline is **the base rate / majority-class rate,
   NOT accuracy**, because a shuffled-label model can still post high accuracy by
   always predicting the majority class. "Chance" is not the accuracy floor on
   imbalanced data. If a randomized-label model still beats the *base-rate* baseline
   on a class-aware metric (AUC ≈ 0.5, precision-at-k ≈ base rate, average precision
   ≈ prevalence), information is leaking through the plumbing. Recipe in §3 below.

6. **Calibration check.** If the probability feeds a decision (an expected-cost
   calculation, a risk threshold), a well-*ranked* model can still be badly
   *calibrated* — its "0.8" isn't 80%. Plot the reliability curve on out-of-fold
   predictions; recalibrate (Platt / isotonic, fit on a held-out calibration slice,
   never on the test fold) if probabilities are load-bearing. If you only need the
   *ranking* (regime 4), calibration is optional — say which you need.

7. **Compare to the trivial baseline.** Score the baseline named in spec row 6 —
   predict the base rate, predict last period, keep the current rule-of-thumb —
   under the *same* harness, and report the model's lift over it. A model that
   doesn't beat the trivial baseline is not earning its complexity, opacity, or
   maintenance cost; report that honestly rather than burying it.

Steps 1–4 produce the headline number; steps 5–7 are what license you to *believe*
it. None is optional, and all of them precede reporting.

---

## 3. The permutation-null recipe

The highest-value single check in the discipline — run it first. It detects leakage
*anywhere* in the harness (features, joins, splits, transforms) without needing to
know where, because it removes the only legitimate source of signal — the
relationship between features and label — and asks whether the pipeline still
performs. If it does, the performance was coming from the plumbing.

**Recipe.**
1. **Shuffle the labels** `y` (permute the target across rows), leaving the feature
   matrix `X` and the *split structure* exactly as they are. Shuffle **within the
   split structure you'll evaluate under** — e.g. permute within time blocks /
   within groups if the real split is grouped — so the null respects the same
   dependence the real evaluation does.
2. **Refit the entire pipeline** on the shuffled labels — every learned transform
   and the model — through the *same* harness (steps 2–4 above). Do not shortcut by
   reusing a fitted transform; the whole point is to exercise the full plumbing.
3. **Score out-of-fold** and record the metric. Repeat for several permutations
   (e.g. 20–100) to get a *null distribution* of the metric, not a single draw.
4. **Compare to the trivial baseline, not to "chance."** On a class-aware metric:
   AUC should sit at ~0.5; average precision / precision-at-k should sit at ~the
   **prevalence (base rate)**; a cost-weighted top-k should match a random queue.
   On accuracy with imbalance the null can look "high" — that's the majority-class
   trap, which is exactly why accuracy is the wrong metric to read the null on.
5. **Read it.** The real model's score must lie *well outside* the permutation null
   (an empirical p-value: the fraction of permuted runs that beat the real score).
   If the null distribution overlaps the real score, **the harness is leaking** —
   stop and bisect (route to `wrong-number-debugging`, suspecting leakage first)
   before trusting any number.

The imbalanced-data caveat is the crux: **"chance" ≠ "accuracy floor."** Always
read the permutation null on a metric that is prevalence-aware (AUC, average
precision, precision/recall-at-k), and state the base rate next to it.

---

## 4. Nested CV — and why the inner loop must respect time/group structure

When you select hyperparameters, that selection is *fitting to data* and needs its
own held-out fold, or the reported number is inflated by exactly the amount you
then can't reproduce. **Nested CV** gives the honest estimate: an **outer** loop
produces the performance estimate on data untouched by tuning; an **inner** loop,
*within each outer training fold*, selects hyperparameters.

The trap specific to this arm: **the inner tuning loop must respect the same
time/group structure as the outer loop.** It is not enough for the outer split to
be temporal or grouped — if the inner loop tunes with a vanilla random K-fold,
leakage sneaks back in through the tuning decision:
- For **temporal** data, the inner loop must be a **forward-chaining / time-series
  split**, so hyperparameters are never chosen using future-to-past folds.
- For **grouped** data, the inner loop must be a **grouped split on the same entity
  key**, so a hyperparameter isn't chosen because it memorized an entity that also
  appears in the inner validation fold.
- For **both**, the inner loop respects both.

A correct outer split with a careless inner split is a real and common way a
nominally "nested" CV still reports a number that won't survive deployment. The
inner loop is part of the harness, and the same split discipline that governs the
outer loop governs it.

---

## 5. Per-language one-liners (concept, not copy-paste)

The point is *concepts over copy-paste* — a pipeline that fits per-fold, a split
that mirrors deployment, a permutation null read against the base rate. The library
names below are pointers, not recipes; the discipline is identical across all
three.

**Python (scikit-learn).** Wrap transforms + model in a `Pipeline` so every
transform is fit per fold; cross-validate with `GroupKFold` (group leakage) or
`TimeSeriesSplit` (temporal leakage); nest with `*SearchCV` *inside* a `cross_val_*`
call, passing the structure-aware splitter to the inner `cv=` too; run the
permutation null with `permutation_test_score` (read it on a prevalence-aware
`scoring=`, not accuracy) or by shuffling `y` and re-running the pipeline yourself
when you need the grouped/temporal-aware shuffle.

```python
# concept: per-fold pipeline + deployment-matched splitter + structure-aware nesting
pipe = Pipeline([("scale", StandardScaler()), ("clf", model)])   # fit per fold (step 3)
outer = GroupKFold(n_splits=5)            # or TimeSeriesSplit — mirror deployment (step 2)
inner = GroupKFold(n_splits=4)            # SAME structure in the tuning loop (§4)
search = GridSearchCV(pipe, grid, cv=inner, scoring="average_precision")  # prevalence-aware
honest = cross_val_score(search, X, y, groups=g, cv=outer, scoring="average_precision")
# permutation null (step 5 / §3): shuffle y within groups, refit, compare AP to prevalence
```

**R (tidymodels).** Build a `recipe` so preprocessing is estimated on the analysis
(training) split only; use `rsample::group_vfold_cv()` (group leakage) or
`rsample::sliding_period()` / `sliding_index()` (temporal / rolling-origin); tune
with `tune_grid()` over inner resamples that share the same grouping/time
structure; there's no single built-in permutation test — shuffle the outcome and
re-`fit_resamples()` to build the null yourself.

**Julia (MLJ).** Wrap transforms + model in a pipeline (`|>` / `@pipeline`) so
fitting is per-fold; pass a resampling strategy that mirrors deployment to
`evaluate!` (custom grouped / time-ordered folds); tune with `TunedModel` whose
inner `resampling` carries the same structure; build the permutation null by
permuting `y` and re-`evaluate!`-ing.

In all three: the structure is *fit-only-on-train, split-like-deployment, tune-with-
the-same-structure, read-the-null-against-the-base-rate.* The library is
interchangeable; the discipline is not.
