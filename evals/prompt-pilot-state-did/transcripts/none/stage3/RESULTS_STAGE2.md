# Stage 2 results

The pooled region-specific model uses all 2,400 observations, state fixed effects, common month fixed effects, and state-clustered inference. Estimated policy effects (rate points per 100,000 per month) are:

| Region | Estimate | Clustered SE | 95% CI |
|---|---:|---:|---:|
| North | -5.3943 | 0.2269 | [-5.8532, -4.9353] |
| South | -1.9718 | 0.2132 | [-2.4031, -1.5405] |
| East | -6.4759 | 0.4007 | [-7.2864, -5.6654] |
| West | -3.5008 | 0.2780 | [-4.0632, -2.9385] |

All four regions show a decrease relative to never-adopting states in the same common calendar months, with the largest estimated decrease in East and the smallest in South. Each region contains five treated and five never-treated states.

The sole alternative adds a separate linear month trend for every state to the baseline state/month fixed-effects specification. Its estimate is **-4.0311** (state-clustered SE 0.5284; 95% CI [-5.0999, -2.9623]; p = 2.98e-09), compared with the preserved Stage 1 baseline of -4.3357. Thus, allowing differential linear pre-existing trajectories modestly attenuates the estimated decrease, while leaving the substantive conclusion intact.

The machine-readable output identifies `panel_v1.csv` by MD5 (`a81bc8b766a03a9d963fdc83152f3bf4`) on every result row and records the exact formula, cluster variable, `fixest` version, finite-sample settings, sample size, and inference degrees of freedom. Causal interpretation retains the usual DiD assumptions.
