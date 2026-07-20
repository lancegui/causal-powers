# Codebook -- data/bid_quarterly.csv and data/bid_registry.csv

## data/bid_quarterly.csv (one row per BID per quarter)
- `bid_id` -- Business Improvement District identifier.
- `quarter` -- `2025-Q3`, `2025-Q4` (pre-pilot), `2026-Q1`, `2026-Q2` (pilot live).
- `avg_weekly_foot_traffic_index` -- average weekly foot-traffic index for
  ground-floor retail frontage in the district that quarter (city baseline = 100).

## data/bid_registry.csv (BID-level covariates, from the Q1 planning deck)
- `bid_id` -- Business Improvement District identifier.
- `pilot_enrolled` -- 1 if the district won the lottery and is running the
  loading-zone permit pilot, 0 if not.
- `baseline_foot_traffic_index` -- the district's historical foot-traffic
  index level prior to the pilot.
- `avg_commercial_rent_per_sqft` -- average asking commercial rent, $/sqft.
- `resident_population` -- residential population within the district boundary.
- `permit_readiness_score` -- a 0-100-ish composite the permitting office
  uses to track how "ready" a district's loading infrastructure and paperwork
  are: pilot enrollment status, weighted heavily (districts running the pilot
  had to complete the expanded-permit paperwork to enroll), plus a smaller
  weight on how recently the district's loading docks passed a safety
  inspection (more recently inspected docks score higher). Established once
  at pilot launch and not updated intra-pilot.

Note: `data/bid_registry.csv` was assembled by merging the current BID
directory with the legacy directory after last spring's district-renumbering
project; a handful of districts that existed under both an old and a new ID
briefly appear under both during the transition.
