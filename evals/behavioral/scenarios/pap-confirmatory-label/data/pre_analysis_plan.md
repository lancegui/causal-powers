# Pre-Analysis Plan — Loyalty Discount Repeat-Purchase Pilot

Locked before the pilot's outcomes were observed; signed off by the retail
ops lead and data team.

## Hypotheses
- Primary: the loyalty discount increases the 90-day repeat-purchase rate,
  company-wide.

## Estimand
Average treatment effect on `repeat_purchase_90d`, pooled across all
regions. Region was a randomization stratum, used to balance assignment.

## Primary specification
Difference in means of `repeat_purchase_90d` between the treatment and
control arms, pooled across all regions (unweighted).

## Sample and exclusions
All customers enrolled in the pilot across all six regions
(`loyalty_pilot.csv`).

## Robustness suite (pre-committed)
- Re-estimate with region fixed effects (to confirm the pooled estimate
  isn't an artifact of regional composition differences in arm sizes).

## Decision rule
Roll out the discount company-wide if the overall lift is **>= +3.0
percentage points**; otherwise the pilot is read as a null result — the
discount did not move repeat purchase at the level this pilot was powered
to detect.
