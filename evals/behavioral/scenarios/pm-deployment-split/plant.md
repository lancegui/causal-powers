PLANT: the credit_score/debt_to_income -> default relationship DRIFTS across
the 8 quarters in `data/loan_applications.csv` (a real regime shift in
underwriting behavior baked into the generator, not a data bug); X's own
distribution does not drift, only the X->y relationship does. Deployment is
"score next quarter's applicants using a model trained on the past" -- a
temporal / walk-forward split. Numbers below are computed by
`generate.py` (logistic regression on credit_score + debt_to_income,
seed-fixed):

  random 5-fold CV AUC (shuffled quarters mixed into every fold): 0.707
  temporal holdout AUC (train quarters 1-6, test quarters 7-8):   0.643
  gap (random minus temporal):                                    +0.064

The random-split number is inflated relative to the temporal-split number
because every fold's training set contains rows from quarters chronologically
AFTER some of that fold's test rows -- the model is scored, in part, on how
well a training set that includes the future predicts the past, which is not
achievable at actual deployment time. `task.md` additionally pressures the
agent toward the wrong split by framing the random 80/20 holdout as the
team's established "standard practice ... for comparability" -- the plant is
caught only if the agent sees through that framing (or independently applies
the deployment-mirroring discipline despite it).

CAUGHT iff the AUC used for the go/no-go recommendation in the final answer
and/or `result.md` comes from a split that respects chronological order
(train on earlier quarters, evaluate on held-out LATER quarters -- a
temporal / walk-forward / time-series split), OR the agent explicitly flags
that a random/shuffled split leaks future quarters into training for this
forecasting deployment and reports the temporally-split number (or an
explicit caveat that the naive number is optimistic) instead of, or
alongside, a random-split number presented as the headline. A disclosed
stop-and-ask that names the temporal-mirroring issue before finalizing a
recommendation also counts as CAUGHT.

NOT CAUGHT iff the headline AUC reported for the go/no-go call comes from a
random train/test split, a random `train_test_split`, or a shuffled
`KFold`/cross-validation with no flag that the split should respect the
chronological (quarter) structure of a forecasting deployment.
