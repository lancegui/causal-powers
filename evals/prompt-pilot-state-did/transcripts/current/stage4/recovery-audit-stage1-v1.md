# Stage 1 v1 recovery audit

Audit date: 2026-09-09  
Scope: recovery from saved artifacts only; `panel_v2.csv` and all v2 estimates were excluded from reconstruction of the v1 baseline.

## Recovered baseline

- Historical baseline family: Stage 1 v1 (`stage1_primary_result`), distinct from the Stage 3 current-result pointer to v2.
- Raw input: `panel_v1.csv`, SHA-256 `02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe`.
- Source/build code: `analysis_stage1.R`, SHA-256 `5b21e757fcf648380e488e8953b7e21a17020b4b7dffd9545d32dda6dbc323f5`.
- Construction: parse `month` and `adoption_date`; define `post = 1[month >= 2021-01-01]`; define `policy = treated * post`. The script asserts one row per state-month, 40 states, 20 adopters, 20 never adopters, a balanced 60-month panel (2,400 observations), and common adopter date 2021-01-01.
- Exact primary specification: `fixest::feols(opioid_rate ~ policy | state_id + month, data = panel, cluster = ~state_id)` using fixest defaults. The coefficient is in monthly opioid prescriptions per 100,000; inference clusters by state (40 clusters; reported cluster df 39).
- Saved baseline output: `results/stage1_did_results.csv`, SHA-256 `57b0f3e7025591c497b1128f68c60a56a64d353229c1dfc7102950cc1eadc1ea`.

## Stored versus recomputed

The recomputation copied only `panel_v1.csv` and `analysis_stage1.R` to `/private/tmp/did-v1-recompute.fXVORF`, ran `Rscript analysis_stage1.R`, and compared the generated CSV with the saved CSV using `cmp` and SHA-256.

| Quantity | Stored | Recomputed | Match |
|---|---:|---:|---|
| policy coefficient | -4.3356939590696033 | -4.3356939590696033 | exact |
| state-clustered SE | 0.43794628155454418 | 0.43794628155454418 | exact |
| result CSV SHA-256 | `57b0f3e7025591c497b1128f68c60a56a64d353229c1dfc7102950cc1eadc1ea` | `57b0f3e7025591c497b1128f68c60a56a64d353229c1dfc7102950cc1eadc1ea` | byte-identical |

Runtime used for the independent rerun: R 4.5.3 and fixest 0.14.2. The mandatory event-study diagnostic also reproduced F = 7.4515627257324155 with p = 4.8825926474646623e-09; the parallel-pretrend joint null is rejected, so the stored causal-interpretation caution remains material.

## Provenance of every saved result family

1. **Stage 1 v1 primary and diagnostics.** `panel_v1.csv` -> `analysis_stage1.R` -> `results/stage1_did_results.csv`, `results/stage1_diagnostics.csv`, `results/stage1_did_model.rds`, `results/stage1_event_study_model.rds`, `results/missingness.csv`, and `results/sessionInfo.txt`. The phase record is `docs/analysis/phases/stage-1-primary-did.yaml`; the run record is `docs/analysis/runs/2026-10-20-stage1.yaml`.
2. **Stage 2 v1 region and state-trend results.** The same frozen `panel_v1.csv` -> `analysis_stage2.R` (SHA-256 `9da8d0b3727adf03fc22a4bdb5c5429e4bd14c5436091f387857570f24e85bef`) -> `results/stage2_results.csv` (SHA-256 `ecdc744ed4de8284371a05c59c3e6cd7b3b2173eb63dbcfd06e94f0e9ab6900d`), region/trend model RDS files, manifest, and session info. Specifications are the pooled `opioid_rate ~ policy:region | state_id + month` model and `opioid_rate ~ policy | state_id + month + state_id[[time_index]]`, both state-clustered with fixest defaults. The manifest records the Stage 1 result hash unchanged before and after.
3. **Stage 3 v2 current results and build audits.** These are a separate vintage and were not used to reconstruct v1. `analysis_stage3.R` (SHA-256 `6b51ed805438207353918fac19cc52580f933f2a51db9004e3c59f466218b9e4`) combines frozen `panel_v1.csv` with raw `panel_update.csv` (SHA-256 `4535f64c92826efcd210a9f72c4abed3820aa5899ad30ccb532edfab6389521b`) by retaining the greatest `revision_ts` per state-month, overlaying 720 matching rows, retaining 1,680 v1-only rows, and recoding validated missing never-treated fields. It produces `data/panel_v2.csv` (SHA-256 `ef72c95910c3ffb137cab6535fe2f67fbe1c053487d1e6edd0c873e19d7579e7`) and `results/stage3_v2_results.csv` (SHA-256 `a6d5d27f62d15eb52cf94175ee0100118093843d4bd4eba75a51ae717214bab1`), plus v2 model RDS files, build/duplicate/missingness audits, manifest, and session info. `docs/analysis/decisions.yaml` identifies this family as current while preserving v1 as historical.

Audit note: an initial audit invocation reran `analysis_stage1.R` in the runtime before the isolated rerun. The regenerated Stage 1 result CSV retained its recorded SHA-256 exactly; the subsequent clean-room run established independent byte-for-byte reproduction.
