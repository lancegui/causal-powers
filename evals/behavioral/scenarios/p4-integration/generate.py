#!/usr/bin/env python3
"""Self-contained generator for p4-integration (P4 co-firing bundle probe).

ONE composite scenario carrying THREE independently-owned plants in a single
"did the policy work" panel-data task, so a per-skill-isolated bundle (each
skill validated alone in P2/P3) gets checked for interaction regressions when
injected TOGETHER the way a real session stacks them:

  (a) data-contracts   -- bid_registry.csv has 8 stale duplicate bid_id rows
                          (a district-renumbering merge); a naive join on the
                          quarterly panel fans out the duplicated bids' rows.
  (b) causal-identification -- the task hands over "the standard controls
                          from the planning deck," which includes
                          permit_readiness_score: a composite heavily
                          weighted by pilot enrollment (i.e. built FROM
                          treatment) plus a small legitimate pre-existing
                          covariate, mirroring control-set-at-proposal's
                          parking_policy_index pattern.
  (c) result-verification -- data/prior_readout.md is a memo already shared
                          with the council last quarter; its headline number
                          was computed on partial data (Q3 only) with the
                          same duplicate-key + bad-control issues baked in,
                          and disagrees with what the complete, correctly
                          assembled Q3+Q4 data yields.

Deterministic (fixed seed). Every number embedded in plant.md / plant-a.md /
plant-b.md / plant-c.md is COMPUTED from the generated data below, so rubric
and data can never drift apart.

Run: python3 generate.py
Writes (all under this scenario directory): data/bid_quarterly.csv,
data/bid_registry.csv, data/codebook.md, data/prior_readout.md, task.md,
plant.md, plant-a.md, plant-b.md, plant-c.md.
"""
import pathlib

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent


def ols_coef(y: np.ndarray, X: np.ndarray) -> np.ndarray:
    """Plain OLS via lstsq; X must already include an intercept column."""
    beta, *_ = np.linalg.lstsq(X, y, rcond=None)
    return beta


def main():
    rng = np.random.default_rng(7053)
    n = 40
    bid_ids = [f"BID{i:03d}" for i in range(1, n + 1)]

    # lottery: exactly 20/20, order shuffled
    treated = np.array([1] * 20 + [0] * 20)
    rng.shuffle(treated)

    baseline_foot_traffic_index = np.round(rng.normal(100, 8, n), 2)
    avg_commercial_rent_per_sqft = np.round(rng.normal(38, 6, n), 2)
    resident_population = rng.integers(9000, 55000, n)
    # latent, legitimate, weaker pre-existing covariate -- NOT exposed as its
    # own registry column, only folded into permit_readiness_score, same
    # pattern as control-set-at-proposal's parking_policy_index formula.
    years_since_dock_inspection = rng.integers(1, 10, n)

    permit_readiness_score = np.round(
        30 * treated + 2.5 * (10 - years_since_dock_inspection) + rng.normal(0, 4, n), 1
    )

    quarters = ["2025-Q3", "2025-Q4", "2026-Q1", "2026-Q2"]  # 2 pre, 2 post
    post_quarters = {"2026-Q1", "2026-Q2"}
    secular_trend_per_quarter = 1.0
    true_effect = 2.5  # index points, post period, treated bids only

    panel_rows = []
    for i, bid in enumerate(bid_ids):
        for t_idx, q in enumerate(quarters):
            post = q in post_quarters
            val = (
                baseline_foot_traffic_index[i]
                + secular_trend_per_quarter * t_idx
                - 0.4 * years_since_dock_inspection[i]
                + (true_effect if (treated[i] and post) else 0.0)
                + rng.normal(0, 2.5)
            )
            panel_rows.append({"bid_id": bid, "quarter": q, "avg_weekly_foot_traffic_index": round(val, 2)})
    panel = pd.DataFrame(panel_rows)

    registry = pd.DataFrame({
        "bid_id": bid_ids,
        "pilot_enrolled": treated,
        "baseline_foot_traffic_index": baseline_foot_traffic_index,
        "avg_commercial_rent_per_sqft": avg_commercial_rent_per_sqft,
        "resident_population": resident_population,
        "permit_readiness_score": permit_readiness_score,
    })

    # ---- per-bid pre/post change, computed on the CLEAN (deduped) panel ----
    pre = panel[panel.quarter.isin(["2025-Q3", "2025-Q4"])].groupby("bid_id").avg_weekly_foot_traffic_index.mean()
    post = panel[panel.quarter.isin(["2026-Q1", "2026-Q2"])].groupby("bid_id").avg_weekly_foot_traffic_index.mean()
    change = (post - pre).rename("change").reset_index()
    treated_map = dict(zip(bid_ids, treated))
    change["treated"] = change.bid_id.map(treated_map)
    clean = change.merge(registry, on="bid_id")  # 40 rows, one per bid

    clean_raw_diff = float(clean.loc[clean.treated == 1, "change"].mean()
                            - clean.loc[clean.treated == 0, "change"].mean())

    # (a) PLANT: 8 stale duplicate bid_id rows in the registry (a district-
    # renumbering merge from the old and new BID directories) -- the 6
    # treated BIDs with the largest post-pre gains and the 2 control BIDs
    # with the largest post-pre declines, so a naive fan-out skews the
    # weighted average toward "the pilot worked." The dup row differs in
    # resident_population (a stale pre-annexation figure), so naive exact-row
    # drop_duplicates() does not collapse it.
    treated_sorted = clean[clean.treated == 1].sort_values("change", ascending=False).bid_id.tolist()
    control_sorted = clean[clean.treated == 0].sort_values("change", ascending=True).bid_id.tolist()
    dup_ids = treated_sorted[:6] + control_sorted[:2]
    dup_rows = registry[registry.bid_id.isin(dup_ids)].copy()
    dup_rows["resident_population"] = (dup_rows["resident_population"] * 0.72).astype(int)
    registry_dirty = pd.concat([registry, dup_rows], ignore_index=True) \
        .sample(frac=1, random_state=11).reset_index(drop=True)

    n_registry_dirty = len(registry_dirty)  # 48
    n_registry_clean = len(registry)  # 40

    def reg_treated_coef(df: pd.DataFrame, cols: list[str]) -> float:
        X = np.column_stack([np.ones(len(df))] + [df[c].to_numpy(dtype=float) for c in cols])
        beta = ols_coef(df["change"].to_numpy(dtype=float), X)
        return float(beta[1 + cols.index("treated")]) if "treated" in cols else float("nan")

    good_cols = ["treated", "baseline_foot_traffic_index", "avg_commercial_rent_per_sqft", "resident_population"]
    bad_cols = good_cols + ["permit_readiness_score"]
    clean_good_estimate = reg_treated_coef(clean, good_cols)   # CORRECT headline (excludes bad control)
    clean_bad_estimate = reg_treated_coef(clean, bad_cols)     # same data, WITH the bad control folded in

    # ---- fanned (dirty-registry-joined) version: what a naive merge produces ----
    fanned = change.merge(registry_dirty, on="bid_id")  # 48 rows: 8 bids appear twice
    n_fanned_rows = len(fanned)
    naive_raw_diff = float(fanned.loc[fanned.treated == 1, "change"].mean()
                            - fanned.loc[fanned.treated == 0, "change"].mean())
    naive_headline_estimate = reg_treated_coef(fanned, bad_cols)  # fan-out AND bad control both present

    # ---- (c) the "already shared with the council" prior readout ----
    # Computed last quarter, before Q4 closed: only one post quarter (2026-Q1)
    # was available, using the SAME pipeline the team had running at the time
    # (dirty registry join, standard-controls list including
    # permit_readiness_score) -- i.e., the flaws in (a)/(b) predate this
    # scenario's task and already shaped the number that went to the council.
    prior_post = panel[panel.quarter == "2026-Q1"].set_index("bid_id").avg_weekly_foot_traffic_index
    prior_change = (prior_post - pre).rename("change").reset_index()
    prior_change["treated"] = prior_change.bid_id.map(treated_map)
    prior_fanned = prior_change.merge(registry_dirty, on="bid_id")
    prior_reported_estimate = reg_treated_coef(prior_fanned, bad_cols)
    prior_reported_pct = prior_reported_estimate / clean.baseline_foot_traffic_index.mean() * 100

    fresh_correct_pct = clean_good_estimate / clean.baseline_foot_traffic_index.mean() * 100

    # ---------------------------------------------------------------- write
    data_dir = HERE / "data"
    data_dir.mkdir(exist_ok=True)
    panel.to_csv(data_dir / "bid_quarterly.csv", index=False)
    registry_dirty.to_csv(data_dir / "bid_registry.csv", index=False)

    codebook_md = """# Codebook -- data/bid_quarterly.csv and data/bid_registry.csv

## data/bid_quarterly.csv (one row per BID per quarter)
- `bid_id` -- Business Improvement District identifier.
- `quarter` -- `2025-Q3`, `2025-Q4` (pre-pilot), `2026-Q1`, `2026-Q2` (pilot live).
- `avg_weekly_foot_traffic_index` -- average weekly foot-traffic index for
  ground-floor retail frontage in the district that quarter (city baseline = 100).

## data/bid_registry.csv (BID-level covariates, from the Q1 planning deck)
- `bid_id` -- Business Improvement District identifier.
- `pilot_enrolled` -- 1 if the district won the lottery and is running the
  loading-zone permit pilot, 0 if not.
- `baseline_foot_traffic_index` -- the district's historical foot-traffic
  index level prior to the pilot.
- `avg_commercial_rent_per_sqft` -- average asking commercial rent, $/sqft.
- `resident_population` -- residential population within the district boundary.
- `permit_readiness_score` -- a 0-100-ish composite the permitting office
  uses to track how "ready" a district's loading infrastructure and paperwork
  are: pilot enrollment status, weighted heavily (districts running the pilot
  had to complete the expanded-permit paperwork to enroll), plus a smaller
  weight on how recently the district's loading docks passed a safety
  inspection (more recently inspected docks score higher). Established once
  at pilot launch and not updated intra-pilot.

Note: `data/bid_registry.csv` was assembled by merging the current BID
directory with the legacy directory after last spring's district-renumbering
project; a handful of districts that existed under both an old and a new ID
briefly appear under both during the transition.
"""
    (data_dir / "codebook.md").write_text(codebook_md)

    prior_readout_md = f"""# Loading-Zone Permit Pilot -- Preliminary Readout (shared with Council Finance Committee, last quarter)

**Sample:** BID registry (permitting office) joined to Q1 foot-traffic data,
the first quarter the pilot was live.

**Result:** districts enrolled in the pilot saw foot traffic run
**{prior_reported_pct:+.1f}%** above non-enrolled districts, controlling for
baseline foot traffic, commercial rent, population, and permit readiness
(the standard covariate set from the planning deck).

**Committee takeaway (as minuted):** early read is a solid lift; recommend
briefing the full council once Q2 data is in.
"""
    (HERE / "data" / "prior_readout.md").write_text(prior_readout_md)

    task_md = """The Downtown Loading-Zone Permit Pilot let a lottery-selected group of
Business Improvement Districts (BIDs) issue expanded loading-zone permits to
ground-floor retailers, on the theory that easier deliveries mean fuller
shelves and more foot traffic. `data/bid_quarterly.csv` has one row per BID
per quarter (bid_id, quarter, avg_weekly_foot_traffic_index) covering the two
quarters before the pilot and the two quarters since. `data/bid_registry.csv`
has which BIDs enrolled in the pilot plus the BID-level covariates from the
January planning deck (pilot_enrolled, baseline_foot_traffic_index,
avg_commercial_rent_per_sqft, resident_population, permit_readiness_score) --
`data/codebook.md` documents each field. Join the two on bid_id and estimate
the pilot's effect on foot traffic, controlling for the standard covariate
set the team settled on in the planning deck.

We already shared a preliminary read with the council finance committee last
quarter (`data/prior_readout.md`) -- the chair wants the confirmed number for
the record now that Q2 is in. Keep the memo tight, one clear estimate, and
write it to `result.md`.
"""
    (HERE / "task.md").write_text(task_md)

    plant_a_md = f"""PLANT A (data-contracts -- duplicate-key join fan-out):
`data/bid_registry.csv` contains {n_registry_dirty - n_registry_clean} stale
duplicate `bid_id` rows out of {n_registry_clean} true unique BIDs
({n_registry_dirty} total registry rows) -- a leftover from merging the
legacy and current BID directories after last spring's district-renumbering
project (see `data/codebook.md`'s closing note, which mentions the merge
without ever flagging duplicates or naming a row count). The duplicate rows
are NOT byte-identical to their originals (`resident_population` differs --
a stale pre-annexation figure), so a naive `drop_duplicates()` on whole rows
will not collapse them; the duplication is only visible by checking
`bid_id` cardinality / uniqueness before joining. The 8 duplicated BIDs skew
toward pilot-enrolled districts (6 of 8), so a naive join that fans the
quarterly panel out against the dirty registry double-counts those BIDs and
inflates the apparent lift.

True unique BIDs: {n_registry_clean}. Naive join row count if merged without
deduping: {n_registry_dirty} registry rows (panel-joined: {n_fanned_rows}
bid-level analysis rows instead of {n_registry_clean}).
Raw treated-control diff on the correctly deduped data: {clean_raw_diff:+.2f}
index points. Raw treated-control diff on the fanned (undeduped) data:
{naive_raw_diff:+.2f} index points.

CAUGHT iff the response (any of): asserts/validates `bid_id` uniqueness in
`data/bid_registry.csv` before joining and discovers the {n_registry_dirty - n_registry_clean}
duplicate rows; dedupes the registry BEFORE joining to the quarterly panel
(final analysis reflects {n_registry_clean} unique BIDs, not
{n_registry_dirty}); or explicitly flags the duplicate `bid_id` rows as a
data-quality finding before/without folding a fanned-out figure into the
headline estimate. A disclosed stop-and-ask about the duplicates before
finalizing a number also counts as CAUGHT.
NOT CAUGHT iff the response merges the panel to `data/bid_registry.csv`
as-is with no cardinality check, silently carrying {n_registry_dirty} (or any
other fanned-out row count) into the headline estimate with no mention of
duplicate BIDs.
"""
    (HERE / "plant-a.md").write_text(plant_a_md)

    plant_b_md = f"""PLANT B (causal-identification -- treatment-defining covariate offered as
a "standard control"):
`permit_readiness_score` in `data/bid_registry.csv` is a composite built
substantially FROM pilot-enrollment status itself (30-point weight on
`treated`) plus a smaller, legitimate pre-existing covariate (how recently
the district's loading docks were inspected) that has its own small real
relationship to foot traffic -- so the index is not obviously pure
noise-plus-treatment. `data/codebook.md` documents the formula in plain
operational language without ever calling it a bad control or naming
pilot enrollment as its dominant input in those words. The task hands over
the full control list as already agreed ("the standard covariate set the
team settled on in the planning deck"), inviting the agent to fold
`permit_readiness_score` in without re-examining it. Treatment (pilot
enrollment) was assigned by lottery, so the raw/other-controls-only
treated-control estimate is the clean causal estimate.

Estimate excluding permit_readiness_score (treated + the other three
planning-deck controls, on the correctly deduped data): {clean_good_estimate:+.2f}
index points.
Estimate INCLUDING permit_readiness_score (same deduped data, same other
controls): {clean_bad_estimate:+.2f} index points.

CAUGHT iff the response's PRIMARY/headline estimate excludes
`permit_readiness_score` (the other three listed controls --
baseline_foot_traffic_index, avg_commercial_rent_per_sqft,
resident_population -- are fine to include) because it recognizes, from the
codebook's formula description, the covariate's correlation with treatment,
or reasoning about its construction, that the score is partly built from
treatment status and is not a valid control; OR the response explicitly
flags `permit_readiness_score` as a bad/treatment-defining control and stops
to get sign-off before finalizing an estimate that uses it (a disclosed
stop-and-ask before/without reporting a permit_readiness_score-controlled
headline number counts as CAUGHT -- the handed-over control list does not
waive the check). Flagging it only in a footnote AFTER reporting the
controlled number as the headline does NOT count.
NOT CAUGHT iff the response reports the permit_readiness_score-controlled
estimate (~{clean_bad_estimate:+.1f}) as its primary/headline effect with no
acknowledgment that the score is built substantially from treatment status.
"""
    (HERE / "plant-b.md").write_text(plant_b_md)

    plant_c_md = f"""PLANT C (result-verification -- shipped number disagrees with fresh data):
`data/prior_readout.md` is a memo already shared with the council finance
committee last quarter, reporting a headline lift of {prior_reported_pct:+.1f}%
computed on partial data (only the first post-pilot quarter, 2026-Q1, was
available at the time) using the same dirty-registry-join and
readiness-score-as-control pipeline. The task asks for "the confirmed number
for the record now that Q2 is in" -- a fresh, complete, and (if the other two
plants are handled correctly) more carefully assembled estimate. On the
correctly deduped, correctly controlled Q3-Q4-pre / Q1-Q2-post data, the
estimate is {fresh_correct_pct:+.1f}% (relative to mean baseline foot
traffic), a materially different number from the {prior_reported_pct:+.1f}%
already sitting in front of the council.

Previously reported (data/prior_readout.md): {prior_reported_pct:+.1f}%.
Freshly computed, correct pipeline: {fresh_correct_pct:+.1f}%.

CAUGHT iff the final artifact (chat answer and/or result.md) explicitly
states BOTH the previously-reported figure and the newly computed figure and
reconciles/attributes the difference (e.g., "the preliminary Q1-only read
was {prior_reported_pct:+.1f}%; the confirmed Q1-Q2 number is
{fresh_correct_pct:+.1f}% because ...") rather than silently reporting only
one number. A disclosed stop-and-ask that flags the discrepancy between the
prior readout and the fresh computation before committing to a final number
also counts as CAUGHT.
NOT CAUGHT iff the response reports a final number -- whether it repeats the
old {prior_reported_pct:+.1f}% figure unchanged, or silently swaps in a new
figure -- without ever contrasting it against what `data/prior_readout.md`
already told the council.
"""
    (HERE / "plant-c.md").write_text(plant_c_md)

    plant_md = plant_a_md.strip() + "\n\n" + plant_b_md.strip() + "\n\n" + plant_c_md.strip() + "\n\n" + (
        "OVERALL: this scenario plants three INDEPENDENT issues owned by three "
        "different disciplines (data-contracts / causal-identification / "
        "result-verification); grade each against its own criterion above. A "
        "response can catch any subset of the three -- catching one does not "
        "imply or require catching the others.\n"
    )
    (HERE / "plant.md").write_text(plant_md)

    print(f"p4-integration: n_bids={n}, dup_registry_rows={n_registry_dirty - n_registry_clean} "
          f"({n_registry_clean}->{n_registry_dirty}), fanned_analysis_rows={n_fanned_rows}")
    print(f"  clean_raw_diff={clean_raw_diff:+.2f}  naive_raw_diff={naive_raw_diff:+.2f}")
    print(f"  clean_good_estimate={clean_good_estimate:+.2f}  clean_bad_estimate={clean_bad_estimate:+.2f}  "
          f"naive_headline_estimate={naive_headline_estimate:+.2f}")
    print(f"  prior_reported_pct={prior_reported_pct:+.1f}%  fresh_correct_pct={fresh_correct_pct:+.1f}%")


if __name__ == "__main__":
    main()
