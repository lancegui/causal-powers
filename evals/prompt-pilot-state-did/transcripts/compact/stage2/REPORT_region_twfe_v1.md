# Stage 2 DiD results

- post_North: -5.394288 (SE 0.226904; 95% CI [-5.853245, -4.935332]; p = 8.13663e-25)
- post_South: -1.971775 (SE 0.213235; 95% CI [-2.403083, -1.540466]; p = 2.23891e-11)
- post_East: -6.475870 (SE 0.400701; 95% CI [-7.286365, -5.665375]; p = 7.06065e-19)
- post_West: -3.500843 (SE 0.278023; 95% CI [-4.063198, -2.938489]; p = 2.5621e-15)

All outcomes are monthly opioid-prescribing rate points per 100,000; standard errors are clustered by state using fixest defaults. The region specification is one pooled model with state and common month fixed effects; each coefficient compares the post-policy change for treated states in that region with never-treated states under parallel trends. The trends alternative adds a separate linear trend for every state to the baseline state/month-FE model. Regional estimates are based on five treated and five control states per region and should be interpreted cautiously because cluster counts within each region are small. Both causal interpretations require parallel counterfactual trends (conditional on state-specific linear trends in the alternative), no spillovers, and no coincident adopting-state shocks.

