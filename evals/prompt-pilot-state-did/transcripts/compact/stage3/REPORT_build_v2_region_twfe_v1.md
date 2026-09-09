# Stage 2 DiD results

- post_North: -5.376272 (SE 0.224968; 95% CI [-5.831314, -4.921231]; p = 6.72275e-25)
- post_South: -1.945339 (SE 0.220965; 95% CI [-2.392283, -1.498395]; p = 8.29506e-11)
- post_East: -6.494609 (SE 0.406667; 95% CI [-7.317170, -5.672048]; p = 1.0578e-18)
- post_West: -3.521626 (SE 0.283362; 95% CI [-4.094779, -2.948474]; p = 3.86622e-15)

All outcomes are monthly opioid-prescribing rate points per 100,000; standard errors are clustered by state using fixest defaults. The region specification is one pooled model with state and common month fixed effects; each coefficient compares the post-policy change for treated states in that region with never-treated states under parallel trends. The trends alternative adds a separate linear trend for every state to the baseline state/month-FE model. Regional estimates are based on five treated and five control states per region and should be interpreted cautiously because cluster counts within each region are small. Both causal interpretations require parallel counterfactual trends (conditional on state-specific linear trends in the alternative), no spillovers, and no coincident adopting-state shocks.

