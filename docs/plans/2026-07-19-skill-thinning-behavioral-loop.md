# Skill thinning via per-skill behavioral loops — plan (2026-07-19)

Status: approved 2026-07-19; executing on branch `thin-2026-07`.

## Goal

Thin every causal-powers skill (~45,000 words today → target ≈30,000) while
holding or improving the behavior each skill induces, verified per skill by
behavioral probes run on **DeepSeek v4 Pro through headless Pi**
(`pi -p --mode json --model ollama/deepseek-v4-pro:cloud`). Fold the July-2026
audit's Tier-2 additions (spec-conformance, artifact-vs-chat reconciliation,
visible-consequence forecast, control-set check at proposal time,
CI-crosses-zero gate, render-and-look) into the same loops so thinning and
strengthening land together per skill.

Why a non-Claude mid-tier model: if a thinned skill still steers DeepSeek v4
Pro, it will steer the stronger orchestrator models; testing on the weakest
realistic consumer is the honest bar, and it can't be contaminated by Claude's
prior exposure to the skill text.

## Amendments to the original proposal

1. **Central dedup before fan-out.** The shared boilerplate (five sign-off
   blocks, 16× STOP-gate restatement, 15 dot digraphs, templated tails) must be
   collapsed by ONE pass with one set of conventions. If 17 parallel agents
   each decide the dedup independently, the family diverges. Per-skill agents
   thin *within* the new conventions.
2. **Reuse the existing harness.** `scripts/run-behavioral-eval.py` already
   implements isolated-config arms, planted-failure scenarios with
   data-derived catch criteria, and LLM grading. We add: (a) a Pi runner
   (subject = `pi -p` with the skill variant via `--append-system-prompt`),
   (b) an arm that injects an arbitrary skill file (current vs thinned), not
   just the card. The 10 existing scenarios + pressure suite are reused as-is
   where they map to a skill.
3. **Pilot before fan-out; batch the fan-out.** Two skills first to debug the
   Pi runner and grading; then batches of ~5 concurrent skill agents (Ollama
   Cloud rate limits; reviewable increments) rather than all 17 at once.

Scope note: Pi has no Skill tool or hooks, so these loops test **behavior
induction given the skill text is in context** — exactly the thing thinning
could break. Trigger/firing quality (descriptions) is a separate, existing
suite (`evals/trigger/`, `scripts/eval-triggers.py`) and descriptions stay
under the 1024-char CI guard, mostly unchanged.

## Per-skill loop (what each sonnet subagent runs)

1. Read the skill, the audit evidence for it, and the new shared conventions.
2. Ensure 2–4 probes exist for it: reuse matching `evals/behavioral/scenarios/`
   entries; author new ones in the same convention (neutral task prompt;
   `plant.md` catch criterion computed from generated data; grader-scored,
   plus mechanical greps where possible). New-behavior probes for any Tier-2
   addition assigned to this skill.
3. Run arms in scratch dirs: **A** no skill (control), **B** current skill
   (from `main`), **C** thinned candidate. n=3 paired runs per arm per probe
   (single runs are noise).
4. Iterate C: thin → run → compare. Keep thinning while C ≥ B on every probe's
   catch rate. On regression, restore last good C and stop.
5. Deliver: thinned SKILL.md in the working tree (no git commands), new/updated
   scenarios, and a report (before/after word counts, per-probe A/B/C table,
   what was cut, what was added).

## Phases

**P0 — preflight (main session).** Smoke-test
`pi -p --mode json --model ollama/deepseek-v4-pro:cloud` headless; branch
`thin-2026-07` in this repo; move `skills/descriptive-evidence-workspace/` to
`evals/behavioral/runs/archive-2026-06/` (pure relocation, no content change).

**P1 — shared-pattern pass (main session, one reviewed commit).**
Establish the conventions every later agent must follow:
- one canonical "locked doc → sign-off → reconstruct-if-mid-pipeline" gate
  pattern (owner: `analysis-checkpoints`); the five domain variants keep only
  their own named rows + a pointer;
- STOP-gate stated fully once, one-line pointer elsewhere;
- delete all 15 dot digraphs (each restates the adjacent Process list);
- tail policy: Red flags / rationalizations tables capped, no duplicated flow
  prose;
- consolidate the ~85%-overlapping checklists across `result-verification` /
  `analysis-review` / `wrong-number-debugging` into one canonical list;
- re-diet the always-on card back under its ≤~1215-word budget;
- refresh `docs/family-audit-and-map.md` to all 17 skills (seeded by the
  2026-07-19 inventory report).
This is ~25–30% of the total savings and touches every file, so it lands
before any per-skill agent forks off. Arm B in later loops = the pre-P1
version from `main`, so the evals validate P1's cuts too.

**P2 — harness extension + pilot (one sonnet subagent).**
Add the Pi runner + skill-file arm to `run-behavioral-eval.py` (or a sibling
`run-skill-eval.py` if cleaner). Pilot on two skills:
- `data-contracts` (existing scenarios: `fanout-join`, `silent-filter-total`,
  `unit-mismatch`);
- `analysis-checkpoints` (pressure-suite probes: "just drop the outliers",
  "make it more significant" — the audit's proven win to protect, plus a new
  visible-consequence-forecast probe).
Exit: runner works end-to-end on DeepSeek v4 Pro, grader agrees with manual
reading on the pilot transcripts, pilot skills thinned with C ≥ B.

**P3 — fan-out (sonnet subagents, each owns only
`skills/<name>/` + its scenario dirs).**
*Mode change, user-directed 2026-07-19 night: run SEQUENTIALLY, one skill
agent at a time; orchestrator reviews and commits each skill, then
dispatches the next without waiting for per-skill user approval. If API
quota exhausts, pause and resume after reset. The batch groupings below
now define ORDER, not concurrency.*
- Batch 1 (core loop): `question-framing`, `data-preparation`,
  `result-verification` (+ artifact-vs-chat + spec-conformance probes),
  `wrong-number-debugging`, `executing-analysis-plans`.
- Batch 2 (modeling arms): `causal-identification` (+ control-set-at-proposal
  probe; existing `bad-control`, `pretrend-violation`),
  `structural-estimation` (existing `nonidentified-param`),
  `predictive-modeling` (existing `leakage-overlap`),
  `descriptive-evidence` (existing `composition-simpson`; render-and-look
  probe).
- Batch 3 (support): `analysis-review`, `analysis-craft`,
  `project-organization`, `pre-analysis-plan`, `using-causal-powers`
  (routing text; judged mostly by trigger evals + word count),
  `analysis-state-management` (SPLIT per audit — generic state advice vs
  conductor-specific schema — rather than thinned).
Main session reviews and commits each skill separately as batches complete.

**P4 — integration check (main session + one subagent).**
Co-firing bundle run: card + thinned core four on a fresh "did the policy
work" scenario, checking interaction regressions. Re-measure the session token
footprint vs the audit's 23k–29k baseline. Re-run the trigger suite.

**P5 — mechanics + release (separate small commits).**
Stop-gate grep regex fix (BSD/GNU bracket-expression bug) with
`test-stop-gate.sh` coverage; commit-nudge behavior (ask once → act at phase
boundary); LESSONS.md promotion step at phase close; CHANGELOG entry; version
bump; full-suite rerun; publish.

## Ownership, budget, and rules

- Subagents run on sonnet, never commit, never touch shared files (card,
  hooks, docs) — those are main-session work in P1/P5.
- Run artifacts go under `evals/behavioral/runs/` (gitignored), scratch
  fixtures in temp dirs, never in `skills/`.
- Estimated run volume: ~2–4 probes × 3 arms × 3 reps × ~2–3 thinning
  iterations ≈ 50–100 short Pi runs per skill, on `deepseek-v4-pro:cloud`.
  Batching caps concurrency; if Ollama Cloud rate-limits, fall back to
  sequential probes within a batch.
- Success criteria for the whole effort: total skill prose ≤ ~30k words; every
  skill's probe catch-rate C ≥ B; trigger suite unchanged or better; the five
  audit wins (p-hacking stop, spec-search line-hold, join contracts, overclaim
  catch, disk-as-RAM resume) each covered by at least one probe that passes.
