---
name: project-organization
description: Use when finishing a piece of analysis and about to commit or push, when a project directory has accreted intermediate or diagnostic files and it's unclear what is a deliverable versus scratch, when setting up or reorganizing a research repository, or when asked to clean up the directory, organize the repo, standardize naming, make a project reproducible for collaborators, or decide what folder structure to use. Also fires throughout the work — when creating a new script, dataset, table, or figure, place and name it per the project's structure instead of dumping it in the root or a flat folder to sort out later. For empirical and structural economics research projects across R, Julia, Python, and Stata, organized around the paper they produce rather than a single-language product layout. Triggers on "clean up the repo", "organize the project", "what should the folder structure be", "before I push this", "standardize the naming", or "make this reproducible for a collaborator".
---

# Project Organization

## Overview

A research repository has one destination — the **paper** — and one test: six months in, a collaborator (or future you) opens it and must answer fast — *what is a finished result, what is scratch, and how was each number produced?* A directory that has accreted `fect_diagnostics.csv`, a dozen `pe_*.png` check-plots, and three half-named panels alongside the code answers none of that. Organization is not tidiness for its own sake; it is what makes the work **reproducible and legible to someone who wasn't in the conversation** — the clean-diff discipline of `analysis-craft`, one level up at the directory.

**Core principle:** organize the project around the paper and its pipeline; place and name every artifact so its **role** (deliverable / intermediate / raw) and its **producer** are obvious; and at the end of a workflow — *before you commit* — tidy so the repo shows deliverables and code, not scratch.

**This is not Cookiecutter Data Science.** That template targets a single-language (Python) ML product. A research project is **polyglot** (R / Julia / Python / Stata coexisting), **paper-centric**, and **replication-graded**. Borrow what Cookiecutter gets right — immutable gitignored data, reproducible outputs regenerated rather than committed, numbered ordering, secrets in a gitignored `.env`, a README — and add what it lacks (last section).

## The structure

```
project-root/
├── README.md             # the map: what this is, data provenance, one-command reproduction
├── paper/                # the destination everything feeds
│   ├── paper.tex|.qmd|.Rmd · appendix · refs.bib
│   └── tables/ figures/  # FINAL tables/figures as they appear in the paper (tracked)
├── data/
│   ├── raw/              # original, immutable, never edited by code   (gitignored)
│   ├── intermediate/     # cleaned / merged working data               (gitignored, reproducible)
│   └── output/           # analysis-ready datasets the analysis reads  (gitignored, reproducible)
├── code/                 # the pipeline, ordered by the paper's stages (R/Julia/Python/Stata)
│   ├── 00_data/          # raw → intermediate → output
│   ├── 01_stylized_facts/# descriptives, summary tables, motivating figures
│   ├── 02_main/          # main results      ── subject subfolders: did_mortality/ did_crime/ …
│   ├── 03_estimation/    # (structural) estimate model primitives
│   ├── 04_montecarlo/    # (structural) recovery of known parameters
│   ├── 05_robustness/    # robustness · placebo · sensitivity
│   ├── 06_counterfactual/# (structural) counterfactual scenarios
│   └── lib/              # shared functions used across stages
├── results/              # generated artifacts staged before the paper
│   ├── tables/ figures/  #   canonical outputs (tracked)
│   └── diagnostics/      # check plots, recovery logs — scratch       (gitignored)
├── docs/                 # MODEL_CARD.md · pre-analysis-plan.md · LESSONS.md
├── sandbox/              # exploratory throwaway, clearly NOT a deliverable (gitignored)
└── .gitignore
```

**Adapt it.** A reduced-form project drops the structural stages (`03_estimation`, `04_montecarlo`, `06_counterfactual`); a single-outcome project drops the subject subfolders; the pipeline folder may be `code/`, `scripts/`, or `analysis/`. **Read the repo's `README.md` first and follow the conventions it already has** — impose this layout only where there are none. The point isn't this exact tree; it's the *separation* (code ≠ data ≠ outputs ≠ scratch) and the paper-centric staging.

## Two axes — stage × subject

Organize **stage-first** (the paper's sections: data → stylized facts → main → estimation → MC → robustness → counterfactual), and within a stage that spans several outcomes, use **subject subfolders** (`code/02_main/did_mortality/`, `code/02_main/did_crime/`). The anti-pattern — the one a cluttered `analysis/` falls into — is mixing **code, data, and generated outputs in one flat folder**, and crossing the stage and subject axes inconsistently (`fect_crime`, `bjs_mortality`, `compare_services` all at one level with CSVs and PNGs between them). Pick stage-then-subject and keep code, data, and outputs in their own trees.

## Naming conventions — standardize them

A filename should announce its order, its role, and what it produces or shows. Lowercase, `snake_case`, no spaces.

- **Scripts:** `NN_verb_subject.ext`, numbered for run order within their folder — `01_clean_mortality.R`, `02_build_county_panel.py`, `03_estimate_blp.jl`. The numbers are what a master script runs in sequence.
- **Subject / analysis folders:** `method_subject` — `did_mortality/`, `event_study_crime/`, `blp_demand/`.
- **Output artifacts:** named by what they show, traceable to their producer — `tab_main_did_mortality.tex`, `fig_eventstudy_mortality.pdf`, `tab_mc_recovery.tex`.
- **Data:** by content and grain — `county_year_panel.parquet`, `facility_panel.parquet`.
- **Forbidden:** dates or `final` / `FINAL` / `v2` in names (git versions, not the filename); two files that differ only by a suffix nobody can decode; spaces and capitals.

## The data lifecycle

`raw → intermediate → output`, one direction only. **`raw/` is immutable** — code never writes to it; if a fix is needed, it happens in a cleaning script that reads `raw/` and writes `intermediate/`. All three are **gitignored**: data is reproducible from `code/` + `raw/` (and `raw/` is usually too large or too sensitive to track), so you regenerate it, you don't commit it. Document in the README where `raw/` comes from (the provenance) so a replicator can obtain it.

## Git — what's tracked, what's ignored

The repo a collaborator sees on GitHub should be **code + manuscript + small canonical results**, not the working mess.

- **Gitignore:** `data/` (raw/intermediate/output), `results/diagnostics/`, `sandbox/`, generated logs, caches, and **secrets** (`.env`, credentials, API keys) — always.
- **Track:** `code/`, `paper/` (incl. its final tables/figures), `docs/`, `README.md`, `.gitignore`, and the canonical `results/tables` & `results/figures` that feed the paper. A *reproducible* output you can regenerate cheaply → gitignore it; an *expensive-to-recompute* artifact → track it **and** document how it's made.
- **One-command reproduction:** a master script / `Makefile` / `run_all` that runs the pipeline in order (data → … → paper). This is the replication-package standard, and it's also the proof the structure is real.
- Keep the tree clean — a `git status` full of untracked scratch is the smell this skill exists to remove.

## Enforce it throughout — tidy before git

Two moments, one discipline:

- **Throughout (placement on creation):** when you write a new script, dataset, table, or figure, put it in its folder and name it per convention **then**, not "in the root for now, I'll sort it later." Later never comes, and the flat dump is what you're cleaning up here.
- **At the end, before you commit (the cleanup pass):** this is the trigger. Run it when a workflow finishes and before `git add`:
  1. **Read the `README.md`** to learn this project's conventions; align to them.
  2. **Inventory** what the workflow touched or produced.
  3. **Classify** each file: *deliverable* → its correct folder; *intermediate / reproducible* → gitignore (regenerate on demand); *scratch / diagnostic* → `sandbox/` or `results/diagnostics/` (gitignored) or delete; *raw / input* → never touch; *secret* → gitignore immediately.
  4. **Propose** the moves, renames, gitignore additions, and deletions — aligned to the structure — and update `.gitignore`.

**Safety — this is destructive-adjacent, so it inherits the checkpoint discipline.** **Offer; don't delete on your own.** Deleting or moving files the user may want is a consequential action — surface the plan and get approval (`analysis-checkpoints`). **Never touch `raw/` or any input data.** Prefer **gitignore or move over delete**; prefer moving a doubtful file to `sandbox/` over removing it. Distinguish *reproducible* (cheap to regenerate → safe to drop) from *expensive* (keep and document). When in doubt, leave it and flag it.

## What Cookiecutter Data Science misses for research

Worth knowing so you take its good parts and not its shape:

- **The paper is the destination.** Cookiecutter has a generic `reports/`; a research repo is organized so every table and figure traces to the manuscript section it lands in.
- **Replication-grade reproduction.** One master script, documented data provenance, deterministic seeds — the AEA / replication-package bar, not just "notebooks exist."
- **Stage-by-paper-section**, not generic numbered notebooks: stylized facts / main / robustness / counterfactual are first-class.
- **Structural stages + the model card.** Estimation, Monte-Carlo recovery, and counterfactual scenarios are folders; the living `docs/MODEL_CARD.md` is part of the structure (`structural-estimation`).
- **Polyglot.** R, Julia, Python, and Stata coexist, organized by stage/subject — never by language. Cookiecutter assumes one Python package.
- **A sandbox** clearly fenced off from deliverables, so exploration doesn't masquerade as result.

## Red flags — STOP

- Code, data, and generated outputs sharing one flat folder (the `analysis/` dump).
- Diagnostic CSVs and one-off check-plots committed alongside the canonical figures, with nothing marking which is which.
- `raw/` data edited in place, or written to by analysis code.
- Data, secrets (`.env`, keys), or large regenerable outputs tracked in git.
- Filenames with dates, `final`/`v2`, spaces, or capitals; two near-identical names nobody can disambiguate.
- No master script — "the results are in here somewhere, run them in the right order" is not reproduction.
- About to **delete** files in a cleanup without surfacing the plan, or about to touch `raw/`.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "I'll dump it in the root and organize later." | Later is never. The flat dump is exactly the mess this skill cleans up; place it now. |
| "Commit the outputs so collaborators don't have to rerun." | Outputs are reproducible from code — gitignore and regenerate. Track only canonical artifacts that are expensive to recompute, and document how. |
| "Dates and v2 in the filename track versions." | Git tracks versions. `results_final_v3_REALLY.csv` is how you lose the canonical one. One name per artifact. |
| "Cookiecutter is the standard, just use it." | It's the standard for single-language ML products. A polyglot, paper-centric research repo needs the paper, replication, and structural stages it doesn't have. |
| "Let me just delete the scratch to clean up." | Deleting files the user might want is their call. Offer the plan; prefer gitignore/move; never touch raw data. |

## Relationship to sibling skills

- This is `analysis-craft`'s legibility discipline scaled from the **diff** to the **directory** — both ask "could a collaborator who wasn't here navigate this?"
- The cleanup pass fires at the **done** boundary alongside **`result-verification`** (freeze the verified result *into its correct folder*) and the phase-boundary tidy-and-compact in **`executing-analysis-plans`**.
- The structural stages and the living `docs/MODEL_CARD.md` come from **`structural-estimation`**; the `docs/pre-analysis-plan.md` from **`pre-analysis-plan`**; `docs/LESSONS.md` from **`result-verification`**.
- Deleting or moving files is a consequential action — route it through **`analysis-checkpoints`** (offer, don't do).

## The bottom line

```
Organized project  →  paper-centric stages, subject subfolders, data raw/intermediate/output gitignored,
                      standardized names, one-command reproduction, scratch tidied before commit
Otherwise          →  a folder only the author can navigate, and only this week
```
