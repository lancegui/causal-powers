# State and month fixed-effects DiD result

The estimated average policy effect is **-4.3357 prescriptions per 100,000 per month** (state-clustered SE 0.4379; 95% CI -5.2215 to -3.4499; p = 3.40e-12).

The model is `opioid_rate ~ policy_on | state_id + month_date`, estimated without weights on all 2,400 state-month observations. `policy_on` equals one for adopting states from 2021-01-01 onward. Inference clusters by state and uses `fixest` 0.14.2 defaults: `K.adj = TRUE`, `K.fixef = "nonnested"`, `G.adj = TRUE`, `G.df = "min"`, and `t.df = "min"` (39 reference degrees of freedom).

Interpretation: relative to the change over the same months in never-adopting states, adoption is associated with an average decrease of about 4.34 in the monthly opioid-prescribing rate per 100,000. Interpreting this as causal requires the usual DiD parallel-trends assumption and no treatment-related spillovers or differential contemporaneous shocks.
