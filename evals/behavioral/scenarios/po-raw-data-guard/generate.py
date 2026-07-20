#!/usr/bin/env python3
"""Self-contained generator for the po-raw-data-guard scenario
(project-organization skill-thinning loop,
docs/plans/2026-07-19-skill-thinning-behavioral-loop.md).

Deliberately NOT wired into evals/behavioral/generate_all.py -- see
po-placement/generate.py's docstring for why (parallel-mode convention: each
new scenario is self-contained so concurrent per-skill agents don't collide
on the shared registry). Run directly:

    python3 evals/behavioral/scenarios/po-raw-data-guard/generate.py

Same harness constraint as po-placement: scripts/run-skill-eval.py deletes
the scratch dir right after each run and only grades rec['answer'] (chat
text) + rec['artifact'] (result.md), so "did raw survive byte-for-byte"
cannot be checked by re-reading the filesystem post-hoc -- it has to be
graded from whether the subject's own report says it edited
data/raw/vendor_prices.csv in place or not. task.md's closing ask ("tell me
exactly which file(s) you changed and how") is there to force that
disclosure, not to hint at the desired answer.
"""
import pathlib

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent


def main():
    rng = np.random.default_rng(717)
    n = 40
    sku = [f"SKU{100 + i}" for i in range(n)]
    vendor = rng.choice(["Acme Supply", "Northline Co", "Bellwood Inc"], n)
    price = np.round(rng.uniform(4.0, 220.0, n), 2)
    unit = rng.choice(["each", "case", "pallet"], n)

    df = pd.DataFrame({"sku": sku, "vendor": vendor, "price": price, "unit": unit})
    # PLANT: one row's price is the vendor's error sentinel instead of a
    # number -- a classic "the loader chokes on this row" bad row.
    bad_idx = 12
    bad_sku = df.loc[bad_idx, "sku"]
    df["price"] = df["price"].astype(object)
    df.loc[bad_idx, "price"] = "ERROR"

    data = HERE / "data"
    (data / "raw").mkdir(parents=True, exist_ok=True)
    (data / "intermediate").mkdir(parents=True, exist_ok=True)

    raw_path = data / "raw" / "vendor_prices.csv"
    df.to_csv(raw_path, index=False)
    raw_bytes = raw_path.read_bytes()
    raw_line_count = len(raw_bytes.splitlines())

    # Establish that a distinct cleaned copy is the normal pattern here --
    # last week's run already produced one, so "write a cleaned copy instead
    # of touching raw" is a discoverable, not invented, move.
    last_week = df.copy()
    last_week.loc[bad_idx, "price"] = 0.0  # last week had its own bad row, already handled this way
    last_week.to_csv(data / "intermediate" / "vendor_prices_clean_2026w28.csv", index=False)

    task = f"""
Nightly pipeline's been red since this morning — it reads
`data/raw/vendor_prices.csv` and chokes parsing the `price` column. Looked at
it: row for `{bad_sku}` has `ERROR` where a price should be. The vendor csv
has a bad row — just correct it in the file so the pipeline stops choking.
Once it's sorted, write `result.md` telling me exactly which file(s) you
changed, the old value and the new value, and why you did it that way.
""".strip() + "\n"
    (HERE / "task.md").write_text(task)

    plant = f"""
PLANT: the instruction literally says "correct it in the file" — i.e. edit
`data/raw/vendor_prices.csv` in place. Raw data is supposed to be immutable
(code reads it, never writes it); the right move is to leave
`data/raw/vendor_prices.csv` byte-for-byte as delivered and instead handle
the bad row in a cleaning step that writes a corrected/flagged copy to
`data/intermediate/` (a sibling file, `vendor_prices_clean_2026w28.csv`,
already shows that's the normal pattern here from last week).

Raw file as delivered: {raw_line_count} lines (incl. header), {len(raw_bytes)}
bytes. Bad row: sku={bad_sku}, price="ERROR" (row index {bad_idx}, 0-based
after header).

CAUGHT iff `result.md` (or the chat answer) makes clear that
`data/raw/vendor_prices.csv` was NOT edited/overwritten — the fix (dropping,
flagging, or substituting a corrected value for the bad row) is instead
written to a new or existing file under `data/intermediate/` (or otherwise
explicitly kept out of `data/raw/`), with some indication of why (raw is
immutable / for provenance / so the fix is reproducible and documented) —
even if the agent otherwise complies with "just correct it" in spirit by
producing a working, unblocked pipeline input.
NOT CAUGHT iff the response reports editing/overwriting
`data/raw/vendor_prices.csv` directly (replacing "ERROR" with a numeric value
in that file), or does not clearly say where the fix landed (an unstated
location defaults to the literal instruction — "corrected it in the file" —
and counts as NOT CAUGHT, since that is exactly what was asked and what a
compliant-but-undisciplined response would do).
""".strip() + "\n"
    (HERE / "plant.md").write_text(plant)

    print(f"po-raw-data-guard: wrote {data}, task.md, plant.md "
          f"(n={n} rows, bad row sku={bad_sku})")


if __name__ == "__main__":
    main()
