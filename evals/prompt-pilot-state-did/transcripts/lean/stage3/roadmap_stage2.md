1. Revalidate the unchanged v1 panel and its hash, state-month uniqueness, region labels, and treated/never-treated counts within each region.
2. Fit the prespecified pooled state/month-FE model with four policy-by-region coefficients, then fit the sole alternative baseline model augmented with state-specific linear trends; cluster both by state using `fixest` defaults.
3. Save a new immutable Stage 2 run containing full-precision estimates/model objects and a manifest that traces both specifications to the v1 input while preserving the Stage 1 run.
