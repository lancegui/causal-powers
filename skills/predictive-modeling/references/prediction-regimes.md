# Prediction-regime cards — what "the label" lets you validate

**Worked examples of one question applied four ways, not a menu.** The label you
can actually call "the label" decides what validation *means* — so for whatever
prediction problem your project has, you fill in the same four rows from the
matching card. Each card below answers them for one of the four regimes named in
row 2 of the Prediction Spec:

1. **What is the label / target?** — what exactly each row's `y` is, and what it is *not*.
2. **How does the SPLIT change?** — what the deployment-mirroring split must respect here.
3. **What METRIC fits?** — the metric that follows from the decision and the label's limits.
4. **How do you VALIDATE?** — the honesty check that proves the score means something.

The four regimes are not algorithm choices — a gradient-boosted tree can serve all
four. They are *epistemic* choices about what you know to be true of past units.
The split mechanics and the leakage taxonomy each card leans on live in
`references/leakage-and-splits.md`.

---

## 1. Clean label — a trustworthy target exists

**The label.** You observe the *true* outcome for past units: the claim **was**
adjudicated fraudulent, the patient **was** readmitted within 30 days, the customer
**did** cancel. The label is the thing you care about, not a stand-in for it. This
is the textbook supervised setup, and the discipline here is *not* the label — it
is the split and the leakage audit, because a clean label lulls you into trusting
the harness.

**The split.** Standard, but "standard" means *matched to deployment*, never
reflexively random. If you predict the future (readmission next month), split by
**time**; if you act on new entities (a pharmacy you've never scored), split by
**group/entity key**; both if both. A random 80/20 is correct **only** when you
genuinely sample i.i.d. from the same population you'll deploy on — which is rarer
than people assume. The clean label does not buy you a random split.

**The metric.** Tie it to the decision (row 1), and **emphasize the operating
threshold**: a clean probability is useless until you pick the point on the
ROC/PR curve where you act. The threshold is set by the **cost asymmetry**, not by
maximizing accuracy — if a missed fraud costs 50× a wasted audit, the threshold
sits low and you accept false positives to catch true ones. Report the metric *at
the chosen operating point* (precision and recall at that threshold), not just a
threshold-free summary (AUC) that hides where you'll actually operate. Calibration
matters whenever the probability feeds an expected-cost calculation rather than a
bare ranking.

**Validation.** The full honest-eval harness applies cleanly: permutation/null
probe (shuffled labels must collapse to the trivial baseline), deployment-mirroring
holdout, nested CV if you tune, calibration check if probabilities are
load-bearing, and beat-the-trivial-baseline. With a clean label every one of these
is computable directly — there is an answer key — so there is no excuse to skip
them. The one trap specific to this regime: a clean label tempts a near-perfect
score to read as a triumph rather than a **leakage alarm**. A clean label makes
leakage *more* dangerous, not less, because the number looks so trustworthy.

---

## 2. Proxy / weak label — the label is a noisy stand-in

**The label.** You do **not** observe the thing you care about; you observe a
correlate of it. "Was investigated and found" is not "was guilty" — it is "was
suspected enough to investigate, *and* the investigation concluded against the
unit." A thresholded volume ("dispensed > X pills") is not "was diverting" — it is
"crossed an arbitrary cutoff." A complaint filed is not "harm occurred." **You are
predicting the proxy, and the spec must say so in row 2.** Every metric you report
is a metric *on the proxy*; calling it a metric on the true outcome is the
mislabeled-model failure.

**Selection into the label.** The proxy almost always carries **selection**: you
only have labels for units that *entered the labeling process*. You see audit
outcomes only for pharmacies someone already suspected; you see "found fraudulent"
only among "got investigated." The labeled subpopulation is therefore **not** a
random sample of the population you'll deploy on — it is the tail someone already
filtered toward. This is the same structure as a sample-selection / missing-not-at-
random problem, and it does not go away because you call the model "predictive."

**The split.** Same deployment-mirroring rules as the clean label (temporal /
grouped / both) — **plus** a sharp awareness of *which population the labels come
from*. If your training labels are all from already-suspected units but you'll
deploy on the full population, your split can mirror deployment in *time* and still
mislead in *coverage*, because the label-bearing units differ systematically from
the units you'll score. Where possible, hold out a slice that resembles the
deployment population, not just the labeled one.

**The metric.** The metric is computed on the proxy and is **valid only within the
labeled / inspected subpopulation.** Precision-at-k among already-audited units
does not transfer to un-audited units without an assumption. Report the metric with
its scope stated: "precision 0.7 *among investigated pharmacies*," not "precision
0.7." If the decision needs a population-level rate (how many true positives are we
missing out there?), the proxy metric alone cannot give it.

**Validation.** Run the full harness *on the proxy* — but the honest-eval section
acquires an extra, regime-specific burden: **extrapolation beyond the labeled
subpopulation needs either an explicit assumption or a selection-corrected
estimator.** Two honest routes:
- *Assume representativeness* — state plainly that labeled units stand in for
  unlabeled ones on the features that matter, and acknowledge it is an assumption
  you cannot test from the labeled data alone. This is load-bearing and untestable,
  exactly the kind of choice that routes through `analysis-checkpoints`.
- *Correct the selection* — model the probability of *being labeled* (a propensity
  for entering the audit process) and reweight, or use a Heckman-type selection
  correction, so that metrics estimated on the labeled tail can be projected to the
  population. This needs a variable that shifts *selection into the label* without
  shifting the outcome itself — the same exclusion-restriction logic as elsewhere
  in the family. If you have no such shifter, you cannot extrapolate; say so.

The trap: reporting a proxy metric as if it were a truth metric, with the selection
silent. A proxy treated as truth is not a conservative simplification — it is a
different claim than the one the user thinks they're getting.

---

## 3. Unsupervised / anomaly — no label at all

**The label.** There isn't one. You flag units that *look unusual* against the bulk
of the data — an isolation forest's outlier score, a reconstruction error, a
density estimate. The critical reframe, stated in the spec before any code:
**anomalous ≠ rogue.** An outlier is a unit that is statistically unusual; that is
not the same as a unit that is doing something wrong. A brand-new high-volume
specialty pharmacy is genuinely anomalous *and* entirely legitimate. The model has
no notion of "right answer" because there is no `y` to be right against.

**The split.** There is no label to leak through `y`, so target leakage in the
usual sense doesn't apply — but **every other split discipline still does**, and
two bite especially hard:
- **Preprocessing leakage** is acute here, because the whole method *is*
  preprocessing — the scaler, the PCA, the density estimate, the contamination
  parameter must be fit on a *reference window* and applied forward, never fit on
  the same data you then score, or "unusual" is defined circularly by the test
  units themselves.
- **Temporal structure** still matters: fit the notion of "normal" on a past
  window and flag the present against it, so the model can't define normality using
  the very period you're trying to surveil.

**The metric.** You **cannot compute precision or recall** — there is no answer
key, so any number that pretends to is fabricated. Frame the output as **triage,
not classification**: a ranked queue of the top-k most-unusual units for a human to
adjudicate, sized to investigator capacity (this shades into regime 4 once capacity
is the binding constraint). The honest "metric" is operational: *of the top-k
flags a human reviews, how many were worth reviewing?* — a hit rate measured by
adjudication, reported with its sample size and its reviewers named.

**Validation — the hard part of this regime.** With no ground truth, you validate
the only ways available, and the spec must commit to them *before* running:
- **Injected known positives.** Plant a handful of units you *know* should be
  flagged (synthetic cases built to the pattern you're hunting, or historically
  confirmed cases if any exist) and confirm the detector surfaces them in the
  top-k. This is the closest thing to a recovery test — the analog of structural
  estimation's Monte-Carlo recovery: prove the method catches what it's supposed to
  before trusting it on the unknown.
- **Expert adjudication of the top-k.** Hand the highest-scoring flags to a domain
  expert and record the hit rate. This is your only real precision estimate, and it
  is precision *at k among reviewed flags*, scope stated.
- **Stability over time and over parameters.** The same units should keep
  surfacing across reasonable contamination settings, random seeds, and adjacent
  time windows. A flag that appears only at one knob setting is an artifact of the
  knob, not a signal.
- **Explicit acknowledgment of what you cannot compute.** State in the writeup that
  precision/recall against truth are unavailable and why. Hiding the absence of an
  answer key behind an official-looking AUC is the signature dishonesty of this
  regime.

Because the output points a human at a real entity, the consequential-decision
discipline applies in full: check base rates (at a 0.5% true rate even an excellent
detector floods the queue with false positives), and hold the line that a human
acts on a **score, not a verdict**.

---

## 4. Ranking / triage — a prioritized list for limited capacity

**The label.** You may have a clean label, a proxy, or only anomaly scores — but
the *output* is not a per-unit verdict. It is an **ordering**: a prioritized queue
for a fixed amount of investigator capacity. You can audit 50 claims a week, review
20 accounts a day, send 200 letters a quarter. The model's job is to fill that
queue with the units most worth acting on — not to classify the entire world into
positive and negative.

**The split.** Same deployment-mirroring rules (temporal / grouped / both) as the
label regime underneath it — but evaluate the split the way the *queue* is
consumed. If you re-rank weekly and act on the top 50, your holdout should be
**forward-chained** (train on the past, rank the next week, score the queue you'd
actually have pulled), not a shuffled pool, because the queue is built from
information available as-of each ranking moment.

**The metric — the operating point IS the capacity.** The metric is **top-k /
precision-at-capacity / cost-weighted**, where *k is your real capacity*, not an
abstract threshold:
- **Precision-at-k** — of the top *k* the model surfaces, what fraction are true
  positives? This is the number that maps directly onto "of the 50 we audited, how
  many paid off."
- **Recall-at-k** — of all the true positives out there, what fraction landed in
  the top *k*? — when the cost of a miss matters and you want to know how much you
  leave on the table at your capacity.
- **Cost-weighted ranking** (e.g. expected-value-at-k, or a cumulative-gain /
  lift curve) when units differ in payoff — a queue that surfaces ten small hits
  may be worth less than one that surfaces three large ones. Rank by *expected
  value of acting*, not by probability, when the stakes per unit vary.

A threshold-free summary like AUC is the wrong headline here: it averages over
operating points you will never use. Report the metric **at your capacity k**, and
if capacity is uncertain, report the curve across the plausible range of k so the
user can see the trade-off they're choosing.

**Validation.** Run the honest-eval harness with the metric set to precision/recall
*at your capacity*, on a forward-chained holdout. The permutation/null probe still
applies — shuffle the labels, rebuild the queue, and confirm precision-at-k
collapses to the **base rate** (the precision a random queue of size k would get),
which on imbalanced data is far below accuracy and is the correct floor. Beat the
trivial baseline that here means *the queue you'd build without the model* — the
current rule-of-thumb ranking, or a random draw of k. A ranking model earns its
keep only if its top-k beats the queue the user already knows how to build.

---

## Which regime am I in? — a decision aid

Answer in order; the first "yes" names your regime.

1. **Do I have, for past units, the *true* outcome I actually care about — not a
   correlate of it?**
   → If yes, and it's trustworthy: **Clean label (1)**. Discipline = split +
   leakage audit + operating threshold tied to the decision.

2. **Do I have a *label*, but it's a stand-in — "investigated/found," a thresholded
   volume, a complaint — that only correlates with the thing, and that I only
   observe for units that entered some selection process?**
   → **Proxy / weak label (2)**. Say you're predicting the proxy; carry the
   selection; metrics valid only within the labeled subpopulation; extrapolation
   needs an assumption or a selection correction.

3. **Do I have *no* outcome at all, and I'm flagging units that look unusual?**
   → **Unsupervised / anomaly (3)**. anomalous ≠ rogue; no precision/recall against
   truth; validate by injected positives + expert top-k review + stability; frame
   as triage, not classification.

4. **Regardless of which of the above, is the *deliverable* a prioritized queue for
   a fixed capacity rather than a per-unit verdict?**
   → **Ranking / triage (4)** — layered on top of whichever label regime you're in.
   Metric = precision/recall/cost-weighted **at your capacity k**; the operating
   point *is* the capacity.

Most real problems are a **pair**: a proxy label consumed as a triage queue
(2 + 4), or an anomaly detector feeding a capacity-limited review (3 + 4). Name
both the label regime and whether the output is a queue — they answer different
questions (what can I validate? vs. what's the metric?) and you need both rows of
the spec right.
