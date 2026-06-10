# Phased Execution Plan — Design Spec

**Date:** 2026-06-10
**Status:** Draft — decision #1 RESOLVED (data-preparation is its own skill); awaiting confirm on the data-contracts boundary + defaults #2–#5 before build.

---

## Update 2026-06-10 — `data-preparation` as a first-class skill (decision #1)

The user resolved #1: **data preparation gets its own skill.** Justified by how
heavy and decision-dense cleaning is in the actual work (ARCOS↔SAMHSA). This
changes the build from "enhance `executing-analysis-plans`" to "add a new skill
+ its wiring (router family, skill-chain case, evals, spine placement)."

### The one boundary that must be crisp: `data-preparation` vs `data-contracts`

They are **complementary, not overlapping** — define them so they never compete
for the same trigger:

- **`data-contracts`** = the *checking* discipline. Assert invariants, join
  cardinality, reconciliation; freeze baselines. It is the **test harness** —
  fires on "I'm about to trust a number / do a join / merge."
- **`data-preparation`** = the *planning + doing* discipline for the cleaning
  **phase**. Decompose ingest → clean → join → dedup → recode → reconcile into a
  phased, checkboxed plan with a decisions log; work through it deliberately;
  resumable. Fires on "I need to clean / build / assemble the dataset" — a
  **phase**, not a single assertion.
- **Relationship:** `data-preparation` *owns the phase and calls* `data-contracts`
  to validate each step. Same relation `executing-analysis-plans` has to
  `data-contracts` (the doer uses the checker). `data-preparation` is the doer
  for the build phase specifically; it produces Phase 1 of `analysis-plan.md`
  (its own sub-checklist + decisions log).

### Chain placement

`executing-analysis-plans`' spine step 1 ("build/clean/join the dataset") now
**delegates to `data-preparation`**, which plans + executes the cleaning phase
(calling `data-contracts` to validate each step), then returns control for
variable construction → primary spec → robustness → verification.

Edges to add to the map:
- `executing-analysis-plans → data-preparation` [spine]: the build/clean phase.
- `data-preparation → data-contracts` [crosscut]: validate every cleaning step.
- `data-preparation → wrong-number-debugging` [crosscut]: a reconciliation fails.
- `data-preparation → analysis-checkpoints` [crosscut]: a cleaning decision
  changes the sample / is consequential (drop/dedup/winsorize/recode that moves a
  number) — STOP, it is the user's call, not a silent fix.
- `data-preparation → executing-analysis-plans` [spine]: clean validated dataset
  built → return to the spine.

### Defaults assumed for #2–#5 (confirm or adjust)

- **#2 completion gate:** soft — `result-verification` reads the plan.
- **#3 resumability hook:** SessionStart re-read + PreCompact flush.
- **#4 file model:** single `analysis-plan.md` with a decisions section
  (`data-preparation` owns its Phase-1 sub-checklist within it).
- **#5 threshold:** `data-preparation` triggers when cleaning is more than a
  couple of steps or will span a session; a single already-clean file skips it
  (state the waiver).

### Build scope once confirmed

1. New `skills/data-preparation/SKILL.md` — purpose, the cleaning-phase plan,
   the decisions log, the `data-contracts` boundary, imperative
   `## When to Use` + `## The Process` (chain-parity form), description tuned
   for triggering.
2. `hooks/prompt-router` — a new high-precision family (anchored "clean/build/
   assemble the dataset/panel" — precision-tested against the corpus + SWE/life
   negatives, like every other family).
3. `hooks/skill-chain` — a `data-preparation` case (delegates from execution;
   calls data-contracts; consequential cleaning decision → analysis-checkpoints).
4. `evals/trigger/data-preparation.json` — should/should-not-fire rows.
5. Spine wiring — `executing-analysis-plans` SKILL.md delegates step 1;
   `using-causal-powers` spine + flow diagram updated; the `analysis-plan.md`
   artifact + resumability hook.

## Purpose

Close a **grain mismatch** in the discipline: causal-powers plans at the
*whole-analysis* grain (one framing brief / PAP / model card), but within
`executing-analysis-plans` the heaviest phase — **data ingest & cleaning /
dataset construction** — is a single spine bullet ("build/clean/join → validate
with `data-contracts`"). In real empirical work that phase is the largest, most
decision-dense, and longest-running part of the job (merges, dedup, missingness,
coding decisions, vintage/source reconciliation — e.g. the ARCOS↔SAMHSA address
normalizer). Planning it as one bullet under-plans exactly the part that needs
the most planning.

Two compounding facts:

1. **v0.16.0 tuned the chain to *propel*** ("don't end at the brief — invoke the
   next skill"). That is deliberate momentum. This spec is the counterweight:
   propel *between* skills, but **decompose and plan deliberately *within* the
   heavy ones**.
2. **No resumable, phase-level progress ledger.** The brief/PAP is persisted, but
   nothing tracks *where you are inside a long execution* in a way that survives
   `/clear`, compaction, or a multi-session cleaning effort. Existing integrity
   tools (`analysis-checkpoints`, `result-verification`, `data-contracts`) are
   **reactive STOP gates**, not **proactive per-phase plans**.

Reference: [planning-with-files](https://github.com/othmanadi/planning-with-files)
("filesystem = persistent RAM; context = volatile RAM → anything important is
written to disk"; one phased `task_plan.md` with checkboxes; session recovery;
completion gate).

## Adopt vs resist (from planning-with-files)

**Adopt:** disk-as-RAM persistence; one *living* phased plan with checkboxes;
resumability across context loss; a completion gate; frequent write-down of
decisions/findings (the "2-action rule").

**Resist:** universal "never start without a plan" + completion-gate on *every*
query (ceremony/friction on trivial work); one-file-per-step sprawl (we use a
single phased doc). The value is concentrated in **data cleaning + long /
multi-session phases**, not plan theater on "what's the median order value."

## Design

### The artifact — `analysis-plan.md` (living, phased, checkboxed)

Extends (does not replace) the framing brief / PAP / model card: the brief is
Phase 0; the plan adds the execution phases. Default phases for non-trivial
reduced-form work:

0. **Brief / PAP / model card** — the approved estimand, population, unit,
   decision (already exists; linked, not duplicated).
1. **Data ingest & cleaning** — *first-class, own sub-checklist*: sources +
   provenance, each join with asserted cardinality + row reconciliation, dedup
   rule, missingness handling, coding/recodes, reconciliation to source totals.
   Every non-obvious decision logged with its rationale.
2. **Variable construction** — treatment / outcome / covariates + their
   validations (ranges, leakage, missingness).
3. **Primary specification** — the one pre-committed number.
4. **Robustness fan-out** — the chosen ~3, run inline or via subagent per the
   execution-mode ask (already in `executing-analysis-plans`).
5. **Verification & assembly** — `result-verification`, then `analysis-review`.

Each phase carries: a checkbox + status (`todo` / `in-progress` / `done`), a
**decisions log** (the 2-action write target — every consequential cleaning/
coding choice recorded with *why*, so it survives context loss and is
auditable), and a "contracts passed" note.

### Resumability

A hook (SessionStart and/or PostCompact) that, when an `analysis-plan.md` exists
in the project, re-reads it and surfaces: *"You were in Phase N; these boxes are
checked; next is X."* Mirrors planning-with-files session recovery. Optionally a
PreCompact hook that flushes current phase state to disk before compaction.

### Completion gate

`result-verification` (already the terminal gate) reads the plan and refuses
"done" until all phases are checked **and** verified. (Soft version. A harder
Stop-hook gate that blocks halting until the plan is complete is possible but
heavier — see open decisions.)

### Size threshold (avoid ceremony)

Kicks in for: confirmatory work; any analysis with a real (multi-step) cleaning/
construction phase; work expected to span a session. **Waived** (state the
waiver explicitly) for one-shot queries. Heuristic: if cleaning/build is more
than a couple of steps, or the work will outlive one session, write the phased
plan.

### Where it lands (no new colliding skill)

Per the lesson from the chain-parity work — *don't spawn a colliding skill*:

- **Enhance `executing-analysis-plans`** to produce & maintain `analysis-plan.md`,
  with **data cleaning promoted to a first-class phase** with its own sub-plan,
  updating checkboxes as it goes.
- **Enhance `question-framing`'s plan section + the spine doc** to name
  `analysis-plan.md` as the execution artifact the brief flows into.
- **Add one resumability hook** (SessionStart / PostCompact) to re-read the plan.

## Open decisions (for the user)

1. **New skill vs enhance `executing-analysis-plans`?** Recommend *enhance* (no
   collision). But data cleaning is arguably big enough to merit its own skill
   (`data-preparation` / `cleaning-plan`) — your call.
2. **Completion gate hardness:** soft (`result-verification` reads the plan) vs
   hard (Stop hook blocks "done" until phases checked). Recommend **soft**.
3. **Resumability hook scope:** SessionStart re-read only, or also PreCompact
   write + PostCompact catch-up? Recommend SessionStart + PreCompact.
4. **One file vs the trio:** single `analysis-plan.md` (with a decisions section)
   vs planning-with-files' `task_plan.md` / `findings.md` / `progress.md`.
   Recommend **one file** for causal-powers (less sprawl).
5. **Size threshold:** where exactly is the "non-trivial enough" line?

## Honest caveats

- The soft-nudge ceiling still holds — a plan file is only as good as the
  discipline to update it; the resumability hook helps but cannot *force*.
- Plan-theater risk is real; keep the mechanism scoped to data cleaning +
  long / multi-session phases, not every query.
