# analysis-plan.md

> Living plan for this analysis — one canonical file, at the project ROOT. Keep
> it current: tick boxes as you finish, update each phase's **Status**, and
> append every consequential choice to the Decisions log. A fresh/compacted
> session resumes from THIS file — anything not written here is lost.

**Title:**
**Owner / date started:**
**Last updated:**
**Current phase:** Phase 0
**Next step:** _the single action to take next_

---

## Phase 0 — Framing brief & plan links  _(owned by `causal-powers:question-framing`)_
**Status:** not started

- [ ] Estimand / metric pinned (for a viz: what each mark represents and encodes)
- [ ] Population + unit of observation stated
- [ ] The decision this informs, and what would flip it
- [ ] Economic prior recorded (sign, magnitude, mechanism) — BEFORE outcomes seen
- [ ] Data sources named (tables/files, grain, the joins that assemble them — reachable?)
- [ ] Approach / spec sketched (the HOW, not just the what)
- [ ] Deliverable named (table, figure, map, memo — what "done" looks like)
- [ ] Confirmatory vs exploratory determined
- [ ] If confirmatory: pre-analysis-plan locked BEFORE outcomes seen — link: _path_
- [ ] If counterfactual outside the data: structural model card written — link: _path_
- [ ] If the goal is a prediction: Prediction Spec written — link: _path_
- [ ] **User sign-off covering the WHAT, the WITH-WHAT-DATA, and the HOW**

---

## Phase 1 — Data ingest & cleaning  _(owned by `causal-powers:data-preparation`)_
**Status:** not started

- [ ] Source inventory with provenance (where each file came from, vintage, who owns it)
- [ ] Loaded with explicit schema / types
- [ ] Per-source validation before any join (`data-contracts`: ranges, keys, units)
- [ ] Row & key counts recorded against source (reconciliation)
- [ ] Every join: cardinality declared and asserted (1:1 / 1:m / m:1) + row deltas logged
- [ ] Dedup RULE stated (what counts as a duplicate) + count removed logged
- [ ] Recodes / harmonizations logged in the decisions log (old → new, why)
- [ ] Missingness DECISION made and logged (drop / impute / flag — not silently default)
- [ ] Totals reconciled to source
- [ ] Cleaned dataset frozen as a baseline (path + hash/rowcount)

### Decisions log (Phase 1)
> Every drop/filter/winsorize/dedup/recode/join-grain choice — date, what, why,
> who approved. These are analysis-checkpoints decisions, not silent fixes.

- _(none yet)_

---

## Phase 2 — Variable construction
**Status:** not started

- [ ] Outcome(s) constructed and defined
- [ ] Treatment / exposure variable(s) defined
- [ ] Covariates / controls constructed
- [ ] Each constructed variable validated (range, distribution, spot-check)
- [ ] Definitions documented (match the brief's metric definition)

---

## Phase 3 — Primary specification
**Status:** not started

- [ ] Primary spec estimated exactly as pre-registered / planned
- [ ] Identification strategy stated and its assumptions tested (design-specific suite)
- [ ] Primary estimate recorded (point, SE, N)
- [ ] No deviation from PAP without an analysis-checkpoints sign-off

---

## Phase 4 — Robustness fan-out
**Status:** not started

> BOUNDED — the ~3 checks that probe the MAIN identification threat, chosen and
> **approved via analysis-checkpoints** (the choice is the user's, not a buffet).
> Execution mode (inline vs parallel subagents) is asked up front, user's call.

- [ ] Check 1: _which, and what threat it probes_ — approved ☐
- [ ] Check 2: _which, and what threat it probes_ — approved ☐
- [ ] Check 3: _which, and what threat it probes_ — approved ☐
- [ ] Results collated against the primary estimate

---

## Phase 5 — Verification & assembly
**Status:** not started

- [ ] Totals reconciled to source
- [ ] Result reproduced from a clean session with a fixed seed
- [ ] Every figure/table matches the numbers in the prose
- [ ] Independent analysis-review (silent-failure sweep) done
- [ ] Scratch tidied (project-organization); deliverables separated from working files
- [ ] Final result reported / handed off
