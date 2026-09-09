# Stage 2 DiD results

- post: -4.012268 (SE 0.529583; 95% CI [-5.083450, -2.941086]; p = 3.51174e-09)

All outcomes are monthly opioid-prescribing rate points per 100,000; standard errors are clustered by state using fixest defaults. The region specification is one pooled model with state and common month fixed effects; each coefficient compares the post-policy change for treated states in that region with never-treated states under parallel trends. The trends alternative adds a separate linear trend for every state to the baseline state/month-FE model. Regional estimates are based on five treated and five control states per region and should be interpreted cautiously because cluster counts within each region are small. Both causal interpretations require parallel counterfactual trends (conditional on state-specific linear trends in the alternative), no spillovers, and no coincident adopting-state shocks.

