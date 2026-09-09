# Fresh-context recovery audit

## Finding

The original Stage 1 v1 baseline is fully recoverable from preserved artifacts. Its stored and independently recomputed values match exactly (double precision): coefficient **-4.3356939590696033** and state-clustered standard error **0.43794628155454418**; both recomputation-minus-stored differences are **0**.

Actual historical Stage 1 code content is retained in `analysis.R` (MD5 `46c58ef0252e786113ff53297a21c99b`). This is not merely a retained hash or prose/formula description. The preserved code was inspected directly; this audit did not infer or rewrite it.

## Exact Stage 1 v1 baseline

- Input: `panel_v1.csv`, MD5 `a81bc8b766a03a9d963fdc83152f3bf4`; 2,400 unique state-month observations, 40 states, 60 months, balanced; 20 treated and 20 never-treated states.
- Treatment build: parse `month` and `adoption_date` as dates; set `policy_on = 1` exactly when `treated == 1`, adoption date is nonmissing, and `month_date >= adoption_date`. All treated states adopt on `2021-01-01`; this yields 480 treated state-months.
- Estimator/specification: unweighted `fixest::feols(opioid_rate ~ policy_on | state_id + month_date, data = d, cluster = ~state_id)`.
- Inference: clustering by `state_id`; `fixest` 0.14.2 defaults retained (`K.adj=TRUE`, `K.fixef="nonnested"`, `G.adj=TRUE`, `G.df="min"`, `t.df="min"`), with 39 reference degrees of freedom.
- Historical implementation/output: `analysis.R` -> `did_results_full_precision.csv` (plus `did_model.rds`, `validation_diagnostics.csv`, `session_info.txt`, and `RESULTS.md`). Stored output MD5: `17c55991be5db9478379b63b59b17118`.

The recomputation loaded `panel_v1.csv`, repeated the preserved treatment construction and exact `feols` call in a fresh R process, and printed results only; it did not run `analysis.R` or write/overwrite any historical artifact. Environment matched the preserved record: R package `fixest` 0.14.2.

## Provenance map

| Stage | Data/version | Build or analysis code | Result provenance |
|---|---|---|---|
| Stage 1 | v1: `panel_v1.csv` (`a81bc8b766a03a9d963fdc83152f3bf4`) | Historical content retained in `analysis.R` | Original baseline in `did_results_full_precision.csv`: state/month FE primary DiD |
| Stage 2 | v1 unchanged: same `panel_v1.csv` and MD5 | `stage2_analysis.R` | `stage2_results_full_precision.csv`: pooled region-specific model and state-specific-linear-trend alternative; every row identifies v1 input/MD5 |
| Stage 3 | v2: `panel_v2.csv` (`219b9909d2dd96394e3172dbbfc3d936`) built from v1 plus `panel_update.csv` (`eabeaa442be931e667b5ae81a5a85200`) | `stage3_analysis.R`; latest `revision_ts` per state-month, update wins overlaps, v1-only keys retained | `stage3_v2_results_full_precision.csv`: v2 primary, regional, and trend models; `CURRENT_RESULTS.csv` marks v2 current and v1 historical |

Stage 3 reconciliation is preserved in `stage3_build_audit.csv`: 721 raw update rows become 720 latest update keys after one older duplicate is removed; they replace 720 overlaps, 1,680 v1-only keys remain, and v2 retains all 2,400 panel keys with zero rows dropped.
