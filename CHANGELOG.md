# Changelog

All notable changes to Causal Powers. Versions follow the plugin manifest.

## 0.22.0 — Recall, not fold (the two-layer learning model)

Prompted by the user's question — *are lessons/memory used effectively, or
becoming bloat?* The audit: the card had re-bloated 970→1256 with no eviction
rule; the project's `LESSONS.md` was rich but **write-only** (4 capture sites in
the skills, 0 recall sites); one 22 KB memory file sat on a dormant project. The
decision (user-driven): **lessons are domain-specific and stay in the project;
the skills are *pointed to* them, not folded into them** — folding would bloat
the shared family with one project's idiosyncrasies. Full rationale:
`docs/2026-06-13-recall-not-fold.md`.

- **Recall + consolidation-suggestion wiring** (the only permanent addition —
  text in 3 existing files, no new skill): the **card** gains a "consult the
  project's `LESSONS.md` + memory at start / before a join / before reporting;
  recalled here, not folded; if bloated/stale while consulting, *suggest*
  consolidation" rule; **`result-verification`**'s "Capture what bit you" becomes
  **"Consult — and capture —"** (read the scar tissue first, capture at the end,
  fold upward only as a rare pattern-only exception); **`data-contracts`** says
  consult the project log before a merge. Recall is the half of the loop that
  makes a logged bug actually stop recurring; consolidation-suggestion is
  demand-driven (never scheduled, never auto-run).
- **Two domain-free pattern folds** (pattern only; instance left in the project):
  `data-contracts` — **versioned/vintage join keys** must assert the same vintage
  on both sides, not just the same key; `result-verification` — a robustness
  check returning a number **identical to baseline** is a silent no-op, not
  evidence. (Generalize the project's CBSA-vintage and leave-one-out lessons.)
- **Card re-diet + eviction rule**: 1256 → 1156 words *while adding* the recall
  section (pre-existing prose compressed ~210 words); a top-of-file budget
  comment now guards against creep (target ≤ ~1050).
- **Memory consolidation** (via the `consolidate-memory` skill, on the
  suggestion model): the 22 KB dormant-proxy memory file → **3 KB** (−86%) —
  kept the orientation + the one durable conclusion + gotchas, dropped the
  superseded narrative and re-derivable detail; refreshed the stale index line.

## 0.21.0 — Task-altitude planning (from real-session dogfood)

Driven by reviewing the user's actual analysis sessions, which gave a sharper
diagnosis than any eval: causal-powers plans at the **study altitude** (estimand
/ PAP / model card) but **hand-waves at the task altitude** — *"merge these two
messy sources"*, *"diagnose why this number is off"* get a dive, not a
roadmap-you-agree-to-first. On a real co-located-coordinate bug the agent dove
into record-dumping and the user had to interrupt to impose an order; the project
has zero `analysis-plan.md` (every plan is a superpowers design doc). Full
write-up: `docs/2026-06-13-task-altitude-rung-and-dogfood.md`.

- **Task-altitude planning rung** — generalized "write it down before you build"
  from study to task altitude, carried by the skill bodies (where real sessions
  get it), card as backstop:
  - `wrong-number-debugging`: REPRODUCE now ends by **stating the diagnostic
    roadmap and getting a nod before running scans**; LOCATE executes the agreed
    roadmap. (Fixes the interrupt-to-impose-order pattern.)
  - `analysis-craft`: a multi-step build/refactor gets a **numbered roadmap
    confirmed before coding**; an approved upstream study design does *not*
    waive the task-level build steps.
  - `data-preparation`: fires for an **ad-hoc mid-analysis merge/reconcile**,
    plan **agreed** before executing.
  - card + gateway: "always a written plan" reframed to **two altitudes**, same
    `write → agree → loop → checkpoint-on-deviation` pattern, same
    couple-of-steps threshold so trivial edits aren't taxed.
- **Viz-trigger validation** (the gate): `eval-triggers.py --live --competitors`
  on haiku — `question-framing` **won 17/19** build-from-data cases against the
  full competitor menu incl. `superpowers:brainstorming` (all 5 viz cases won;
  the 2 losses went to the causal-powers gateway, in-family), **negatives 20/20
  clean**. The v0.19.0 viz broadening is validated; precision boundary held.
- **Lesson-nudge recurrence** (`hooks/stop-gate`): the lesson gate re-fires as
  *new* debugging accumulates without a lesson (capped 2/session, only on growth
  in the debugging count); the escape hatch is one line to `LESSONS.md` — the
  lesson *or* a `no-lesson: <why>` note — making a silent skip a recorded
  decision. Motivated by the live ledger (5 debugging stops, 0 lessons). Results
  and lesson gates now use independent per-obligation markers.
- **Re-trigger context cost**: the re-trigger rule now distinguishes
  *re-applying the discipline* (always) from *reloading the skill body* (only
  when scrolled out / compacted away) — long sessions were reloading full
  `SKILL.md` bodies on every re-trigger.
- **New behavioral scenario** `pressure-roadmap-first` (manifest-pressure).
  Card-alone, haiku: 0/1 — re-confirming that card text alone doesn't change a
  weak model's behavior (v0.20.0 redux); the rung is delivered by the skill
  bodies, whose validation needs the full-plugin arm.

## 0.20.0 — The ranked-next adoptions, executed and measured

All six ranked candidates from the 0.19.0 evolution survey, adopted in one
pass — with the measurements run (haiku as the cheap subject model), not just
the machinery built. Results: `docs/2026-06-12-pressure-descopt-subagent-tests.md`.

- **Pressure suite** (`evals/behavioral/manifest-pressure.json`, 4 scenarios;
  runner gains `--manifest`): the plant is in the *prompt* — "the join was
  already validated", "skip the robustness, deadline tonight", "stay consistent
  with the +0.21 the board saw", "drop the outliers so it reads clean".
  First run (haiku): **card 1/4 vs baseline 1/4** — the always-on card alone
  did not rescue a weak model from social pressure (the card arm even saw the
  row fan-out and rationalized it as "valid 1:M"). Paired with 0.19.0's core
  result (sonnet 8/9 vs 8/9), the conclusion: protection lives in the
  enforcement layers and model strength, not in a context string — hence the
  Stop-gate below and a planned full-plugin benchmark arm.
- **Description hill-climbing** (`scripts/optimize-description.sh`, wrapping
  the official skill-creator `run_loop.py`): ran 3 challenger iterations each
  on `question-framing` and `structural-estimation` (60/40 train/holdout,
  best-by-test-score). **Both originals won** — including the same-day viz
  broadening of question-framing. The two flagship descriptions are now at a
  measured local optimum; re-run the script after any description edit.
- **Subagent value regression** (superpowers v5.0.6 method, scoped): the
  `analysis-reviewer` prompt vs generic review on the two missed-plant
  artifacts, 3 reps per arm on haiku. **12/12 — both arms surfaced the planted
  issue every time**, with an instructive confound: the "generic" arm's
  transcripts show the installed `analysis-review` skill triggering natively
  (6/6) on "review this analysis". Clean takeaways: a fresh review pass
  catches what the same model missed as author (the strongest evidence yet for
  the independent-review step); the specialist persona adds no measured delta
  over the skill-equipped default (superpowers v5.0.6 redux); and triggering
  worked 6/6 in headless haiku. Agent kept; dissolve decision deferred to an
  isolated rerun.
- **Stop-gate + JSONL run ledger** (`hooks/stop-gate`, new `Stop` hook): at
  most ONE soft block per session, only in analysis projects (opt-in surface:
  `analysis-plan.md` or `docs/LESSONS.md` present), never when continuing from
  a prior block — fires when a results artifact was written without
  `result-verification`, or debugging ran without a LESSONS entry; the reason
  always includes an explicit out (state it doesn't apply in one line — never
  loop). Every stop appends to `.causal-powers/ledger.jsonl` (append-only,
  survives compaction). Six-case test battery in the hook's design;
  five-condition loop safety after planning-with-files v3.
- **Injection hardening** (`hooks/plan-resume`): plan-file excerpts injected at
  SessionStart are now sanitized (reminder-wrapper tokens stripped) and capped
  at 240 chars each — the plan file is writable by content pasted from fetched
  pages, i.e. an injection surface (planning-with-files' 2026-03 audit).
- **Hook kill-switch**: every hook (session-start, prompt-router, plan-resume,
  skill-chain, stop-gate) honors `CAUSAL_POWERS_DISABLED_HOOKS` — a
  comma-separated disable list, the escape hatch when a hook misbehaves.

## 0.19.0 — Measure the value, not just the firing

The release theme: the family's evals previously tested whether skills *trigger*;
nothing tested whether following them *catches anything*. Now both are measured,
the everyday workhorse ships code, the learning loop is closed, and the always-on
card paid down its accretion debt.

- **NEW: behavioral benchmark** (`evals/behavioral/` + `scripts/run-behavioral-eval.py`).
  Nine scenario tasks, each with one planted silent failure from the family's
  threat model (fan-out join, silently filtered rollup, cents-vs-dollars,
  top-coded missingness, train/test overlap, post-treatment "control", diverging
  pre-trends, spatial silent drop, non-identified elasticity). A deterministic
  generator emits data + task + grading rubric together, so rubric numbers are
  computed from the actual data. The runner A/Bs `claude -p` arms — baseline vs.
  the always-on card — under an **isolated `CLAUDE_CONFIG_DIR`** (locally
  installed plugins can't contaminate the baseline), then an LLM grader applies
  each plant's catch criterion. First calibration run (sonnet-4-6): **card 8/9
  vs baseline 8/9** — near-ceiling both arms. The honest reading: sonnet-4-6's
  default discipline already covers loud single-task plants (a baseline catch
  is good news about the model); the card's one clean differential was the
  least-salient plant (train/test overlap, caught only with the card); the v0
  scenarios need pressure framings + pipeline embedding before the headline
  number discriminates. Full analysis + v1 hardening plan:
  `docs/2026-06-12-behavioral-benchmark-v0.md`.
- **NEW: trigger CI** (`scripts/eval-triggers.py`). Part A pipes every
  `evals/trigger/*.json` query through the *real* `hooks/prompt-router` and
  scores it against a committed baseline
  (`evals/trigger/router-baseline.json`); CI fails on new precision violations
  or lost recall hits, so router/description edits are regression-tested instead
  of hand-simulated. Current state: recall 54/127 (a backstop, by design),
  precision 145/145. Part B (`--live`, optional cost) tests description
  matching via `claude -p` — with `--competitors` it includes the overlapping
  superpowers descriptions, directly measuring the
  "brainstorming-steals-the-trigger" failure mode that motivated 0.19.0's
  question-framing fix.
- **NEW: `data-contracts` ships code** —
  `skills/data-contracts/references/contract-helpers.md`: copy-paste
  `assert_join` (declared cardinality + row-count bracket + unmatched-key
  report), `reconcile`, `na_audit`, `freeze_baseline`/`check_baseline` in
  Python, R, Julia, **and Stata** (`isid`, `merge, assert()`, `datasignature` —
  resolving the family's Stata inconsistency: organization + helpers cover
  Stata; guidance prose remains R/Julia/Python).
- **Lessons loop closed**: `wrong-number-debugging` (new Process step 5) and
  `analysis-review` (new step 4) now end by logging the failure class to the
  project's `docs/LESSONS.md` — the two moments a failure class is freshest;
  `result-verification`'s ship-time retro already existed.
- **Always-on card diet**: `hooks/session-context.md` tightened 1,258 → 970
  words (−23%) with zero rules dropped — the workflow spine merged into the
  written-plan rule, repeated rationale riffs cut. `AGENTS.md` inherits via
  symlink.
- **Stale-plugin warning** (`hooks/session-start`): compares the loaded
  plugin version against the published manifest (daily-cached, 2s-capped,
  fail-silent `curl`) and tells the session to suggest
  `/plugin update` + restart. Counters claude-code#52218 (auto-update never
  refreshes plugin installs) — the mechanism behind "the skills never
  triggered" on a stale live session.
- **question-framing broadened to data-visualization deliverables** (commit
  729fd6b): a map/figure/dashboard/interactive viz *built from a dataset* now
  triggers framing (unit = what each mark represents, encoding = the metric,
  joins get more scrutiny, not less) across all five surfaces — description,
  body, gateway, always-on card, router + trigger eval (9 new cases). Fixes
  the real-session miss where "build a leaflet map of my treatment facilities"
  fired only superpowers:brainstorming.
- **Evolution survey**: `docs/2026-06-12-evolution-candidates.md` — a sourced
  survey of superpowers / anthropics-skills / ecc / planning-with-files and the
  broader ecosystem, with ranked adoption candidates for future releases.

## 0.18.1 — Codex one-liner installer

- `scripts/install-codex.sh`: one copy-paste `curl | bash` installs the 14
  skills into Codex's scan dir (`~/.agents/skills`, or `<repo>/.agents/skills`
  with `--project`) and the always-on discipline as a managed, marker-delimited
  block in `AGENTS.md` — idempotent, with `--uninstall` that removes only the
  managed block. Verified install / re-install / uninstall end-to-end.

## 0.18.0 — Codex compatibility

The skills are plain `SKILL.md` (name + description) — the format Codex also
triggers on natively. Added the surrounding layer Codex needs (it has no
SessionStart hook): `AGENTS.md` (symlink → `hooks/session-context.md`, single
source, no drift), a `.codex-plugin/plugin.json` manifest, a Claude-Code→Codex
tool mapping (`references/codex-tools.md`: Task→spawn_agent, Skill→native,
TodoWrite→update_plan, fan-out degrades to inline), and README/gateway sections.
Claude Code behavior unchanged.

## 0.17.2 — Post-addition consistency audit

`data-preparation` arrived after the chain-parity rewrites, so the other
skills' handoff graphs predated it. Audited all 14: `executing-analysis-plans`
now routes its build step through `data-preparation` (which calls
`data-contracts` within) instead of jumping straight to the checker;
`data-contracts` documents the doer/checker boundary from its side. The other
12 were already consistent. Corpus precision unchanged at 100%.

## 0.17.1 — Docs sync

Gateway prose and README caught up with the shipped plugin: the written-plan
rule describes the phased, living `analysis-plan.md` (Phase 1 =
`data-preparation`'s sub-plan, disk-as-RAM, resumable across `/clear` and
compaction via the SessionStart/PreCompact hook); README covers the full hook
layer and adds `data-preparation` to the table.

## 0.17.0 — `data-preparation` + the phased, resumable execution plan

Closes the grain mismatch: cleaning — the heaviest, most decision-dense phase —
was a single spine bullet. New skill `data-preparation` (the **doer/planner**
for the cleaning phase; `data-contracts` is the **checker** it calls per step):
ingest→clean→join→dedup→recode→reconcile as a checkboxed Phase 1 of a living
`analysis-plan.md` with a decisions log; consequential cleaning choices fork to
`analysis-checkpoints`. Ships `analysis-plan-template.md`. New `plan-resume`
hook (SessionStart + PreCompact) resumes the next open step after `/clear` or
compaction. Router family added (0 false-fires on repo-cleanup phrasings).

## 0.16.0 — Chain enforcement parity

The chain documented its transitions but didn't reliably *fire* them. Three
legs: all 12 content skills replaced the descriptive "Relationship to sibling
skills" section with an imperative **When to Use decision graph + The Process**
that invokes the next skill; a new **PostToolUse skill-chain hook** surfaces
each skill's next obligation the moment it's invoked (framing→plan+gate,
execution→inline-vs-subagent ask + bounded fan-out, verify→review);
the router gained the executing-analysis-plans and pre-analysis-plan families.
`question-framing` now owns the everyday analysis plan (data + approach +
deliverable) for general/exploratory work, with a hard confirmatory-cut check.

*(0.12–0.15 were never cut — version numbering jumped during rapid iteration.)*

## 0.11.0 — UserPromptSubmit trigger router

The discipline was only injected at SessionStart — once, then it scrolls off
and goes wallpaper. New `hooks/prompt-router` fires on every prompt, scans for
trigger phrases across the skill families, and injects a per-turn nudge naming
the specific skill to invoke. Scoped honestly as a **high-precision backstop**
(precision 100% on the eval corpus after a suppression guard for
writing/formatting/teaching prompts that merely *name* a method; recall ~22% by
design — description matching remains the primary mechanism).

## 0.10.2 — Re-trigger per request (don't coast on a locked design)
- Added the **re-trigger rule** to the always-on hook card and the
  `using-causal-powers` gateway: a skill invoked earlier in the session does not
  stay satisfied. Every new ask re-fires the relevant skill **even on an
  already-locked, already-reviewed design** — a re-run or a finer reporting cut is
  still `executing-analysis-plans` + `result-verification` *before any result is
  written to a file*; "review it" re-fires `analysis-review`; a cut that changes
  the unit/estimand re-opens `question-framing` + `analysis-checkpoints`. Closes
  the real-world failure where "this is just running the locked plan" skipped the
  execute/verify gates and shipped an unverified new cut.
- Reinforced in `executing-analysis-plans` (a new cut on a locked plan re-fires
  this skill, ends in verification) and `analysis-review` ("review it" re-fires
  every time, including mid-session — don't answer from loaded context).

## 0.10.1 — archive folders + manifest listing
- `project-organization`: added a per-category **`archive/`** for old runs that are
  no longer used but worth keeping (a superseded spec, last quarter's results, a
  retired model version). It's distinct from `sandbox/` (throwaway) and
  `results/diagnostics/` (regenerable scratch): archive is deliberately retained,
  inactive provenance, and **tracked**. Retiring a run now means **move to
  `archive/`, not delete** — reinforced in the cleanup pass, the git rules, and the
  always-on hook.
- Manifests: `project-organization` (research-project organization) now listed in
  the plugin/marketplace descriptions.

## 0.10.0 — `project-organization`, the compaction discipline, and a full audit pass

**New skill — `project-organization`.** A standalone discipline for organizing an
empirical/structural research repo (not a single-language ML-product template):
paper-centric pipeline stages × subject subfolders (data stage included),
`data/{raw,intermediate,output}`, standardized naming, and a before-git cleanup
pass. Track the data a replicator needs; gitignore only secrets, sensitive data,
and files past GitHub's ~100 MB limit (shrink oversized-but-shareable files to
parquet/tsv first). Enforced throughout, tidied before commit; offer-don't-delete.

**Actively maintain the plan; compact at phase boundaries.** The plan/brief/model
card is a living document you update as you go; at each finished phase (after a
spine step / fan-out assembly) write the decisions + insight + concrete
POST-COMPACT next steps into it and **offer to compact**, so a long, fix-heavy
session resumes on a clean slate from the document alone.

**Family audit pass (Tiers 1–3) — see `docs/2026-06-09-family-audit-and-map.md`.**
A six-auditor review across fluff, LLM-workflow clarity, HITL triggering, and
pipeline holes, with every finding fixed:
- **HITL gates moved onto the always-on card** (the only reliably-loaded surface):
  the robustness-shortlist STOP, sample drops (drop/winsorize/filter), and a
  restoring fix that moves an already-seen number. Plus a **non-interactive
  fallback** (batch/cron: stop at the last validated state, return
  options+recommendation, never resolve silently).
- **Closed the dangling handoffs:** `question-framing` now has an explicit "is this
  confirmatory? → pre-analysis-plan" gate; `result-verification` makes "dispatch
  `analysis-reviewer`" and "tidy with `project-organization`" real steps; the PAP
  blinding gate moved to "before touching outcome data"; a verification check that
  fails now stops rather than shipping behind a caveat.
- **Always a plan**, with an observable trigger replacing the unmeasurable
  ~10-minute one; "check it" = invoke the Skill tool; the `analysis-checkpoints`
  contradiction resolved with a tiebreaker.
- **structural-estimation:** pipeline collapsed to `MODEL CARD → APPROVAL`,
  mid-pipeline gate hardened, the missing **VALIDATE FIT** section added, the
  Hessian ridge-check made imperative, "report a range" given a method.
- **De-fluff:** halved the model-card section, de-duplicated repeated rules to
  one-liner-plus-pointer, fixed reference-code skeletons. Kept the load-bearing
  repetition (the never-change-the-goal rule in every sibling list).

## 0.9.1 — The plan/spec/model-card discipline, made a rule
- **Elevated "write it down before you build" to a first-class always-on rule**
  (the SessionStart hook card and the `using-causal-powers` gateway), co-equal
  with "never change the goal behind the user's back": before any substantial
  work, commit the plan/spec to a file and confirm it — the framing brief, the
  pre-analysis plan, or, for structural work, the model card.
- **The structural spec is now a living "model card"** — written the moment you
  understand the model, even rough, capturing the structure and, above all, what
  would move each parameter and what variation/instrument identifies it (a blank
  identification row is a parameter you can't yet identify). Every later change is
  an edit to the same card; load-bearing changes still route through
  `analysis-checkpoints`. Renamed "model spec" → "model card" across the live
  skills, hook, and README for one vocabulary, tied to the `references/` cards.
- **The discipline is entry-point-agnostic and recurring.** Wherever the user
  drops you in ("just estimate / fix / run this"), back up and write or reconstruct
  the card *first*, then do the named step. Each major component and every
  mid-stream fix is an edit queued onto the card.
- **The ~10-minute rule** (`analysis-craft` + hook): anything beyond a quick
  surgical fix gets a short written plan/spec and a confirm before you code;
  a sub-10-minute rename/typo/one-liner you just do.

## 0.9.0 — Trigger-eval coverage, agent generalization, and fixes
- Updated the **trigger evals and reusable agents** for the reduced-form/structural
  boundary: added `evals/trigger/structural-estimation.json` (with reduced-form
  near-misses — the elasticity-from-an-experiment trap, a 2SLS demand elasticity,
  a DiD), added structural near-miss negatives to `causal-identification.json`,
  taught the `analysis-reviewer` agent the structural silent failures, and
  generalized the `robustness-runner` agent to also run a Monte-Carlo recovery
  rep or a counterfactual scenario.
- Backfilled **trigger evals** for the rest of the family (`question-framing`,
  `pre-analysis-plan`, `analysis-craft`, `analysis-checkpoints`,
  `executing-analysis-plans`, `result-verification`, `analysis-review`) — each a
  20-query set whose negatives are deliberate sibling near-misses (e.g. a restore-
  fix that must NOT trip `analysis-checkpoints`; reviewing someone else's notebook
  vs. self-verifying before reporting), so the set tests the boundary, not just
  keywords. Every skill now has a trigger eval.
- Fixed **YAML frontmatter**: an unquoted `description:` value containing `: `
  (colon-space) parses as a nested mapping ("mapping values are not allowed in
  this context"). Replaced the offending colon with the house-style em-dash in
  `structural-estimation`, `analysis-checkpoints`, and `analysis-review`; all
  skill and agent frontmatter now parses cleanly with pyyaml.

## 0.8.0 — Structural estimation (the structural workflow)
- Added `structural-estimation`: the structural counterpart to
  `causal-identification`. A model-agnostic discipline across IO structural
  models — differentiated-products demand (logit/random-coefficients/BLP) +
  supply, single-agent dynamic discrete choice, entry/dynamic games, auctions,
  limited consideration, and search.
- Core moves: justify going structural over reduced form (the Lucas-critique
  fork); **write the model spec — primitives, identification, estimand,
  estimation plan — to a file and get approval before estimation** (the
  structural pre-analysis-plan); name what identifies **each** parameter;
  **prove the estimator recovers known θ by Monte Carlo before trusting real
  data** (converge back from a distant start; map the objective surface — a flat
  direction is non-identification); derive **analytical gradients group-by-group**
  when the estimator (GMM/MoM, NLS, MSL) admits them, and check them against
  finite differences; and **re-solve equilibrium** for counterfactuals with one
  scenario per mechanism.
- Reference cards: `references/model-classes.md` (per-class primitives /
  identification / counterfactual) and `references/estimation-and-gradients.md`
  (estimators, the group-by-group gradient structure, a Monte-Carlo-recovery
  harness skeleton, inference, reproducibility).
- Wired the **reduced-form vs. structural fork** into `using-causal-powers` and
  the always-on SessionStart hook card.
- **Wove `structural-estimation` into the whole family** with bidirectional
  cross-links so it isn't a bolt-on: `question-framing` now treats the
  reduced-form-vs-structural choice as a *framing* decision (the estimand is a
  structural counterfactual when the decision needs a world outside the data);
  `causal-identification` names structural as the other half of the fork;
  `pre-analysis-plan` notes the model spec as its structural analog;
  `analysis-checkpoints` adds the structural model/conduct/distribution to the
  STOP list; `executing-analysis-plans` fans out recovery reps, starts, and
  per-mechanism counterfactuals; `result-verification` and `analysis-review` add
  the structural checks (recovery passed, equilibrium re-solved, identification
  stated); `data-contracts` frames the recovery test as a contract on the
  estimator; `wrong-number-debugging` separates an implausible counterfactual
  (model) from a data bug.

## 0.7.0 — Robustness is an argument, not an inventory
- `executing-analysis-plans` no longer fans out an exhaustive menu of robustness
  checks. It names the main identifying threat, proposes the ~3 checks that would
  break the result if it's fragile (each with a rationale), gets approval, and
  runs only the approved set.
- Reinforced across `causal-identification`, `pre-analysis-plan`,
  `analysis-checkpoints`, and the always-on hook card.

## 0.6.0 — Always-on layer + reusable agents (ECC-inspired)
- Added a **SessionStart hook** (`hooks/`) injecting a compact always-on
  discipline block, so must-always rules don't depend on a skill triggering.
- Added **agents/**: `robustness-runner` (fan-out worker) and `analysis-reviewer`
  (independent adversarial review).
- Folded **lessons-capture** into `result-verification` + seeded `docs/LESSONS.md`.

## 0.5.0 — Economic judgment + consolidation
- Wove senior-economist judgment into `question-framing` (form a prior on sign,
  magnitude, mechanism), `result-verification` (interpretable units, economic vs
  statistical significance, plausibility, mechanism, benchmark), and
  `causal-identification` ("what's your experiment?" + bad-controls).
- Trimmed repetition; reduced-form micro focus.

## 0.4.0 — Plan execution
- Added `executing-analysis-plans`: drive an approved plan, validate the
  dependent spine in order, fan independent work out to parallel subagents.

## 0.3.0 — Human-in-the-loop checkpoints
- Added `analysis-checkpoints`: loop toward the agreed goal, never change the
  design/sample/spec/estimand behind the user's back.
- Hardened `wrong-number-debugging` (data-bug fix vs analytical-design change)
  and `causal-identification`; `question-framing`/`pre-analysis-plan` persist an
  artifact and hard-stop for approval before execution.

## 0.2.0 — Karpathy craft principles
- Added `analysis-craft` (simplicity-first code + surgical edits) and wove
  goal-driven-execution + think-before-coding into the gateway.

## 0.1.0 — Initial family
- Gateway + 7 skills: `question-framing`, `pre-analysis-plan`, `data-contracts`,
  `wrong-number-debugging`, `result-verification`, `causal-identification`,
  `analysis-review`. Three-language (R/Julia/Python). Supersedes the earlier
  single `validation-driven-analysis` skill.
