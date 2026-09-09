1. Inspect `panel_v1.csv`; identify the outcome, state, month, and adoption fields; verify panel uniqueness, balance, missingness, and the stated 20/20 treatment split.
2. Estimate the requested state and month fixed-effects DiD in R with `fixest::feols`, clustering standard errors by state and retaining `fixest`'s default finite-sample correction.
3. Save a reproducible R script, validation diagnostics, and full-precision machine-readable coefficient and model metadata; run the script from a clean R process and report the estimate, uncertainty, and interpretation.
