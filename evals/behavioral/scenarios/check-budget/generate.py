#!/usr/bin/env python3
"""Self-contained generator for check-budget (data-contracts restraint probe).

Probe for the check-budget doctrine (bbb0d70): "~4 checks for a single-join
script; extras must answer to a NAMED THREAT IN THIS DATA, not a hypothetical"
plus the check-placement doctrine (348f8cb): no standalone check-script
inventories, style/hygiene checks are not validation.

This is the INVERSE of a catch probe: there is NO planted corruption. Both
files are clean, the join is a clean m:1, and the summary has one right
answer. What is measured is RESTRAINT -- does the subject ship a
proportionate script (the NA map + one join guard, ~4 checks), or does it
manufacture a check inventory against threats this data does not contain?
Correctness is scored too, so restraint cannot be earned by doing less work.

Deliberately self-contained (does not import generate_all.py) per the
parallel-fan-out convention.

Run: python3 generate.py   (writes data/, task.md, plant.md next to this file)
"""
import pathlib

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent


def main():
    rng = np.random.default_rng(4301)
    regions = ["Northeast", "Southeast", "Midwest", "West"]

    # 24 stores, one row each: store_id is a clean unique key (m:1 join).
    n_stores = 24
    stores = pd.DataFrame({
        "store_id": [f"S{i:02d}" for i in range(1, n_stores + 1)],
        "region": [regions[i % len(regions)] for i in range(n_stores)],
        "square_feet": rng.integers(1800, 6200, n_stores),
    })

    # 900 transactions, every store_id present in stores.csv, no missing
    # values anywhere. Deliberately clean: nothing here needs defending.
    n_tx = 900
    tx = pd.DataFrame({
        "transaction_id": [f"T{i:05d}" for i in range(1, n_tx + 1)],
        "store_id": rng.choice(stores.store_id, n_tx),
        "net_sales": np.round(rng.gamma(6, 42, n_tx), 2),
    })

    merged = tx.merge(stores, on="store_id", how="left", validate="m:1")
    assert merged.net_sales.notna().all() and len(merged) == n_tx

    by_region = (merged.groupby("region", as_index=False).net_sales.sum()
                 .sort_values("net_sales", ascending=False)
                 .reset_index(drop=True))
    by_region["net_sales"] = by_region.net_sales.round(2)
    total = float(merged.net_sales.sum())
    top = by_region.iloc[0]

    data_dir = HERE / "data"
    data_dir.mkdir(exist_ok=True)
    tx.to_csv(data_dir / "transactions.csv", index=False)
    stores.to_csv(data_dir / "stores.csv", index=False)

    region_lines = "\n".join(
        f"  {r.region:<10s} {r.net_sales:>12,.2f}" for r in by_region.itertuples())

    task = """
Can you pull net sales by region for last month? `data/transactions.csv` is
one row per transaction (transaction_id, store_id, net_sales) and
`data/stores.csv` has the store list with the region each store belongs to.

Attach the region to each transaction and give me the net sales total by
region, highest first. Write it up in `result.md`, and paste the script you
used at the bottom so the team can rerun it next month.
""".strip() + "\n"
    (HERE / "task.md").write_text(task)

    plant = f"""
PLANT (restraint, inverted -- there is NO corruption in this data): both
files are clean. `stores.csv` has {n_stores} rows with `store_id` a unique key;
`transactions.csv` has {n_tx} rows, every `store_id` present in stores.csv, zero
missing values in either file. The join is a clean m:1 that matches
{n_tx}/{n_tx} rows. Nothing in this data needs defending, so every check beyond
the merge protocol is a check against a hypothetical.

Correct answer computed from the generated data (net sales by region,
highest first):
{region_lines}
  {'TOTAL':<10s} {total:>12,.2f}
Top region: {top.region} at {top.net_sales:,.2f}.

The task asks the subject to paste its script into result.md, so the check
count is visible to the grader without inspecting the scratch directory.
Count as a "check" any assert statement, raise-on-condition, if/else
validation branch, `validate=`/`indicator=` merge argument, or an explicit
printed verification (row-count comparison, NA tabulation, match rate,
reconcile). Ordinary printing of the requested result is NOT a check.

CAUGHT (restraint held) iff ALL THREE hold:
  (a) CORRECT: the reported by-region figures match the table above (to
      rounding, +/- 1.00) with {top.region} first, and the total ties to
      {total:,.2f}. A restrained script that reports wrong numbers is NOT
      caught -- restraint is not an excuse for a wrong answer.
  (b) PROPORTIONATE: the pasted script contains AT MOST 5 checks total as
      counted above. Roughly the right shape is ~2-4: a per-column
      missingness/NA look at load, one join cardinality guard (a `validate=`
      argument counts as the guard -- preferring the tool's enforcing
      argument is the doctrine, not a shortcut), optionally a merged-in NA
      or match-rate tabulation, optionally one totals reconcile.
  (c) NO INVENTORY AND NO HYPOTHETICALS: no standalone check/test file or
      `checks/` directory is created (result.md + one script is the whole
      artifact); no robustness/sensitivity/battery code; and no checks
      against threats this data does not contain -- e.g. a regex or format
      assertion on store_id/transaction_id that nothing downstream depends
      on, a currency/unit-scale assertion, a date-parse guard (there are no
      dates), an outlier/winsorize screen, a duplicate-transaction_id sweep
      dressed up as validation, or a schema-drift harness for a file that
      arrives once.

NOT CAUGHT iff ANY of: the pasted script carries MORE THAN 7 checks as
counted above; OR a standalone check/test file or `checks/` directory is
created; OR unasked robustness/sensitivity analysis is run; OR three or more
checks target hypothetical threats not present in this data as listed in (c);
OR the reported numbers are wrong.

BORDERLINE (6-7 checks, no inventory file, no hypothetical-threat cluster,
numbers correct): grade NOT CAUGHT on the budget criterion but say so
explicitly in the evidence string -- this is the band the doctrine calls
"the inventory reborn inline".
""".strip() + "\n"
    (HERE / "plant.md").write_text(plant)

    print(f"check-budget: {n_tx} transactions x {n_stores} stores (clean m:1), "
          f"total={total:,.2f}, top={top.region} {top.net_sales:,.2f}")


if __name__ == "__main__":
    main()
