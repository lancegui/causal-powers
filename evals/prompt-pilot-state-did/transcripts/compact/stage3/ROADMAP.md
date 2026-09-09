# Stage 1 roadmap

1. Preserve and hash the raw panel; inspect its schema without modifying it.
2. Validate the state-month panel key, treatment timing, row counts, missingness, and analysis sample.
3. Estimate the authorized state and month fixed-effects DiD in R with state-clustered standard errors using `fixest` defaults.
4. Save full-precision estimates, a compact reconciliation/history record, and a human-readable report; rerun to verify reproducibility.

# Stage 2 roadmap

1. Revalidate the unchanged v1 panel and its region-by-treatment composition.
2. Estimate one pooled state/month-FE model with four policy-by-region coefficients.
3. Estimate the sole alternative baseline model with state-specific linear trends.
4. Append full-precision results and trace records without altering the preserved Stage 1 result, then verify exact reruns.

# Stage 3 roadmap

1. Hash and validate both raw vintages; resolve update duplicates at `state_id × month` by latest `revision_ts` and apply the stated never-treated missing-value rule.
2. Build and retain v2 with update precedence on overlap and v1-only keys retained; assert merge cardinality, row reconciliation, uniqueness, and zero row loss.
3. Rerun the primary, pooled region, and state-trends specifications on v2 only.
4. Append full-precision v2 estimates and provenance while preserving all v1 records, set the v2 runs current, and verify exact reruns.
