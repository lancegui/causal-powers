---
name: data-contracts
description: >-
  Use when computing, transforming, cleaning, joining, merging, aggregating, reshaping, or modeling ANY result from data — before you trust a number, a table, a model metric, or a chart. Establishes data contracts and invariants up front, validates assumptions before building on them, asserts join cardinality before every merge, and freezes validated results as regression baselines. Use this whenever you load a dataset, write a transform or cleaning step, do a join or group-by, fit a model, or are about to report a figure — even if the user only says "analyze this", "what's the trend", "clean this up", "merge these two files", or "build this metric" without ever mentioning tests or validation — in R, Julia, Python, or Stata. NOT the owner of the cleaning PHASE: building a dataset end-to-end is data-preparation, which calls this skill per step.
---

# Data Contracts

## Overview

A number you computed but never validated is a guess wearing a lab coat.

**Core principle:** Lock in what must be *true* before you trust what you *discovered*.

This is the **checker**: it asserts invariants and reconciles totals, it does not plan or run the work. Its complement is the **doer** — `data-preparation` calls this skill per ingest/join/dedup/recode step, `executing-analysis-plans` calls it on every spine step and fanned-out spec — but you also reach for it directly the moment you're about to trust a number or do a join.

This is the data-analytics counterpart of test-driven development, adapted for the one way it doesn't transfer: TDD asserts the exact output before implementing, but in analysis the output is the unknown — you cannot assert `mean == 42.3` before computing it. The discipline underneath still transfers, and matters *more* here.

## Why analysis breaks naive TDD (and why you still need its spirit)

In software the dangerous bug usually throws — a stack trace, a red test, something loud. In analysis the dangerous bug is **silent**: a join fans out, an `NA` poisons a mean, units are off by 100×, train/test overlap — the code runs cleanly and hands you a confident, wrong answer, no error raised (the full catalog of these is below). So we move the discipline from *"assert the answer first"* (impossible — computing the number IS the point) to **"assert everything *around* the answer that must hold regardless of the answer."** Those are your **data contracts** and **invariants**, checkable *before* you know the result and again *after* — exactly the leverage test-first gives you in software.

## Two regimes — know which one you're in

**1. Exploration** (EDA, plotting, trying models). Forcing test-first here is theater — the rule that applies instead: **validate the inputs before trusting any output, and check intermediate results at every step.** Trust nothing you haven't looked at.

**2. Reusable rules** (a cleaning step, metric definition, transform, feature pipeline). Here you *do* know the rule, so real test-first applies: hand-build a tiny fixture with a known answer, write the check, watch it fail, then implement. A metric definition without a test is a rumor.

Most work flows regime 1 → regime 2: explore to *find* the right transform, then *lock it down* as a tested rule. The mistake is staying in regime 1 forever and shipping exploratory code as production.

## The loop (analytics red-green)

```
CONTRACT  →  CHECK IT BITES  →  COMPUTE  →  RECONCILE  →  FREEZE
```

1. **CONTRACT** — Before computing, write down what must be true: row counts, key uniqueness, value ranges, totals that must reconcile, allowed categories, types and units. (See the invariant catalog below.)
2. **CHECK IT BITES** — Confirm the check actually *fails* on bad data before you trust it: perturb one row to violate the contract, or point it at a known-bad earlier version of the data, and watch the assertion trip. **A check that cannot fail proves nothing** — the analytics form of TDD's "watch the test fail." A row-count assertion that would pass on a broken join isn't protecting you, it's lying to you comfortably; if you've never seen a check go red, you don't know it's testing anything.
3. **COMPUTE** — Do the transform / aggregation / model.
4. **RECONCILE** — Run the contract against the result. Reconcile totals back to the source ("do my segment revenues sum to the grand total I started with?"). Mismatch = **stop; route to `wrong-number-debugging`** to bisect to the bad step — don't patch and proceed. And if the "fix" would drop/winsorize/filter rows or move a number the user has already seen, that's a *sample/spec change*, not an autonomous fix → **`analysis-checkpoints`**.
5. **FREEZE** — Once a result is validated, snapshot it as a **golden / reference output** (a small committed CSV/parquet, or stored summary stats). Future re-runs and refactors diff against it — the regression test of data work, converting *"the number changed three weeks ago and nobody noticed"* into an immediate, obvious failure instead.

## The merge protocol — three lines around every join

More silent analytics disasters come from joins than from anything else, because a join is the one operation that can *change your row count in either direction without erroring*. Every merge gets three lines, written into the pipeline script itself.

(About to hand-write more than a couple of asserts, or facing two-plus joins? Copy `assert_join` and `na_audit` from [`references/contract-helpers.md`](references/contract-helpers.md) instead — one-line calls, pre-tested, terser than free-hand `stopifnot` blocks.)

**1. Cardinality — declare the relationship you expect, then assert it:**

- **1:1** — both keys unique; row count must not change. (Two tables keyed on the same entity.)
- **1:m / m:1** — one side unique; rows on the many side preserved, none duplicated by accident.
- **m:m** — almost never what you actually want. If you didn't *intend* a cross-product, an m:m is a bug. Treat an unexpected m:m as a stop-the-line event.

Say out loud what you expect, then let the tool enforce it:

| | Python (pandas) | R (dplyr) | Julia |
|---|---|---|---|
| Enforce cardinality | `df.merge(o, on="id", validate="one_to_one")` (or `"one_to_many"`, `"many_to_one"`) | `left_join(o, by="id", relationship="one-to-one")` (or `"many-to-one"`) | assert key uniqueness before `leftjoin`: `@assert allunique(o.id)` |
| Catch dropped/added rows | assert `len(out) == len(left)` for a left join that must not fan out | `stopifnot(nrow(out) == nrow(left))` | `@assert nrow(out) == nrow(left)` |
| Catch unmatched keys | check `indicator=True` value counts | `anti_join()` to see what failed to match | `antijoin(left, right, on=:id)` |

**2. Match rate + NA tabulation of the merged-in columns.** The cardinality assert is necessary but not sufficient: a left join can hold its row count, pass the assert, and still fill the columns it brought in with `NA` on every unmatched row — your regressors are quietly missing and nothing errored. After the join, tabulate the match rate and the `NA` counts of the columns that came from the right side, then look at *who* didn't match — unmatched rows concentrated in one year, one region, one category are a systematic gap, not noise:

| | Python (pandas) | R | Julia |
|---|---|---|---|
| NA of merged-in cols | `out[new_cols].isna().sum()` | `colSums(is.na(out[new_cols]))` | `count.(ismissing, eachcol(out[!, new_cols]))` |

**Checking NA is not dropping NA.** The tabulation is mandatory and lives in the script; silently dropping, imputing, or filtering the unmatched rows is a *sample decision* → `analysis-checkpoints`.

**3. Totals reconcile** through the join back to the source (see the catalog below) — the check that catches what the first two miss.

These three lines around a join are the cheapest, highest-value checks in all of data work. Write them every time.

**Before a merge in an established project, consult `docs/LESSONS.md`** for prior join failures in *this* data — a fan-out that bit last month, a vintage mismatch, a key that wasn't as unique as it looked. (Capture lives in `result-verification`; this is the recall half — a logged bug only stops recurring if you read it back before repeating it.)

## The NA map — tabulate missingness early, once per dataframe

Every dataframe gets an explicit per-column missingness tabulation **at first load or build** — one line, inline in the script, before any transform touches it:

| Python | R | Julia |
|---|---|---|
| `df.isna().sum()` | `colSums(is.na(df))` | `describe(df, :nmissing)` |

Why early: nearly everything downstream handles `NA` **silently**. `lm`/`feols` drop incomplete rows without erroring — the "observations removed" note scrolls past in a log while the estimation sample recomposes; `min()`/`max()` over a group return `NA` for the whole group from one bad value; a mean quietly computes over fewer rows than you think. With the NA map known at load, every downstream drop is *predictable* — you can say "this spec will lose 212 rows to missing `region`" before the estimator does it to you. Without it, the sample silently reshapes and nobody notices.

Two rules:

- **The check is mandatory; the drop is not.** `NA` is information — often it *is* the finding (which units don't report, which years are uncovered). Surfacing it is part of the script; removing it (drop / impute / filter) is a sample decision → `analysis-checkpoints`.
- **This is what covers estimation.** An estimation script needs no checks of its own: by the time a model is fit, the NA map and the merge protocol upstream have already determined the estimation sample (in the same validated run — a script that re-loads data fresh is a new ingest boundary; see check placement below). (An assert that enforces a *claim* — e.g. `stopifnot(m_a$nobs == m_b$nobs)` for two specs sold as "identical sample" — is a contract on the claim, not ritual, and is welcome.)

## The invariant catalog — what to assert

These are the things that hold regardless of the answer. Reach for the ones that fit your step:

- **Cardinality / joins** — Did rows fan out or vanish? Assert the expected row count after every join (see above).
- **Keys & nulls** — Join keys unique where they should be? No unexpected nulls in keys? Primary keys actually unique?
- **Versioned / vintage keys** — when a join key gets *re-released* over time (geographies like CBSA/county-FIPS, industry or diagnosis codes, taxonomies, any crosswalk), assert **both sides use the same vintage**, not just the same key. A vintage mismatch doesn't error — it silently mismatches (a low match rate you might not notice) and drops or duplicates rows. Pin the vintage as part of the key contract.
- **Ranges & domains** — Ages in `[0,120]`, proportions in `[0,1]`, no negative quantities, prices positive.
- **Totals reconcile** — Parts sum to the known whole. Pre-aggregation total == post-aggregation total. This catches the majority of silent join/filter bugs.
- **Categories** — The set of category levels matches expectations; no surprise new levels (`"N/A"`, `"unknown"`, mojibake, trailing-space duplicates).
- **Types & units** — dtype/`eltype`/class is what you think; dollars not cents; seconds not ms; the percent column really is a percent.
- **Missingness** — The NA map (above), tabulated at load and re-checked after any operation that can mint new `NA` (joins, recodes, reshapes). Is the missingness rate stable vs. last run?
- **Temporal** — Date ranges sane, no future timestamps, timezone explicit, no duplicated periods after a resample.
- **Determinism / reproducibility** — Same input + same seed → same output. If it doesn't, you have hidden state.
- **Leakage** — For any model: no target leakage, no train/test overlap, no future information in features.

## Provenance up front — write the lineage into the contract

A contract is not just about *values*; it's about *where the values came from*. Before you build on a column, you should be able to answer: where did this come from, how was it derived, and what was dropped or recoded upstream to make it? Capture that as part of the contract — a short data dictionary alongside the code:

- **Source** — which raw file / table / extract / API each column originates from.
- **Derivation** — the exact rule that produced any computed column (and its units).
- **Upstream surgery** — rows filtered, categories collapsed, values recoded, deduplication applied *before* this dataset reached you. These are the silent killers; an analyst who doesn't know a 30% sample was already taken will over-count by 3×.

When a number later comes out wrong, this lineage is what lets `wrong-number-debugging` bisect fast instead of guessing. Document it while you still remember it.

## Language cheat-sheet (R / Julia / Python)

Use the idioms native to each stack rather than bolting on a framework you don't need:

| Need | Python | R | Julia |
|---|---|---|---|
| Inline assertion | `assert df.shape[0] == n, msg` | `stopifnot(nrow(df) == n)` | `@assert nrow(df) == n msg` |
| Data contract / schema | `pandera`, `great_expectations`, `pydantic` | `assertr`, `pointblank`, `validate` | `@assert` on `eltype`, `Test`, custom schema check |
| Unit test (reusable rule) | `pytest` with tiny fixtures | `testthat` | `Test` stdlib (`@test`) |
| Missing handling to watch | `NaN` vs `None`, `df.isna().sum()` | `NA`, `sum(is.na(x))` | `missing`, `count(ismissing, x)` |
| Reconcile totals | `assert np.isclose(parts.sum(), total)` | `stopifnot(isTRUE(all.equal(sum(parts), total)))` | `@assert isapprox(sum(parts), total)` |

Use floating-point-aware comparison (`np.isclose` / `all.equal` / `isapprox`) for any reconciliation — exact `==` on floats will betray you.

Past two or more joins, a reconciliation, or a baseline to freeze, don't re-derive helper functions from scratch — copy the canonical prelude for your language from [`references/contract-helpers.md`](references/contract-helpers.md): `assert_join` (declared cardinality + row-count bracket + unmatched-key and merged-in-NA report), `na_audit` (the NA map, at first load), `reconcile`, and `freeze_baseline`/`check_baseline`, in Python, R, Julia, **and Stata** (where `isid`, `merge, assert()`, and `datasignature` are built in).

## Check placement — a few checks at boundaries, not an inventory

Checks concentrate where silence lives: **ingest** (the NA map, types/units), **every merge** (the three-line protocol), **sample construction** (totals reconcile, the train/test split & leakage check for any model, the golden freeze), and **once at report time** (figures/tables tie to the prose). That is the whole pipeline surface — plus three sanctioned checks that live off the pipeline: regime-2 fixture tests of reusable rules (above), the structural estimator's Monte-Carlo recovery harness (`structural-estimation`), and the frozen eval-harness probe (`predictive-modeling`).

- **Every check names the silent failure it catches.** Can't name one → don't write it.
- **One check per failure mode — the strongest one.** Prefer the tool's enforcing argument (`validate=`, `relationship=`, `merge, assert()`) over a separate assert; don't stack a dup-key assert, a row-count assert, and a reconcile against the same fan-out. Redundant asserts are the inventory in miniature. And no ceremony: a check is one or two lines in place, not a banner-titled section.
- **Check budget scales with the task.** A single-join analysis script needs ~4 checks total: the NA map, one cardinality guard on the join, the merged-in NA tabulation, one reconcile. Nine checks on a two-file task is the inventory reborn inline. Any check beyond the protocol must answer to a **named threat in this data** — a comparison that a format drift would silently break, a key the join argument doesn't already enforce — not to a hypothetical.
- **Inline in the pipeline script, not a parallel check-script inventory.** A standalone `checks/` directory that grows a file per anxiety is software-engineering theater, not rigor — observed in the wild at 55 check scripts against 9 estimation scripts, while the bugs that actually bit (an NA-amplifying group `min()`, silently dropped rows) had no check at all. Check *placement* is rigor; check *count* is not.
- **Style and hygiene checks are not data contracts.** Figure styling, repo tidiness, docs freshness — fine as project tooling if the user wants them, but they live outside the analysis-check surface and never count as validation.
- **Estimation scripts are exempt** *within a pipeline whose boundaries were checked in the same run* — the NA map and merge protocol upstream cover them. A spec script that re-loads data fresh (a fanned-out robustness subagent, a standalone re-run) is a new ingest boundary: re-assert its input contracts before fitting.

## Red flags — STOP and validate

- "The pipeline ran without errors, so the numbers are right" / "I'll just eyeball the head() / summary() and move on." Neither a clean run nor an eyeball is a contract — neither re-runs.
- A join, merge, filter, or group-by with no row-count check before and after — or a merge nobody inspected for where the `NA`s landed.
- A dataframe headed into a model whose NA map was never tabulated.
- Reporting a figure you computed but never reconciled against the source.
- Building step N on top of step N-1's output without having validated step N-1.
- A check that has never once failed — you don't know it works.
- Re-running an analysis and not comparing against the last known-good output.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "The data's clean, it came from the warehouse." | Warehouses fan out, change schemas, and re-key. Trust, then verify with a row count. |
| "I can see it's right." | You can see *a* number. You can't see the rows the join dropped. |
| "The totals are close enough." | "Close" on a reconciliation usually means rows are leaking. Find out why before you round it away. |
| "Adding checks slows me down." | A wrong number in front of a stakeholder costs far more than the 60 seconds the assertion took. |

## The Process

1. **Write the contract and watch it bite** — keys, ranges, totals, the NA map at first load, the merge protocol per join; feed it one broken row and confirm the assertion fires before you trust it.
2. **Compute, then reconcile against the source.** A clean run is not a correct result.
3. **If a reconciliation / total / cardinality assertion FAILS → STOP and invoke `wrong-number-debugging`** — bisect the pipeline to the exact bad step; do not patch and proceed.
4. **If the "fix" would drop/filter/winsorize rows, change a join's grain, or move a number the user has already seen → STOP and invoke `analysis-checkpoints`** — that's a sample/spec redesign, not an autonomous bug fix; don't smuggle it in.
5. **Otherwise freeze the validated result as a golden baseline** and continue to the next step — every future re-run diffs against it.

## The bottom line

```
Reported result  →  contract written, check seen to bite, totals reconciled, baseline frozen
Otherwise        →  not validated, just hopeful
```

You are not slowing down. You are refusing to be confidently wrong.
