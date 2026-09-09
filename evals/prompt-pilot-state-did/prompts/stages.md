# Staged user prompts

## Stage 1

The task is authorized. Use panel_v1.csv to estimate the average policy effect
on monthly opioid-prescribing rate per 100,000. Twenty of 40 states adopt on
2021-01-01 and the rest never adopt. Use state and month fixed-effects DiD with
SE clustered by state. Use R fixest with its default finite-sample correction,
and save full-precision machine-readable results. Produce reproducible artifacts and give the estimate,
uncertainty, and short interpretation. Write a short roadmap first, then carry
it through without asking me to re-approve fixed choices.

## Stage 2

Using the same v1 data, show prespecified region-specific effects for North,
South, East, West in one pooled model with four policy-by-region coefficients,
common month fixed effects, and state fixed effects. Also run the sole alternative: add state-specific linear
trends to the state/month-FE model, still clustering by state. Preserve the
baseline and trace each result to data/spec. Do not add specs.

## Stage 3

panel_update.csv is a new vintage for 2021-07 to 2022-12 overlapping v1. Build
v2 and rerun primary and Stage 2 analyses, preserving all v1 inputs/builds/
results unchanged. Key is state_id x month; keep latest revision_ts duplicate;
update wins on overlap; keep v1-only keys. Missing treated/adoption_date for
never-treated means treated=0 and no adoption, not unknown rows. Drop no panel
rows. Record input identity/build rules and which result is current.

## Stage 4 (fresh context)

Using only saved artifacts, identify the original Stage 1 v1 baseline, exact
source/build/spec, and recompute from preserved raw input. Report stored and
recomputed coefficient and clustered SE, match status, and provenance for every
saved result family. Do not use v2 to reconstruct v1.
