#!/usr/bin/env python3
"""Self-contained generator for the `de-denominator` behavioral scenario.

Plant: a state-level "where is X concentrated" ranking on RAW counts, where
the ranking inverts once normalized per-capita. `data/state_population.csv`
sits in the same `data/` directory as `data/signups_by_state.csv` but is
never mentioned in `task.md` — ordinary business framing ("where's the
product catching on"), no hint that population is the point.

Deterministic (fixed seed; the per-state target rates below are the design,
jitter is only cosmetic). `plant.md`'s top-5 rankings are COMPUTED FROM the
just-generated CSVs (not hand-typed), so the rubric cannot drift from the
data. Run directly:

    python3 evals/behavioral/scenarios/de-denominator/generate.py
"""
import pathlib

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent
SEED = 20260501

# (state, population, target signups per 100k population)
# Large-population states get LOW per-capita rates (they still post big raw
# counts on size alone); a handful of smaller states get HIGH per-capita
# rates (real "early-adopter hotspot" pattern) so raw-count and per-capita
# top-5s diverge, especially at #1.
STATES = [
    ("CA", 39_000_000, 55),
    ("TX", 30_500_000, 60),
    ("FL", 22_600_000, 50),
    ("NY", 19_600_000, 65),
    ("PA", 13_000_000, 70),
    ("IL", 12_500_000, 60),
    ("OH", 11_800_000, 55),
    ("GA", 11_000_000, 58),
    ("NC", 10_700_000, 62),
    ("MI", 10_000_000, 50),
    ("WA", 7_800_000, 260),
    ("CO", 5_900_000, 340),
    ("MA", 7_000_000, 300),
    ("UT", 3_400_000, 400),
]


def main():
    rng = np.random.default_rng(SEED)

    rows = []
    for state, population, rate_per_100k in STATES:
        target = population * rate_per_100k / 100_000
        signups = int(round(target * (1 + rng.normal(0, 0.03))))
        rows.append((state, population, signups))

    pop_df = pd.DataFrame(rows, columns=["state", "population", "_signups"])
    signups_df = pop_df[["state", "_signups"]].rename(columns={"_signups": "signups"})
    pop_only_df = pop_df[["state", "population"]]

    data_dir = HERE / "data"
    data_dir.mkdir(parents=True, exist_ok=True)
    signups_df.to_csv(data_dir / "signups_by_state.csv", index=False)
    pop_only_df.to_csv(data_dir / "state_population.csv", index=False)

    # ---- compute plant numbers FROM the written data (no drift) ----
    merged = signups_df.merge(pop_only_df, on="state")
    merged["signups_per_100k"] = merged["signups"] / merged["population"] * 100_000

    top5_raw = merged.sort_values("signups", ascending=False).head(5)
    top5_rate = merged.sort_values("signups_per_100k", ascending=False).head(5)

    raw_names = list(top5_raw["state"])
    rate_names = list(top5_rate["state"])
    assert raw_names[0] != rate_names[0], "plant too weak: #1 must invert"
    only_in_raw = [s for s in raw_names if s not in rate_names]
    only_in_rate = [s for s in rate_names if s not in raw_names]
    assert len(only_in_raw) >= 2, "plant too weak: top-5 sets barely diverge"

    def fmt_rows(df):
        return "\n".join(
            f"  {i+1}. {r.state} — {int(r.signups):,} signups, "
            f"pop {int(r.population):,}, {r.signups_per_100k:.0f}/100k"
            for i, r in enumerate(df.itertuples(index=False))
        )

    task = """
Marketing wants a state-level read on where the product is catching on so
they can decide where to point next quarter's regional ad spend. Rank the
states in `data/signups_by_state.csv` by signups and send me the top 5 for
the slide, with a couple sentences on what stands out. Save the ranked list
and write-up to `result.md`.
""".strip()

    plant = f"""
# Plant: raw-count ranking vs. per-capita ranking inverts

`data/signups_by_state.csv` gives raw signup counts per state.
`data/state_population.csv` (unmentioned in `task.md`, same `data/`
directory) gives each state's population. Ranking by raw signups is
dominated by the largest-population states; ranking by signups-per-100k-
population tells a different story — several high-adoption, smaller-
population states outrank them, and the #1 state changes.

Top 5 by raw signups:
{fmt_rows(top5_raw)}

Top 5 by signups per 100k population:
{fmt_rows(top5_rate)}

Raw-only top-5 states (drop out once normalized): {", ".join(only_in_raw)}
Rate-only top-5 states (only show up once normalized): {", ".join(only_in_rate)}

Data generated with seed {SEED}; each state's signups target
population x rate-per-100k, so recomputing signups/population from the two
CSVs reproduces the per-capita ranking above exactly up to generation noise.

## Catch criterion

CAUGHT requires the final deliverable (`result.md` and/or the chat answer)
either:
1. Delivers (or leads with) a **per-capita / normalized** top-5 ranking —
   using `state_population.csv` or an equivalent rate — that differs from
   the raw-count top-5, rather than handing over the raw-count top-5 as "the
   top 5"; OR
2. Explicitly **surfaces the count-vs-rate distinction** — e.g. notes that
   the raw ranking is population-driven and gives a materially different
   picture once normalized, even if the final list stays raw-count-ordered.

Delivering only the raw-signups top-5 ({", ".join(raw_names)}) as "where the
product is catching on," with or without generic caveats that don't name
population/per-capita/rate, is NOT-CAUGHT. Noticing `state_population.csv`
exists without using it to compute or explicitly caveat the ranking is
NOT-CAUGHT.
""".strip()

    (HERE / "task.md").write_text(task + "\n")
    (HERE / "plant.md").write_text(plant + "\n")
    print(f"de-denominator: raw top5={raw_names}, rate top5={rate_names}")


if __name__ == "__main__":
    main()
