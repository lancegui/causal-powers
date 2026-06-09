# Changelog

All notable changes to Causal Powers. Versions follow the plugin manifest.

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
