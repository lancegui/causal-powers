---
name: project-organization
description: Use when finishing a piece of analysis and about to commit or push, when a project directory has accreted intermediate or diagnostic files and it's unclear what is a deliverable versus scratch, when setting up or reorganizing a research repository, or when asked to clean up the directory, organize the repo, standardize naming, make a project reproducible for collaborators, or decide what folder structure to use. Also fires throughout the work — when creating a new script, dataset, table, or figure, place and name it per the project's structure instead of dumping it in the root or a flat folder to sort out later. For empirical and structural economics research projects across R, Julia, Python, and Stata, organized around the paper they produce. Triggers on "clean up the repo", "organize the project", "what should the folder structure be", "before I push this", "standardize the naming", or "make this reproducible for a collaborator".
---

# Project Organization

## Overview

A research repository has one destination — the **paper** — and one test: six months in, a collaborator (or future you) opens it and must answer fast — *what is a finished result, what is scratch, and how was each number produced?* Organization is what makes the work reproducible and legible to someone who wasn't in the conversation: `analysis-craft`'s clean-diff discipline, scaled to the directory.

**Core principle:** organize around the paper and its pipeline; place and name every artifact so its role (deliverable / intermediate / raw) and its producer are obvious; and at the end of a workflow, before you commit, tidy so the repo shows deliverables and code, not scratch.

## The structure

```
project-root/
├── README.md             # the map: what this is, data provenance, one-command reproduction
├── paper/                # the destination — manuscript + the FINAL tables/figures it uses
├── data/
│   ├── raw/              # original, immutable — code reads it, never writes it
│   ├── intermediate/     # cleaned / merged working data (reproducible)
│   └── output/           # analysis-ready datasets the analysis reads
│       └── mortality/ crime/ …     # subject subfolders where the project spans several
├── code/                 # pipeline ordered by paper stage (R / Julia / Python / Stata)
│   ├── 00_data/          # raw → intermediate → output    ── subjects: mortality/ crime/ …
│   ├── 01_stylized_facts/
│   ├── 02_main/          #                                 ── subjects: did_mortality/ did_crime/ …
│   ├── 03_estimation/ 04_montecarlo/ 05_robustness/ 06_counterfactual/   # (structural)
│   └── lib/              # shared functions
├── results/              # generated artifacts — tables/ figures/ (canonical) · diagnostics/ (scratch)
├── docs/                 # MODEL_CARD.md · pre-analysis-plan.md · LESSONS.md
├── sandbox/              # exploratory throwaway, clearly not a deliverable
└── .gitignore
```

Adapt it: reduced-form projects drop the structural stages; single-subject projects drop the subject subfolders; the pipeline folder may be `code/`, `scripts/`, or `analysis/`. **Read the repo's `README.md` first and follow the conventions it already has** — impose this only where there are none. The point is the separation (**code ≠ data ≠ outputs ≠ scratch**) and the paper-centric staging, organized **stage-first with subject subfolders throughout — the data stage included.**

## Naming — standardize it

A filename announces its order, role, and what it produces. Lowercase, `snake_case`, no spaces.

- **Scripts:** `NN_verb_subject` — `01_clean_mortality.R`, `02_build_county_panel.py` (numbers = run order).
- **Subject folders:** `method_subject` — `did_mortality/`, `blp_demand/`.
- **Outputs:** named by what they show, traceable to their producer — `tab_main_did_mortality.tex`, `fig_eventstudy_mortality.pdf`.
- **Data:** content + grain — `county_year_panel.parquet`.
- **Banned:** dates, `final`/`v2`, spaces, capitals, and two names that differ only by an undecodable suffix. Git versions; the filename doesn't.

## Data — raw → intermediate → output

One direction. `raw/` is **immutable**: code reads it and never writes it; a fix happens in a cleaning script that writes `intermediate/`. The data folders carry subject subfolders when the project spans several.

**Track the data by default** — a research repo should ship what a replicator needs. Gitignore only two things: data that is **sensitive and can't be shared** (PII, restricted, licensed), and files **past GitHub's ~100 MB limit**. For a file that is merely too big (not sensitive), don't drop it — **convert it to a compact format (parquet, or compressed tsv) first**; that usually clears the limit and keeps it tracked and replication-ready. Whatever you genuinely can't ship, document its provenance in the README so a replicator can obtain it.

## Git — tracked vs. ignored

The repo a collaborator sees should be code + manuscript + results + the shareable data.

- **Track:** `code/`, `paper/` (incl. final tables/figures), `docs/`, `README`, and the `data/` and `results/` that are shareable and under the size limit.
- **Gitignore:** secrets (`.env`, keys) **always**; sensitive data; oversized files (after trying to shrink them); `results/diagnostics/`, `sandbox/`, caches, logs.
- **One-command reproduction:** a master script / `Makefile` that runs the pipeline in order (data → … → paper). It's the replication standard and the proof the structure is real.

## Enforce throughout, tidy before git

- **Throughout:** when you create a script, dataset, table, or figure, put it in its folder and name it by convention *then* — not "in the root for now."
- **Before you commit (the trigger):** read the README's conventions; inventory what the workflow produced; classify each file — deliverable → its folder; intermediate/reproducible → keep or gitignore; scratch/diagnostic → `sandbox/` or `results/diagnostics/` or delete; sensitive/oversized → shrink-or-gitignore; secret → gitignore now. Propose the moves/renames/gitignore/deletes; update `.gitignore`.
- **Safety:** offer, don't delete on your own — deleting files the user may want is a checkpoint (`analysis-checkpoints`). **Never touch `raw/`.** Prefer gitignore/move over delete; move a doubtful file to `sandbox/` rather than removing it.

## Red flags — STOP

- Code, data, and generated outputs in one flat folder.
- Diagnostic CSVs / check-plots committed beside the canonical figures, with nothing marking which is which.
- `raw/` edited in place, or written to by analysis code.
- Secrets tracked in git; a large file gitignored without first trying to shrink it to parquet/tsv.
- Filenames with dates, `final`/`v2`, spaces, or capitals.
- No master script — "run them in the right order, they're in here somewhere" is not reproduction.
- About to delete files in a cleanup without surfacing the plan, or about to touch `raw/`.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "I'll dump it in the root and organize later." | Later never comes; the flat dump is the mess this cleans up. Place it now. |
| "Gitignore all the data to be safe." | A research repo should ship the data a replicator needs. Ignore only the sensitive or the oversized — and shrink the oversized to parquet/tsv first. |
| "Dates and `v2` track versions." | Git does. `results_final_v3_REALLY.csv` is how you lose the canonical one. One name per artifact. |
| "Just delete the scratch to tidy up." | Deleting files the user might want is their call. Offer; prefer gitignore/move; never touch `raw/`. |

## Relationship to sibling skills

- This is `analysis-craft`'s legibility, scaled from the diff to the directory.
- The cleanup fires at the **done** boundary with **`result-verification`** (freeze the verified result into its folder) and the phase-boundary tidy in **`executing-analysis-plans`**.
- The structural stages and `docs/MODEL_CARD.md` come from **`structural-estimation`**; `docs/pre-analysis-plan.md` from **`pre-analysis-plan`**; `docs/LESSONS.md` from **`result-verification`**.
- Deleting or moving files is consequential — route it through **`analysis-checkpoints`**.

## The bottom line

```
Organized  →  paper-centric stages × subject subfolders, raw→intermediate→output, shareable data
              tracked (only sensitive/oversized excluded, big files shrunk to parquet/tsv),
              standardized names, one-command reproduction, scratch tidied before commit
Otherwise  →  a folder only the author can navigate, and only this week
```
