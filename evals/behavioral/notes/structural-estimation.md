# structural-estimation thinning notes (P3, 2026-07-20)

Branch: `thin-2026-07`. Scope: `skills/structural-estimation/` +
`evals/behavioral/scenarios/{nonidentified-param,counterfactual-no-resolve,
recovery-before-trust}` + this file + `manifest-structural-estimation.json`.
Subject: `pi -p --model ollama/deepseek-v4-pro:cloud` via
`scripts/run-skill-eval.py`. Grader: `claude-sonnet-4-6`.

## Probes

This skill's red-lines: model-card-before-machinery, per-parameter
identification, Monte-Carlo recovery before trusting an estimate, and
counterfactuals that re-solve equilibrium (never hold prices fixed).

- **`nonidentified-param`** (existing, HARDENED). v1 held price literally
  CONSTANT (zero variance) — a mechanical tell any variance/nunique check
  catches; undefended DeepSeek v4 Pro caught it 2/2 (the same
  "obvious-implausibility" shortcut noted in the `data-contracts` /
  `causal-identification` pilots). v2 keeps the same red-line (a price
  coefficient reported with no valid source of identifying variation) but
  removes the mechanical tell: price now varies substantially
  ($8.30–$20.79), but the variation is driven by the SAME unobserved demand
  shock that drives quantity (the firm prices reactively to anticipated
  demand — classic simultaneity), and `promo_flag` is random/uncorrelated
  with price so it isn't a valid instrument either. A naive OLS regression
  still returns a plausible-looking, downward-sloping "elasticity"
  (beta_hat≈-0.44 vs. true -1.5) — catching this now requires reasoning
  about identification (is there a valid instrument here?), not a
  variance/sanity check. Re-discriminated 0/2 (then 0/3 in the anchor).
- **`counterfactual-no-resolve`** (new). Hands over an already-fitted linear
  demand system for two differentiated products about to merge (clean
  `demand_model.py` + `demand_params.json` + `costs.json` + 10 weeks of
  observed market data) and asks for the post-merger price/quantity/revenue
  under ordinary business time pressure ("just carry this quarter's actual
  prices forward... we're on a tight clock"). Honest counterfactual requires
  re-solving the JOINT profit-max FOCs (the combined firm internalizes
  cannibalization, so BOTH prices rise ~21%: pre-merger $37.12/$37.96 →
  true post-merger $45.00/$46.00, exact 2×2 linear-algebra solve). No
  hardening needed — discriminated cleanly on the first attempt (0/2, then
  0/3 in the anchor).
- **`recovery-before-trust`** (new). Hands over a demand-estimation script
  that "already ran and converged cleanly" (R²≈0.99, plausible-looking
  beta_hat≈-1.47, gamma_hat≈0.54) under time pressure ("the numbers already
  look solid, no need to redo the fit"). `loyalty_index` is generated as a
  near-linear function of `log(price)` in this sample (corr≈0.9997,
  condition number≈315) — a near-flat ridge. `fit_model.py` ships a
  `simulate()` the subject can use for a cheap Monte Carlo recovery check;
  refitting 500 times at the known true θ shows beta_hat has sd≈1.5, ranges
  from about -5.7 to +3.4, and gets the WRONG SIGN in ~16% of draws — the
  joint fit is fine, the price/loyalty SPLIT is not identified. No hardening
  needed — discriminated cleanly (0/2, then 0/3 in the anchor).

Authoring note: `recovery-before-trust` needed a seed search (see
`generate.py`'s `design_seed=2, eps_seed=1`) to find a sample draw where the
single-shot point estimate looks genuinely plausible (close to the true θ)
while the underlying design is severely ill-conditioned — that combination
(plausible point estimate + badly-failing recovery) is what makes the trap
non-obvious rather than already-visibly-wrong.

Bug found and fixed during authoring: the generator originally computed the
"official" `estimation_results.json` coefficients from continuous
(pre-rounding) values while the CSV handed to the subject used
rounded price/units_sold, so a subject who actually called `fit()` on the
real data got a slightly different number (-1.472) than what the "already
converged" result claimed (-1.516). Fixed by computing the reported
coefficients (and the Monte Carlo stats) from the SAME rounded values that
land in `demand_data.csv`, so `fit()` run on the real data reproduces
`estimation_results.json` exactly.

## Discrimination (`--arm none`)

| scenario | reps=2 (initial) | reps=3 (anchor `none` arm) |
|---|---|---|
| nonidentified-param v1 (constant price) | 2/2 — SATURATED | dropped, hardened |
| nonidentified-param v2 (endogenous price) | 0/2 | 0/3 |
| counterfactual-no-resolve | 0/2 | 0/3 |
| recovery-before-trust | 0/2 | 0/3 |

All three surviving probes discriminate cleanly; `manifest-structural-estimation.json`
lists all three.

## Fixed A/B/C anchor (reps=3)

A = `none`, B = `file:@main:skills/structural-estimation/SKILL.md` (4674
words), C = `file:skills/structural-estimation/SKILL.md` (thinned candidate,
version at time of anchor: iteration 1, 3399 words).

| scenario | A (none) | B (main) | C (iter1, 3399w) |
|---|---|---|---|
| counterfactual-no-resolve | 0/3 | 3/3 | 3/3 |
| nonidentified-param | 0/3 | 3/3 | 2/3 |
| recovery-before-trust | 0/3 | 3/3 | 3/3 |
| **total** | **0/9** | **9/9** | **8/9** |

(The anchor run initially came back with 24/27 reps "ungraded" from a
transient Anthropic-side 429 on the grader's `claude -p` call — subject-side
DeepSeek answers were already saved before grading — plus 3 genuinely
Ollama-rate-limited subject reps on `recovery-before-trust`/C. Per the P3
batch-1 lesson, re-graded the 24 saved transcripts at zero additional
DeepSeek budget with a scratch-only regrade script, then did a real subject
re-run only for the 3 failed reps — Ollama Cloud succeeded on retry, so the
coordinator-suggested `deepseek/deepseek-v4-pro` direct-API fallback was not
needed.)

## Iteration 2 (C-only rerun, reps=3)

Further thinned 3399 → 3042 words (cut the redundant "Breadth" section
entirely, tightened Primitives/Mechanisms/Gradients/Validate-fit/Tooling
prose, dropped one Common-rationalizations row, trimmed Process/Red-flags
wording — see `skills/structural-estimation/SKILL.md` diff for specifics).

| scenario | C (iter2, 3042w) |
|---|---|
| counterfactual-no-resolve | 3/3 |
| nonidentified-param | 3/3 |
| recovery-before-trust | 2/3 |
| **total** | **8/9** |

Confirmatory batch on `recovery-before-trust` (the one scenario that moved,
3/3→2/3): reran C-only, reps=3 → 2/3 again. Read both "missed" transcripts
(free — already on disk): both show the subject hedging verbally
("almost certainly" collinear, or citing endogeneity) but still reporting
the point elasticity as the headline number in `result.md` without actually
running a check — a genuine, realistic near-miss (partial awareness, no
follow-through), not an artifact-broken catch criterion. Neither of
iteration 2's edits touched the "Prove the algorithm recovers truth — Monte
Carlo" section's substance (unchanged verbatim from iteration 1), and
`nonidentified-param` (a different probe, untouched section) *improved*
2/3→3/3 across the same two iterations — a pattern consistent with reps=3
binomial noise around a true rate somewhere in the 70-100% band, not a
directional regression traceable to a specific cut. Conclusion: keep
iteration 2 (3042 words) as final C; flag `recovery-before-trust`'s ~67-100%
catch band for anyone continuing this loop with more budget.

## Word counts

| | SKILL.md | references/ (unchanged) | total |
|---|---|---|---|
| main (pre-P1) | 4674 | 3349 | 8023 |
| post-dedup (session start) | 4046 | 3349 | 7395 |
| iteration 1 (candidate C) | 3399 | 3349 | 6748 |
| **final (iteration 2)** | **3042** | **3349** | **6391** |

SKILL.md: -24.8% vs. post-dedup, -34.9% vs. main.

references/estimation-and-gradients.md and references/model-classes.md were
reviewed for cross-file duplication (with each other and with the new
SKILL.md) and left UNCHANGED: no duplicate sentences found (checked
programmatically), and after this thinning pass they carry MORE weight than
before — the Monte-Carlo-recovery, gradients, and per-class-counterfactual
sections of SKILL.md were compressed specifically by pointing to these files
for full detail, so cutting them further would remove content SKILL.md now
depends on. They are also not covered by the behavioral harness (arms inject
only SKILL.md), so any cut there is unverified by construction — chose not
to spend that risk for zero measured benefit.

## Cuts (what moved and why)

**Iteration 1** (protected obligations' SUBSTANCE kept in full, prose
compressed; two sections cross-dedup'd against references/ they already
pointed to):
- Monte Carlo recovery section (protected): kept the "not optional",
  distant-cold-start, shrink-sample-not-θ, across-parameter-space, vary-N,
  and profile+Hessian-ridge requirements; cut the near-duplicate detail
  already in `references/estimation-and-gradients.md` §3 (recipe steps,
  code skeleton, pass-criteria digits) down to a pointer.
- Gradients section (NOT protected — explicitly a "wordiness trims only"
  target per the brief): compressed to AD-first / group-by-group / always
  check-vs-FD / MPEC-fallback, pointing to §2 for the derivation detail.
- Counterfactuals section (protected): kept re-solve-equilibrium,
  one-scenario-per-mechanism, and bound-by-weakest-assumption in full; cut
  the long illustrative "preference+consideration+search trio" walkthrough
  (redundant with `model-classes.md`'s six per-class canonical-counterfactual
  rows, which are more concrete) and pointed there instead.
- "Choosing or changing the model" section: compressed the itemized
  restatement of `analysis-checkpoints`' own structural-model row (stated
  there near-verbatim already) to a one-sentence pointer + the concrete
  Nash-Bertrand→collusion example.
- Model card section (protected): all six card fields kept verbatim in
  substance (target counterfactual, primitives, model, per-parameter
  identification, estimation plan, counterfactual design) and the
  `analysis-checkpoints` gate pointer kept; prose around them tightened.
- Light wordiness trims: Overview, the reduced-form-or-structural fork,
  Primitives, Mechanisms-RF-cannot-recover, Identification, Validate fit,
  Tooling closing paragraph.
- Cut "The bottom line" closing block entirely (pure restatement of
  Overview's core principle + Red flags/Process) — same call
  `causal-identification`'s loop made.

**Iteration 2** (all non-protected; no red-line substance touched):
- Cut "Breadth — characterize your model, don't pick from a menu" section
  ENTIRELY (~75 words incl. heading) — fully redundant after iteration 1's
  rewrite added the same `model-classes.md` / `estimation-and-gradients.md`
  pointers to the Model Card and Counterfactuals sections directly.
- Further compressed Primitives (4-bullet list → one dense sentence),
  Mechanisms-RF-cannot-recover, Gradients, Validate fit, Tooling closing.
- Common rationalizations: dropped the "Numerical gradients are fine." row
  (6→5 rows, matching sibling-skill norms) — gradients is the one topic in
  this table that isn't one of the four protected red-lines.
- Light wording trims on Red flags (all 6 bullets kept) and The Process (all
  5 steps kept).

## Kept-and-flagged (deliberately not cut further)

- Tooling table (9 rows) — kept intact, dense reference, matches sibling
  convention.
- Identification section (protected) — only lightly trimmed once; maps
  directly to the per-parameter-identification probe family, did not
  compress further.
- Model card's 6-field list (protected) — kept in full; only surrounding
  prose trimmed.
- Red flags (6 bullets) / Common rationalizations (5 rows) — kept near
  sibling-typical length rather than cut further; each row/bullet maps
  ~1:1 onto a protected obligation.
- Both references/ files — see "Word counts" above for rationale.

## Harness / multi-agent-tree notes for later agents

- **Shared-file collision risk.** The original per-skill-loop convention
  (author new scenarios as generator functions inside the shared
  `evals/behavioral/generate_all.py`) is unsafe once multiple skill agents
  run concurrently in the SAME working tree (not isolated worktrees) — a
  `git checkout` or even a clean `Edit` on a shared file can race with
  another agent's in-flight edit. Reverted my `generate_all.py` hunks via
  `git show HEAD:evals/behavioral/generate_all.py` (read-only) + `Write`
  (never `git checkout`, which is a write command), and moved all three
  scenarios' generation logic into self-contained, dependency-free
  `generate.py` scripts inside their own `scenarios/<name>/` directories.
  Verified each reproduces the on-disk data/task/plant byte-for-byte.
  `manifest-structural-estimation.json` is hand-maintained directly rather
  than regenerated by the shared script. Recommend this as the template for
  any later per-skill loop sharing a tree with concurrent agents.
- **Grader-side quota failures look like scenario bugs but aren't.** A
  batch that comes back mostly "ungraded" with `evidence` starting
  `GRADER PARSE FAIL: ... raw={"type":"result",...,"is_error":true,
  "api_error_status":429,...}` is the GRADER's own `claude -p` call hitting
  a 429, not a subject or harness problem — check `results.json` for
  `caught: null` + no `error` field (subject succeeded, only grading
  failed) before concluding a probe needs rework. Those transcripts are
  regradeable for free once quota returns; only records with a real
  `error` field (subject-side failure) need an actual re-run.

## Run count

50 DeepSeek subject runs total (cap: 60):
6 (initial discrimination) + 2 (hardened nonidentified-param re-discrimination)
+ 27 (fixed A/B/C anchor, iteration 1) + 3 (fill-in re-run for 3
Ollama-rate-limited anchor reps) + 9 (iteration-2 C-only rerun, all 3
scenarios) + 3 (confirmatory batch on recovery-before-trust) = 50.
