# Stage 1 roadmap

1. Preserve and hash the raw panel; inspect its schema without modifying it.
2. Validate the state-month panel key, treatment timing, row counts, missingness, and analysis sample.
3. Estimate the authorized state and month fixed-effects DiD in R with state-clustered standard errors using `fixest` defaults.
4. Save full-precision estimates, a compact reconciliation/history record, and a human-readable report; rerun to verify reproducibility.
