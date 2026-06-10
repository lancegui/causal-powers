# analysis-plan.md

> Living plan for this analysis. Keep it current: tick boxes as you finish,
> update each phase's **Status**, and append every consequential choice to the
> Decisions log. A fresh/compacted session resumes from THIS file — anything not
> written here is lost.

**Title:**
**Owner / date started:**
**Last updated:**
**Current phase:** Phase 0
**Next step:** _the single action to take next_

---

## Phase 0 — Brief & PAP link
**Status:** not started

- [ ] Framing brief written (estimand/metric, population, unit of observation, the decision it informs, what would flip it)
- [ ] Confirmatory vs exploratory determined
- [ ] If confirmatory: pre-analysis-plan locked BEFORE outcomes seen — link: _path/URL_
- [ ] If counterfactual outside the data: structural model card written — link: _path/URL_
- [ ] User sign-off on brief + plan obtained

---

## Phase 1 — Data ingest & cleaning  _(owned by `causal-powers:data-preparation`)_
**Status:** not started

- [ ] Sources identified (tables/files, grain, reachable?)
- [ ] Loaded with explicit schema / types
- [ ] Row & key counts recorded against source (reconciliation)
- [ ] Join cardinality asserted before every merge (1:1 / 1:m / m:1)
- [ ] Missingness, duplicates, units checked
- [ ] Cleaned dataset frozen as a baseline (path + hash/rowcount)

### Decisions log (Phase 1)
> Every drop/filter/winsorize/recode/join-grain choice — date, what, why, who approved. These are analysis-checkpoints decisions, not silent fixes.

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

> BOUNDED — pick the ~3 checks that earn their place; a wall of specs reads as weak identification. Independent specs may fan out to parallel subagents.

- [ ] Robustness checks chosen (which, and why these)
- [ ] Alternative specifications run
- [ ] Placebo / falsification test(s) run
- [ ] Sensitivity / subsample cuts run
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
