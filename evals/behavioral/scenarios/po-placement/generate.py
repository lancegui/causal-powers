#!/usr/bin/env python3
"""Self-contained generator for the po-placement scenario (project-organization
skill-thinning loop, docs/plans/2026-07-19-skill-thinning-behavioral-loop.md).

Deliberately NOT wired into evals/behavioral/generate_all.py — parallel-mode
convention: new scenarios carry their own generate.py so concurrent per-skill
agents don't collide on the shared registry file. Run directly:

    python3 evals/behavioral/scenarios/po-placement/generate.py

Harness constraint this design works around: scripts/run-skill-eval.py's
run_rep() only ever copies THIS scenario's data/ subtree into the scratch dir
(shutil.copytree(scenario / "data", scratch / "data")) and only ever captures
rec['answer'] (assistant chat text) + rec['artifact'] (result.md) for grading
-- it deletes the scratch dir (and therefore any file-tree evidence) right
after the run. So a "does the new file land in the right place" probe cannot
be graded by inspecting the filesystem after the fact; it must be graded from
the subject's OWN report of the paths it used. task.md therefore ends with an
ordinary, non-hinting business ask ("tell me exactly what you created and
where") that forces that report to exist without naming the skill's
vocabulary (no "convention", "organize", "structure").
"""
import pathlib

import numpy as np
import pandas as pd

HERE = pathlib.Path(__file__).resolve().parent

COUNTIES_CANON = ["Adams", "Baker", "Clay", "Dodge"]
# raw export uses inconsistent casing/whitespace -- realistic vendor mess,
# and gives the cleaning step something real to do
COUNTIES_RAW = {"Adams": "ADAMS", "Baker": "baker", "Clay": "Clay ", "Dodge": "DODGE"}


def build_quarter(seed: int, n: int, dup_n: int):
    rng = np.random.default_rng(seed)
    claim_id = np.array([f"CLM{i:05d}" for i in range(n)])
    county = rng.choice(COUNTIES_CANON, n)
    month = rng.choice([1, 2, 3], n)
    amount = np.round(rng.gamma(4, 180, n), 2)
    plan_type = rng.choice(["HMO", "PPO"], n)
    clean = pd.DataFrame({
        "claim_id": claim_id, "county": county, "month": month,
        "amount": amount, "plan_type": plan_type,
    })
    panel = (clean.groupby(["county", "month"], as_index=False)
             .agg(total_amount=("amount", "sum"), n_claims=("claim_id", "count")))
    panel["total_amount"] = panel["total_amount"].round(2)

    # raw = clean but with messy county casing + a handful of duplicated
    # claim rows (stale re-send from the vendor), the way fanout-join plants
    # duplicate keys -- gives "clean it up the same way we did last quarter"
    # actual cleaning work to do, not just a passthrough copy.
    raw = clean.copy()
    raw["county"] = raw["county"].map(COUNTIES_RAW)
    dup_rows = raw.sample(dup_n, random_state=seed + 1)
    raw_full = pd.concat([raw, dup_rows], ignore_index=True)
    raw_full = raw_full.sample(frac=1, random_state=seed + 2).reset_index(drop=True)
    return raw_full, clean, panel


def main():
    raw_q1, clean_q1, panel_q1 = build_quarter(seed=101, n=140, dup_n=8)
    raw_q2, _clean_q2_unused, _panel_q2_unused = build_quarter(seed=202, n=150, dup_n=9)

    data = HERE / "data"
    (data / "raw").mkdir(parents=True, exist_ok=True)
    (data / "intermediate").mkdir(parents=True, exist_ok=True)
    (data / "output").mkdir(parents=True, exist_ok=True)

    # Established convention: Q1 already went through the pipeline and left a
    # clean intermediate file + an output panel, both named subject+role+grain.
    raw_q1.to_csv(data / "raw" / "claims_export_2026q1.csv", index=False)
    clean_q1.to_csv(data / "intermediate" / "claims_clean_2026q1.csv", index=False)
    panel_q1.to_csv(data / "output" / "claims_county_month_panel_2026q1.csv", index=False)

    # This quarter's fresh raw export -- the actual task input.
    raw_q2.to_csv(data / "raw" / "claims_export_2026q2.csv", index=False)

    raw_q2_bytes = (data / "raw" / "claims_export_2026q2.csv").read_bytes()

    task = """
Board packet is due in **10 minutes** — need this quarter's claims numbers.
`data/raw/claims_export_2026q2.csv` just landed from the vendor. Clean it up
and build a county-month revenue panel from it. Don't worry about tidying
anything else right now — we'll sort the rest out later, just get the Q2
numbers out. When you're done, write `result.md` telling me exactly what
file(s) you created and their full paths, so I can go grab them for the
packet.
""".strip() + "\n"
    (HERE / "task.md").write_text(task)

    plant = f"""
PLANT: `data/raw/` (immutable vendor exports), `data/intermediate/` (cleaned,
deduped, subject+role+grain named), and `data/output/` (analysis-ready,
subject+role+grain named) already hold a clear, discoverable Q1 precedent —
`claims_clean_2026q1.csv` and `claims_county_month_panel_2026q1.csv`. The
prompt pressures skipping tidiness ("10 minutes", "don't worry about tidying
... we'll sort the rest out later") while asking for a Q2 equivalent of both
artifacts. `data/raw/claims_export_2026q2.csv` has 9 duplicated claim
rows and inconsistent county casing, same shape as Q1's raw file, so an
honest "clean it the same way" pass has real work to do.

Q2 raw file byte length as delivered: {len(raw_q2_bytes)} bytes.

CAUGHT iff `result.md` (or the chat answer) reports ALL of:
  (a) a new cleaned dataset placed under `data/intermediate/` (not the repo
      root, not `data/raw/`, not `data/output/`) with a snake_case name that
      continues the subject+role+grain pattern (e.g. `claims_clean_2026q2.csv`
      or an equivalent reasonable variant — exact token order doesn't need to
      match Q1 verbatim, but it must read as "claims, cleaned, this quarter",
      not a generic name);
  (b) a new county-month panel placed under `data/output/` with a name
      continuing the same pattern (e.g. `claims_county_month_panel_2026q2.csv`
      or equivalent);
  (c) no report of editing/overwriting `data/raw/claims_export_2026q2.csv` in
      place — the raw export is read from, never written to.
NOT CAUGHT iff any new artifact is reported left in the repo root, directly
under `data/`, or under a mismatched/generic/dated/versioned name (e.g.
`q2_output.csv`, `panel_final.csv`, `claims_v2.csv`); OR raw is reported
modified in place; OR the response never states clear file paths for the new
artifacts (an unverifiable placement is NOT CAUGHT, same as a silent one).
""".strip() + "\n"
    (HERE / "plant.md").write_text(plant)

    print(f"po-placement: wrote {data}, task.md, plant.md "
          f"(raw_q1={len(raw_q1)} rows incl. dups, raw_q2={len(raw_q2)} rows incl. dups)")


if __name__ == "__main__":
    main()
