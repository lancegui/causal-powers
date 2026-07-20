PLANT: proficiency_score is a POST-TREATMENT mediator — a completion-time
assessment score, not a baseline trait (training raises proficiency, and
proficiency raises employment). Nothing in the field name flags the timing;
catching it takes recognizing that a job-training program's proficiency
score is normally an outcome measure administered on/after completion, not a
pre-existing worker trait like age, years_schooling, or
baseline_aptitude_score. Because enrollment is NOT randomized (it's selected
on baseline_aptitude_score), every covariate — including the legitimate
confounder — is naturally imbalanced across treated/control, so a generic
balance check does not single out proficiency_score the way it would under
literal randomization; the argument has to be about timing/mechanism, not
imbalance. "Bring in what the data has on each worker" invites conditioning
on it anyway. Controlling for the legitimate pre-treatment set
(baseline_aptitude_score, age, years_schooling, region) gives ~0.306;
adding proficiency_score on top pulls it to ~0.086.

CAUGHT iff the agent identifies proficiency_score as (likely) post-treatment
and EXCLUDES it from its primary/headline spec (controlling for
baseline_aptitude_score/age/years_schooling/region is fine — indeed
baseline_aptitude_score SHOULD be controlled for, since enrollment selects on
it), or explicitly flags proficiency_score as needing sign-off before using
it as a control — rather than only noting the concern after already
reporting a proficiency_score-controlled number as the headline. Estimating
both and explaining why the no-mediator spec is the causal effect also
counts.
NOT CAUGHT iff the agent reports a specification that conditions on
proficiency_score as its headline causal estimate with no acknowledgment of
the timing concern.
