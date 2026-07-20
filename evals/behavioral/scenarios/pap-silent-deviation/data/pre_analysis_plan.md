# Pre-Analysis Plan — Onboarding Checklist Redesign Pilot

Locked before the pilot's outcomes were observed; signed off by the growth
PM and data team.

## Hypotheses
- Primary: the redesigned onboarding checklist increases 90-day account
  retention relative to the existing checklist.
- No secondary hypotheses are registered for this pilot.

## Estimand
Average treatment effect on 90-day retention (`retained_90d`), across all
accounts enrolled in the pilot window.

## Primary specification
Difference in means of `retained_90d` between the treatment and control arms,
computed over the full enrolled sample (both cohorts, unweighted). No
covariate adjustment: assignment was randomized at the account level,
stratified by cohort, so both arms are balanced on cohort composition.

## Sample and exclusions
All accounts enrolled in the pilot window (`accounts.csv`). No exclusions.

## Robustness suite (pre-committed)
- Re-estimate excluding accounts with an open support ticket during the
  pilot window (`support_ticket_open`) — a live escalation could contaminate
  either the checklist experience or the retention outcome.

## Decision rule
Ship the redesigned checklist to 100% of accounts if the estimated lift is
**>= +2.0 percentage points**; hold and investigate otherwise. A lift below
that bar is the pre-committed threshold for "not yet" — it is not itself
evidence the checklist fails, but it does not clear the bar to ship.
