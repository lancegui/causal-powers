# descriptive-evidence — thinning loop notes (2026-07-20)

Branch `thin-2026-07`. Subject `ollama/deepseek-v4-pro:cloud` via
`scripts/run-skill-eval.py --jobs 1` (foreground only). Grader
`claude-sonnet-4-6`.

Word counts: `main` (pre-P1) 4713 — the family's largest skill. Post-dedup
(P1, this loop's starting point) 4178. **Final (this loop) 3505** — -16.1%
vs. post-dedup, **-25.6% vs. `main`**.

## Probe suite

- `composition-simpson` — **STATIC**, checked-in data, no generator, never
  regenerated or modified. Overall mortality falls 2015→2022 while it RISES
  in both severity strata (mix shift). Owns: the composition check.
- `de-denominator` (new, `evals/behavioral/scenarios/de-denominator/`,
  self-contained `generate.py`, seed 20260501) — state-level product
  signups; raw-count top-5 (CA, WA, MA, CO, TX) inverts against per-capita
  top-5 (UT, CO, MA, WA, NY) once normalized by the unmentioned
  `data/state_population.csv`; #1 flips CA→UT. Owns: per-capita/denominator
  comparability fix ("map/rank where X is concentrated").
- `de-nominal-trend` (new, `evals/behavioral/scenarios/de-nominal-trend/`,
  self-contained `generate.py`, seed 20132023) — 11-year revenue series
  (2013-2023) whose nominal "growth" (+24.5%) is entirely price-level; real
  (deflated by the unmentioned `data/cpi.csv`) growth is -5.9%. Business
  framing: "growth slide for the board deck." Owns: real-vs-nominal + base
  year comparability fix.
- Both new plants compute their catch-criterion numbers programmatically
  from the just-written CSVs inside `generate.py` (not hand-typed) — data
  and rubric cannot drift apart. `de-denominator`'s generator additionally
  asserts the #1 state inverts and the top-5 sets diverge by >=2 members, so
  a future reseed can't silently produce a non-discriminating plant.
- An early draft of `de-nominal-trend`'s `task.md` included a breadcrumb
  ("there may be other files in `data/` worth a look") — removed before any
  subject run, since it would have turned "does the subject explore on its
  own" into "was the subject told to look," undermining the plant. Both new
  scenarios instead follow the brief's design: name only the planted data
  file, leave the comparability file unmentioned in the same `data/` dir.
- Render-and-look (screenshot QA of an actual rendered chart/map) —
  **not attempted**, infeasible in this headless, single-turn, text-only
  harness per the audit. Recorded as an un-probed obligation.
- Also un-probed by this loop (composition-simpson covers composition only;
  the 2 new probes cover the two comparability items named in the brief):
  the causal-verb firewall (`Describe, don't infer`), `Show the
  distribution`, `Honest visualization`, and `Is the number plausible?`
  (reliability/validity). All four thinned conservatively — wordiness trims
  only, every named rule/check kept — and flagged here per the rule that
  unexercised sections don't get structural cuts on judgment alone.

## Discrimination (arm none, reps=2) — mandatory recipe step 1

| scenario | baseline catch |
|---|---|
| composition-simpson | 1/2 |
| de-denominator | 0/2 |
| de-nominal-trend | 0/2 |

None saturated (no 2/2) — no hardening needed, all 3 kept as-authored.
Run: `runs/20260720-092618-de-discrim-none/`.

## Fixed A/B/C anchor (reps=3) — iteration 0

A = none, B = `file:@main:skills/descriptive-evidence/SKILL.md` (4713w),
C = `file:skills/descriptive-evidence/SKILL.md` at loop start (4178w,
post-dedup, pre-thinning).

| scenario | A (none) | B (main) | C (post-dedup) |
|---|---|---|---|
| composition-simpson | 1/3 | 3/3 | 3/3 |
| de-denominator | 0/3 | 2/3 | 2/3 |
| de-nominal-trend | 0/3 | 3/3 | 3/3 |
| **total** | **1/9** | **8/9** | **8/9** |

Run: `runs/20260720-093238-de-abc-anchor/` (regraded in place — see incident
below) + `runs/20260720-123247-de-nomtrend-retry/` (de-nominal-trend B/C
resubmission).

## Thinning iterations (C-only, reps=3 vs. the fixed A/B above)

| iteration | words | composition-simpson | de-denominator | de-nominal-trend | total |
|---|---|---|---|---|---|
| 0 (anchor C, post-dedup) | 4178 | 3/3 | 2/3 | 3/3 | 8/9 |
| 1 | 3636 | 3/3 | 2/3 | 3/3 | 8/9 |
| **2 (final)** | **3505** | **3/3** | **3/3** | **3/3** | **9/9** |

Run 1: `runs/20260720-124329-de-iter1-C/`. Run 2 (final):
`runs/20260720-125200-de-iter2-C/`. C >= B held at every iteration (8/9,
8/9, then **9/9** — strictly above B's 8/9 on the final candidate). Stopped
after iteration 2 because (a) the result is already a clean improvement over
both `main` and the post-dedup baseline, and (b) budget: 57/60 DeepSeek
subject runs used, leaving 3 — not enough for a further cut + verification +
possible-revert cycle within the cap. Per the recipe, iterating stops on
regression OR budget exhaustion; this is the latter, at a good result.

## Run-count accounting (cap 60)

6 (discrimination) + 27 (anchor, incl. 6 that errored — see incident, all
counted per "re-run an errored rep once, count both") + 6 (de-nominal-trend
B/C resubmission after the incident) + 9 (iter1 C) + 9 (iter2 C) = **57/60**.
Re-grading the 21 valid-but-initially-ungraded anchor transcripts used ZERO
additional subject runs (grading isn't DeepSeek/pi and doesn't count against
this cap) — same harness lesson as the P3 batch-1 notes ("read the actual
transcripts / re-grade before trusting an unexpectedly-low catch rate"),
here applied to an infra failure rather than a criterion bug.

## Incident: shared account-quota exhaustion mid-anchor-run, and the fix

The first anchor-run attempt (launched via `nohup ... &` + a background
Monitor, before a coordinator course-correction) came back with: all 27
reps' GRADING failed (`GRADER PARSE FAIL: Expecting value...` — empty
`claude -p` stdout), and `de-nominal-trend`'s B and C arms additionally
failed at the SUBJECT level with `429 "you (lanceguixiaofan) have reached
your session usage limit..."`. That 429 text is a Claude-account session
limit, not an Ollama Cloud rate-limit message — plausible given several
sibling per-skill agents were hitting the same shared Claude account
concurrently (grading + `isolated_config` probing all shell out to
`claude -p`). The coordinator flagged quota was restored and instructed:
(a) foreground Bash only, explicit timeouts, never background — adopted for
every run after this point; (b) if genuine Ollama Cloud rate-limiting shows
up, smoke-test switching the subject to Pi's direct DeepSeek API
(`deepseek/deepseek-v4-pro`) and re-run affected batches on the new
provider, keeping one provider per A/B/C comparison. A `claude -p` smoke
test confirmed the account limit had reset; the 21 non-errored anchor
transcripts were then re-graded IN PLACE from their already-written per-rep
JSON (no new subject calls), and the 6 errored `de-nominal-trend` B/C reps
were resubmitted as a fresh foreground batch (`de-nomtrend-retry`) — which
completed cleanly on `ollama/deepseek-v4-pro:cloud` with zero errors. **No
subject-model switch was needed or performed** — the failure was never
genuine Ollama Cloud rate-limiting, so `deepseek/deepseek-v4-pro` direct-API
was not smoke-tested in this loop. The one-off regrade helper lived at
`/private/tmp/.../scratchpad/_regrade_anchor.py` (outside the repo) and was
never checked into `skills/` or `evals/`.

## Cuts made (post-dedup 4178 -> final 3505, -673w / -16.1%)

Two passes, wordiness/prose trims only — no numbered item, named check, or
cross-skill pointer was deleted. Heaviest cuts landed on the sections no
probe exercises directly (`Is the number plausible?` 485->~340w,
`Descriptive maps` 315->~250w, `Overview` 423->~330w); the composition-check
and comparability-choices sections (both directly probed) were trimmed
lightly and kept their full enumerated content. Concretely:
- `Overview`: 4 paragraphs tightened, no claim dropped (composition
  artifact, twin causal-slide failure, core-principle sentence verbatim).
- `What are you producing?`: table rows condensed; fixed a latent
  inconsistency ("three shapes" heading a 5-row table) by dropping the
  stale count instead of the row it no longer matched.
- `Fix the comparability choices`: all 7 numbered items kept (denominator,
  real-vs-nominal+base-year, per-capita, weighting, unit of observation,
  window+frequency, aggregation level); each clause shortened.
- `The composition check`: light trim only (heavily probed, composition-
  simpson at 3/3 throughout) — all 4 decomposition tools (within/between,
  shift-share, Oaxaca, plot-the-subgroups) plus the selection-into-sample
  check kept in full.
- `Honest visualization`: 5 bullets collapsed to 3 — axis honesty /
  index-to-base-year / log-vs-linear merged into one "scale honesty" bullet
  (all three are facets of the same rule); smoothing and dual-axis traps
  kept as separate bullets, nothing dropped.
- `Descriptive maps`: all 5 spatial rules kept (rate-not-count, MAUP,
  color-binning-as-axis-honesty, join-to-data-contracts, where-not-why);
  the rate-not-count bullet is the one this loop's `de-denominator` probe
  exercises, so left fullest; the other 4 trimmed harder.
- `Is the number plausible?`: the single largest section (485w), and
  entirely un-probed by this loop — cut hardest (~30%) on prose alone;
  reliability-vs-validity distinction and all 3 named checks (known-shock,
  external-benchmark, alternative-construct-coverage) kept, one illustrative
  example ("AI-trace PRs") dropped as decorative.
- `Red flags` / `Common rationalizations`: already near the P1 family cap;
  light wording trims only, all 6+6 rows kept (no merges).
- `The Process`: 7-step canonical checklist kept at 7 steps, each
  shortened.
- Untouched: YAML frontmatter (`name:`/`description:`), `The bottom line`
  ASCII summary, the `Tooling` reference table (functional content, not
  prose bloat — trimmed only its one-line outro).

## Kept-and-flagged (unprobed obligations, not cut structurally)

See "Also un-probed by this loop" above for the four sections; per the
brief's rule ("unsure = keep and flag; unexercised sections get wordiness
trims only"), none of these had a numbered rule, named check, or verb list
removed — only prose tightened. A future loop with a render-and-look-capable
harness, or a 4th probe targeting the causal-verb firewall directly, could
re-open these for a real (not just prose) cut.
