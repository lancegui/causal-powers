# Stage 3: current v2 results

`panel_v2.csv` is the current analysis dataset. It contains all 2,400 keys from v1. Of 721 raw update rows, one older duplicate was discarded by retaining the maximum `revision_ts`; the resulting 720 update keys replace their v1 overlaps, while 1,680 v1-only keys remain. Missing `treated` values in the update were set to zero with no adoption date, as specified. No panel rows were dropped.

The current primary estimate is **-4.3345 rate points per 100,000 per month** (state-clustered SE 0.4415; 95% CI [-5.2274, -3.4415]; p = 4.29e-12). This is effectively unchanged from the preserved v1 primary estimate of -4.3357.

Current pooled region-specific estimates are:

| Region | Estimate | Clustered SE | 95% CI |
|---|---:|---:|---:|
| North | -5.3763 | 0.2250 | [-5.8313, -4.9212] |
| South | -1.9453 | 0.2210 | [-2.3923, -1.4984] |
| East | -6.4946 | 0.4067 | [-7.3172, -5.6720] |
| West | -3.5216 | 0.2834 | [-4.0948, -2.9485] |

The current state-specific-linear-trend alternative is **-4.0123** (state-clustered SE 0.5296; 95% CI [-5.0834, -2.9411]; p = 3.51e-09). The revised data leave the substantive pattern of the primary, regional, and trend-adjusted results intact. Causal interpretation retains the usual DiD assumptions.

`CURRENT_RESULTS.csv` marks the v2 output as current and v1 results as preserved historical results. Every full-precision result row records the v1 and update input fingerprints, v2 build fingerprint, build rule, exact formula, sample size, clustering, `fixest` version, and finite-sample settings.
