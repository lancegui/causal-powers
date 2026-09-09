# Compact recovery audit

## Stage 1 v1 baseline and recomputation

The original baseline is `build_v1 / run_v1 / twfe_v1`. Its exact recorded input is `panel_v1.csv`, MD5 `a81bc8b766a03a9d963fdc83152f3bf4`, used unchanged as a 40-state by 60-month panel (2,400 rows; unique `state_id × month`; 20 treated and 20 never-treated states). The constructed treatment indicator is `post = treated × 1[month >= 2021-01-01]`. The specification is

`opioid_rate ~ post | state_id + month_date`, estimated in R with `fixest::feols` and `cluster = ~state_id` (state and month fixed effects; 40 state clusters; 2,400 observations; cluster-t df = 39).

The historical record identifies Stage 1 code by MD5 `e75be96fcd6ce4833418da2377461494`. **The actual historical Stage 1 code content is not retained**: there is no script with that hash in the compact artifacts. Only its hash, recorded build rule/formula, reconciliation, estimate, and report survive. The sole surviving `analysis.R` has MD5 `900936eb0e887de63bd9a16b008b511e` and is later Stage 3 code, so byte-for-byte historical-code recovery is impossible and was not repaired.

I recomputed the recorded Stage 1 specification read-only from the preserved `panel_v1.csv`, using R `fixest` 0.14.2, without invoking the artifact-writing script or overwriting any historical artifact:

| quantity | stored | recomputed | match |
|---|---:|---:|---|
| coefficient (`post`) | -4.3356939590696033 | -4.3356939590696033 | exact at stored precision |
| state-clustered SE | 0.43794628155454418 | 0.43794628155454418 | exact at stored precision |

## Provenance map

| stage | build / runs / specs | inputs and construction | recorded code identity |
|---|---|---|---|
| Stage 1 v1 | `build_v1 / run_v1 / twfe_v1` | `panel_v1.csv` (`a81bc...f3bf4`), unchanged; baseline post indicator above | `e75be...1494`; content absent |
| Stage 2 v1 | `build_v1 / run_region_v1 / region_twfe_v1`; `build_v1 / run_trends_v1 / state_trends_v1` | same preserved v1 input and unchanged build; pooled region-specific post coefficients or baseline plus state-specific linear trends | `074c12...8f75`; content absent |
| Stage 3 v2 | preliminary `run_v2_primary`, `run_v2_region`, `run_v2_trends`; final `run_v2_primary_final / twfe_v1`, `run_v2_region_final / region_twfe_v1`, `run_v2_trends_final / state_trends_v1` | `panel_v1.csv` (`a81bc...f3bf4`) + `panel_update.csv` (`eabeaa...5200`); latest `revision_ts` removes one update duplicate, update wins 720 overlapping keys, 1,680 v1-only keys retained, yielding `built_v2.csv` with 2,400 unique keys | preliminary `3d88bf...a3d`; final `900936...511e`, whose content survives as `analysis.R` |

`CURRENT` points to the final Stage 3 trends run, while `CURRENT.csv` maps all three final Stage 3 specifications. No missing historical code was synthesized.
