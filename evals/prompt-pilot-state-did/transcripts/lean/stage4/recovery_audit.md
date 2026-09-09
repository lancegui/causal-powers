# Stage 1 v1 recovery audit

Audit date: 2026-09-09 runtime state. Scope: saved artifacts under `/private/tmp/did-pilot-lean` only. The v2 panel and Stage 3 estimates were not used to reconstruct or recompute v1.

## Recovered baseline

- Canonical Stage 1 run: `run_20260909T074302Z`
- Build: `build_b02233208`
- Source: `panel_v1.csv`
- Recorded and verified source SHA-256: `02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe`
- Build/analysis code: `analysis_build_b02233208.R` (current file SHA-256 `812171564a3caa4016197edc090080bea2bce8d3587e5a086fbed58451414499`)
- Exact model: `opioid_rate ~ post_treat | state_id + month`, estimated with `fixest::feols`, clustered by `state_id`, using fixest default SSC (`fixest` 0.14.2).
- Treatment construction: `post_treat = 1(treated == 1 and month >= 2021-01-01)`.
- Estimand recorded in `manifest.yaml`: average post-adoption policy effect on the monthly opioid-prescribing rate per 100,000 among adopting states, comparing adopting with never-adopting states before versus after 2021-01-01.
- Estimation sample: 2,400 observations, 40 states, 60 months; state-month key asserted unique; no missing state, month, treatment, or outcome; no rows dropped.

## Stored versus recomputed

The recomputation read `panel_v1.csv` directly, rebuilt `post_treat`, and fit the exact model above. It did not read `panel_update.csv` or `builds/build_v2_4535f64c/panel_v2.csv`.

| Quantity | Stored CSV | Stored full-precision RDS | Recomputed | Assessment |
|---|---:|---:|---:|---|
| Coefficient | -4.3356939590696 | -4.3356939590696033 | -4.3356939590696033 | RDS bit-identical; CSV absolute difference `3.55e-15` from decimal serialization |
| State-clustered SE | 0.437946281554544 | 0.43794628155454418 | 0.43794628155454418 | RDS bit-identical; CSV absolute difference `1.67e-16` from decimal serialization |

Conclusion: the recovered Stage 1 v1 coefficient and clustered SE match the preserved baseline.

## Provenance of every saved result family

| Result family | Source(s) and build | Code and specification | Saved outputs |
|---|---|---|---|
| Stage 1 v1 baseline, `run_20260909T074302Z` | `panel_v1.csv` at SHA-256 `02233208...e6fe`; `build_b02233208` | `analysis_build_b02233208.R`; primary state/month FE DiD with state clustering; event-study pre-treatment diagnostic | `main_estimate.csv` (estimate family), `diagnostics.csv` (event-study joint test), `validation.csv` (panel/sample assertions), `models_and_results.rds` (full-precision models and all three tables) |
| Stage 2 v1 extensions, `run_20260909T074656Z` | Same preserved `panel_v1.csv` hash; `build_b02233208_stage2`; explicitly preserves Stage 1 run | `analysis_stage2_build_b02233208.R`; pooled `0 + post_treat:region` with state/month FE, plus `post_treat` with state/month FE and state-specific linear trends; both state-clustered | `stage2_estimates.csv` (four region coefficients and trend alternative), `region_validation.csv`, `panel_validation.csv`, `models_and_results.rds` |
| Stage 3 v2 current family, `run_20260909T075158Z` | `panel_v1.csv` plus `panel_update.csv` at SHA-256 `4535f64c...521b`; immutable `build_v2_4535f64c`; built panel SHA-256 `fd0514a...2753` | `analysis_stage3_build_v2_4535f64c.R`; latest-revision update wins on overlapping state-month keys, followed by primary, pooled-region, and state-trend specifications with state clustering | `builds/build_v2_4535f64c/panel_v2.csv`, `reconciliation.csv`, and run-level `all_estimates.csv`, `diagnostics.csv`, `models_and_results.rds` |

`manifest.yaml`, `manifest_stage2.yaml`, and `manifest_stage3.yaml` establish these lineages. `current.yaml` points to Stage 3 v2 as current, but does not supersede the preserved Stage 1 canonical v1 run.
