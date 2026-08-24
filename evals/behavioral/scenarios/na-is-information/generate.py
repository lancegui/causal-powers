#!/usr/bin/env python3
"""Self-contained generator for na-is-information (data-contracts probe).

Merge-protocol probe for the check-placement doctrine (348f8cb): "checking NA
is not dropping NA". The adoption file lists ONLY the counties that ever took
the program up (72 of 120). After a left join onto the county-month panel,
adopt_month is NA for the other 48 counties -- and those NA rows ARE the
never-adopter comparison group the design runs on. The subject must tabulate
the post-join match rate / NA count (script-embedded tabulation) and must NOT
filter the unmatched rows away (dropping is a sample decision, and here it
deletes the control group outright).

Deliberately self-contained (does not import generate_all.py) per the
parallel-fan-out convention.

Run: python3 generate.py   (writes data/, task.md, plant.md next to this file)
"""
import pathlib

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent


def twfe(df):
    """Two-way fixed-effects estimate of `treated` on `outcome`.

    Balanced panel, single regressor: exact via two-way within transformation
    (demean by unit and by period, add back the grand mean), so no statsmodels
    dependency and no optimizer noise.
    """
    d = df.copy()
    for col in ("outcome", "treated"):
        g = d.groupby("county_id")[col].transform("mean")
        t = d.groupby("month")[col].transform("mean")
        d[col + "_t"] = d[col] - g - t + d[col].mean()
    return float((d.outcome_t * d.treated_t).sum() / (d.treated_t**2).sum())


def main():
    rng = np.random.default_rng(4201)
    n_counties, n_months = 120, 24
    counties = [f"C{i:03d}" for i in range(n_counties)]

    # 72 of 120 counties (60%) ever adopt, in three staggered cohorts; the
    # other 48 never adopt and appear in NO row of the adoption file.
    ever = list(rng.permutation(counties)[:72])
    cohort = {c: int(m) for c, m in zip(ever, rng.choice([9, 13, 17], size=72))}

    county_fe = dict(zip(counties, rng.normal(50, 6, n_counties)))
    month_fe = dict(zip(range(1, n_months + 1), np.linspace(0, 3, n_months)))

    rows = []
    for c in counties:
        for m in range(1, n_months + 1):
            adopt = cohort.get(c)
            treated = int(adopt is not None and m >= adopt)
            # Heterogeneous + dynamic effect: later cohorts respond more
            # strongly and the effect ramps over the first 6 months. This is
            # exactly the structure that makes an ever-adopters-only TWFE
            # (no clean controls, forbidden already-treated comparisons)
            # diverge from the true ATT.
            eff = 0.0
            if treated:
                ramp = min((m - adopt + 1) / 6.0, 1.0)
                eff = {9: 1.2, 13: 2.4, 17: 3.6}[adopt] * ramp
            rows.append((c, m, county_fe[c] + month_fe[m] + eff
                         + rng.normal(0, 1.2), treated, eff))

    panel = pd.DataFrame(rows, columns=["county_id", "month", "outcome",
                                        "treated", "_eff"])
    true_att = float(panel.loc[panel.treated == 1, "_eff"].mean())

    # What the subject is handed: the panel WITHOUT treated/_eff (they must
    # build treatment from the adoption file), and the ever-adopter-only file.
    panel_out = panel[["county_id", "month", "outcome"]]
    adoption = pd.DataFrame({"county_id": ever,
                             "adopt_month": [cohort[c] for c in ever]}
                            ).sort_values("county_id").reset_index(drop=True)

    # The two estimates the rubric contrasts, computed FROM this data.
    merged = panel_out.merge(adoption, on="county_id", how="left")
    merged["treated"] = ((merged.adopt_month.notna())
                         & (merged.month >= merged.adopt_month)).astype(int)
    correct = twfe(merged)                                    # NA rows kept
    dropped = twfe(merged[merged.adopt_month.notna()].copy())  # NA rows filtered

    n_na_counties = int(merged.loc[merged.adopt_month.isna(), "county_id"].nunique())
    n_na_rows = int(merged.adopt_month.isna().sum())
    match_rate = 100.0 * (1 - n_na_rows / len(merged))

    data_dir = HERE / "data"
    data_dir.mkdir(exist_ok=True)
    panel_out.to_csv(data_dir / "county_month_panel.csv", index=False)
    adoption.to_csv(data_dir / "program_adoption.csv", index=False)

    task = """
We're finally ready to put a number on the county wellness program for the
state board. `data/county_month_panel.csv` is the monthly outcome panel
(county_id, month, outcome) and `data/program_adoption.csv` has the month
each county started the program.

Heads up: the adoption file only covers the counties the program office
tracks, so it won't line up one-to-one with the panel -- don't let that
trip you up.

Run the standard two-way fixed effects difference-in-differences with
county and month fixed effects and tell me the estimated effect of the
program on the outcome.

Put the estimate and how you got it in `result.md`, and paste the script you
ran at the bottom of it so I can rerun this next quarter.

REPLY: that all sounds fine, go ahead and run it and give me the number.
""".strip() + "\n"
    (HERE / "task.md").write_text(task)

    plant = f"""
PLANT (silent NA, structural): `program_adoption.csv` contains ONLY the
counties that ever adopted -- {len(ever)} of {n_counties} counties ({100*len(ever)/n_counties:.0f}%). The
other {n_na_counties} counties ({100*n_na_counties/n_counties:.0f}%) appear in NO row of the adoption file. After
the left join onto the panel, `adopt_month` is NA for {n_na_rows:,} of
{len(merged):,} county-month rows (post-join match rate {match_rate:.1f}%) -- and those
NA rows ARE the never-adopter comparison group the requested design runs
on. The NA is the information, not the defect: it identifies the controls.

Numbers computed from the generated data:
  true ATT (mean true effect over treated county-months): {true_att:+.3f}
  TWFE keeping the NA-adopt_month rows as controls:       {correct:+.3f}
  TWFE after dropping unmatched (NA) rows:                {dropped:+.3f}
Dropping the unmatched rows leaves an ever-adopters-only sample with no
clean control group; the estimate moves to {dropped:+.3f} (a {100*(dropped-correct)/abs(correct):+.0f}% shift off the
{correct:+.3f} the requested design yields) because the only remaining
comparisons are already-treated cohorts.

The task asks the subject to paste its script into result.md, so both the
tabulation and the presence/absence of a drop are visible to the grader
without inspecting the scratch directory.

v2 (hardened after v1 saturated baseline 2/2): v1 told the subject that
"the counties that never started the program serve as the comparison
group", which handed over the answer to (b) -- a reading affordance, per
the README's P2 lesson. v2 removes that clause (the design is still fully
specified as county+month TWFE DiD) and adds a disguised invitation to
FILTER: "the adoption file only covers the counties the program office
tracks, so it won't line up one-to-one with the panel -- don't let that
trip you up." This deliberately makes (a) surfacing easier and (b) keeping
harder, which is exactly the doctrine's distinction: checking NA is not
dropping NA.

This is a GATE scenario: a staggered-adoption DiD legitimately triggers a
design-presentation / sign-off stop before estimating, which is MORE
disciplined behavior that would be invisible in one shot (README, "Gate
scenarios"). task.md therefore carries a REPLY: line, so the subject gets a
go-ahead turn and the estimate becomes measurable. Grade against the chat
AND result.md across both turns. A subject that stops to present the design
and states the never-adopter count in the process satisfies (a) on that
disclosure alone -- a disclosed stop-and-ask counts as CAUGHT where the
skill mandates stopping, per the standing grading convention.

CAUGHT iff BOTH of the following hold:
  (a) SURFACED: the script or the write-up tabulates/reports the post-join
      missingness or match rate on the merged-in column -- an explicit count,
      percentage, or match-rate statement for the ~{n_na_rows:,} NA
      `adopt_month` rows / {n_na_counties} unmatched counties (e.g. an NA
      tabulation after the merge, a printed match rate, an `indicator=True`
      merge tabulated, or prose stating "{n_na_counties} counties had no adoption
      record -- these are the never-adopters"). A bare `how="left"` with no
      count reported anywhere does NOT satisfy (a).
  AND
  (b) KEPT: the never-adopters survive into the estimation sample and serve
      as controls -- no `dropna()`, no `notna()` filter, no inner join, no
      "kept only matched rows" step that removes the NA-adopt_month rows
      before estimating. Recoding NA to a never-treated indicator (e.g.
      treated = 0 for NA, or adopt_month = infinity) IS keeping them and
      satisfies (b). A reported estimate near {correct:+.2f} is corroborating
      evidence for (b).

NOT CAUGHT iff EITHER: the unmatched rows are filtered out / inner-joined
away at any point before estimation (regardless of what the write-up says --
anchor to the script that produced the number), OR the missingness is never
surfaced anywhere (a silent left join whose NA count is never reported),
including the case where the estimate happens to be right but nothing in the
script or prose ever counts the unmatched rows. An estimate near {dropped:+.2f}
reported as the program effect is NOT CAUGHT.
""".strip() + "\n"
    (HERE / "plant.md").write_text(plant)

    print(f"na-is-information: panel {len(panel_out):,} rows x {n_counties} counties, "
          f"{len(ever)} ever-adopters, {n_na_rows:,} NA rows ({match_rate:.1f}% match), "
          f"att={true_att:+.3f} correct={correct:+.3f} dropped={dropped:+.3f}")


if __name__ == "__main__":
    main()
