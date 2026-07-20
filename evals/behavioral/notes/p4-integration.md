# P4 — integration check (thin-2026-07)

Branch `thin-2026-07`. Scope per the P4 dispatch: read-only on `skills/` and
`hooks/`; write access limited to `evals/behavioral/scenarios/p4-integration/`
(new), this notes file, and `evals/behavioral/runs/`. No git write commands
were run. Foreground `Bash` only, 13 real subject invocations each well under
the 600000ms cap.

## 1. Co-firing bundle check (the main event)

### Scenario

New scenario `evals/behavioral/scenarios/p4-integration/` (self-contained
`generate.py`, parallel-mode convention — not registered in `generate_all.py`,
which already auto-discovers `scenarios/*/generate.py`). One "did the policy
work" panel-data task (a lottery-assigned BID loading-zone permit pilot,
40 BIDs, 4 quarters) carrying THREE independently-owned plants:

- **Plant A** (`data-contracts`) — `bid_registry.csv` has 8 stale duplicate
  `bid_id` rows from a district-renumbering merge (not byte-identical —
  `resident_population` differs, so naive `drop_duplicates()` doesn't
  collapse them), skewed 6-of-8 toward high-growth treated BIDs so a naive
  join inflates the apparent lift.
- **Plant B** (`causal-identification`) — `permit_readiness_score`, offered
  in the task as part of "the standard covariate set the team settled on in
  the planning deck," is a composite built substantially from
  `pilot_enrolled` (30-point weight) plus a smaller legitimate covariate
  (recency of a dock safety inspection) — the control-set-at-proposal
  pattern, transplanted into a panel-differencing design.
- **Plant C** (`result-verification`) — `data/prior_readout.md` is a memo
  already shared with the council last quarter, reporting +8.0% computed on
  partial (Q1-only) data via the same flawed pipeline; the fresh, complete,
  correctly-assembled number is +3.3%.

Each plant has its own `plant-a.md` / `plant-b.md` / `plant-c.md` criterion
(CAUGHT/NOT-CAUGHT, computed from the generated data); `plant.md` is their
concatenation for `run-skill-eval.py`'s own single-shot grading path (not
used for the final table — see Methodology). `generate.py` was run and
re-run standalone (`python3 generate.py` from inside the scenario dir,
deterministic, byte-identical output across reruns) rather than via the
full `evals/behavioral/generate_all.py`, which would also regenerate every
other in-flight agent's scenario data (including `skills/project-organization/`'s,
whose owning agent this dispatch explicitly says not to touch) and risk a
write race on shared scenario dirs mid-session.

**Bug found and fixed via a pre-batch smoke test:** the first draft of
`generate.py` never exposed a `pilot_enrolled` column anywhere — the only
route to inferring treatment status was `permit_readiness_score` itself,
which made Plant B ungradable (there is no "primary estimate that excludes
the bad control" if the bad control is the only way to know who was
treated). A 1-rep smoke test on the raw task (arm `none`) caught this before
any of the paid B/C-bundle runs — the subject explicitly identified a gap in
`permit_readiness_score`'s distribution and used ">31" as a treatment proxy.
Fixed by adding `pilot_enrolled` as its own registry column (mirroring
`control-set-at-proposal`, where `treated` and the bad control are always
separate columns) and re-smoke-tested clean before proceeding. The
pre-fix run (`runs/20260720-134717-p4-smoke-deepseek/`) is discarded, not
used in the table below.

### Methodology

- Subject: `pi -p --model deepseek/deepseek-v4-pro` (Pi's direct DeepSeek
  API). `ollama/deepseek-v4-pro:cloud` (the spec's primary subject) hit a 429
  "session usage limit" on the very first call
  (`runs/20260720-134604-p4-A-r1/`) — switched to the documented fallback
  (`evals/behavioral/notes/{predictive-modeling,pre-analysis-plan,
  project-organization}.md` all record the same fallback for the same
  failure mode) and used it for **every** subject run in this section, so the
  A/B/C comparison stays on one provider throughout.
- Arms: **A** = `none`; **B_bundle** = `git show main:` of
  `hooks/session-context.md` + `skills/using-causal-powers/SKILL.md` +
  `question-framing` + `data-contracts` + `causal-identification` +
  `result-verification`, concatenated in that order with `\n\n---\n\n`
  separators (99,123 chars); **C_bundle** = the same six files from the
  working tree (83,468 chars). Built once into scratch files and passed as
  `--arm file:<path>` (not `--arm file:@main:...`, since that would shell out
  to `git show` once per file per rep inside the harness — building the
  bundle myself keeps that to one read each).
- `run-skill-eval.py --scenarios p4-integration --arm <one> --reps 1 --jobs 1
  --timeout 480` was invoked once per (arm, rep) — 9 separate invocations for
  the base reps=3×3, rather than one `--reps 3` call per arm — to keep every
  single foreground `Bash` call comfortably under its 600000ms cap regardless
  of actual pi latency (observed 16s–183s; the huge B/C-bundle system prompts
  were not reliably the slow ones — several finished in 19–27s).
- **Grading**: `run-skill-eval.py`'s own single-shot grader (fed the
  concatenated `plant.md`) is not what the table below uses — a 3-plant
  criterion in one grading call produces ambiguous or unparseable verdicts
  (several `ungraded` results in the raw run logs). Instead, every saved
  transcript was re-graded three times, once per `plant-{a,b,c}.md`, by
  importing `run-behavioral-eval.py`'s `grade()` + `isolated_config()`
  verbatim (same reuse pattern `run-skill-eval.py` itself uses) from a
  throwaway script in the scratch dir — pure grading, zero additional
  DeepSeek/pi cost. One grader call hit a JSON parse failure
  (`C_bundle` rep 1, plant C) and was retried directly (`caught: false`,
  consistent with its sibling reps) rather than left `ungraded`.
- **Confirmatory batch**: the base reps=3 run left Plant C at B_bundle 2/3
  vs. C_bundle 1/3 — a 1-catch gap, below the ≥2-catch threshold that would
  require a diagnosis, but close enough to be noise-sensitive at n=3 (the P2
  pilot's own documented lesson: single-rep swings at reps=3 aren't a signal
  until they hit ≥2 or repeat). Ran 2 more reps each for B_bundle and
  C_bundle (4 more subject calls) targeting Plant C specifically; the gap
  closed to a tie (3/5 vs. 3/5) — confirms the base-batch reading was noise,
  not a regression.

### Results (n=3 for A_none, n=5 for B_bundle/C_bundle)

| plant | A_none (no skill) | B_bundle (main, pre-P1) | C_bundle (working tree) | gate (C≥B) |
|---|---|---|---|---|
| A — data-contracts (join fan-out) | 3/3 | 5/5 | 5/5 | **PASS** (tie) |
| B — causal-identification (bad control) | 0/3 | 5/5 | 5/5 | **PASS** (tie) |
| C — result-verification (prior-number reconciliation) | 3/3 | 3/5 | 3/5 | **PASS** (tie) |

**Gate verdict: PASS on all three plants.** No plant shows a C_bundle loss of
any size, let alone ≥2 catches, so the "identify which skill's content should
have caught it" branch never triggers — nothing to report there.

### Reading the numbers

- **Plant A and B both saturate at 5/5 for both skill bundles** — thinning
  (P1 + the per-skill loops) did not cost anything on either the join-fan-out
  catch (`data-contracts`) or the bad-control catch (`causal-identification`)
  when the two skills are stacked together with three others in one context,
  which is exactly the interaction-regression risk this phase exists to
  check. `A_none` at 0/3 on Plant B (every undefended rep folded
  `permit_readiness_score` into the headline without comment) confirms the
  plant is doing real work — it isn't a magnitude tell a generic model would
  catch unaided (contrast with the fan-out plant, which baseline also gets
  right, consistent with the P2 pilot's note that duplicate-key catches
  don't always need the discipline to fire).
- **Plant C's baseline-beats-both-bundles pattern (3/3 vs. 3/5 vs. 3/5) is a
  harness artifact, not a content regression.** Both skill bundles correctly
  induce a STOP-and-ask before finalizing a number once Plants A and B are
  spotted (`B_bundle` rep 1: "Before I lay out the full task plan, let me
  present the Design Card and the two issues that need your decision" /
  `C_bundle` rep 1: "Shall I proceed with this plan?") — genuinely more
  disciplined behavior. But `run-skill-eval.py`'s pi runner is single-turn
  only (`REPLY:` gates are explicitly unautomated per the README), so a rep
  that stops before computing a fresh number never reaches the point where
  Plant C's criterion ("states BOTH the old and new figures / flags an
  actual discrepancy") can be satisfied, even though `plant-c.md` explicitly
  credits a disclosed stop-and-ask. Several stop-and-ask transcripts flag
  *that* the prior +8.0% will need revisiting once the bad control is fixed,
  without yet having a second number to contrast it against — a reasonable,
  strict "not yet caught" read by the grader. `A_none`, with no discipline
  pushing it to pause, runs the whole task in one shot and incidentally
  reconciles the prior number every time. This is the same class of issue as
  the P3 batch-1 finding on `pressure-roadmap-first` (a "before you act"
  process plant colliding with a single-turn harness) — not something a
  per-skill agent restricted to `skills/<name>/` can fix, and out of this
  agent's scope (`scripts/run-skill-eval.py` is off-limits here too).

## 2. Token footprint re-measure

Chars via `wc -c`; tokens estimated as chars/4. "Typical bundle" =
card + `using-causal-powers` + `question-framing` + `data-contracts` +
`causal-identification`. "Extended bundle" = typical + `analysis-checkpoints`
+ `executing-analysis-plans`.

| set | main (chars) | main (≈tokens) | working tree (chars) | working tree (≈tokens) | Δ chars | Δ % |
|---|--:|--:|--:|--:|--:|--:|
| card (`hooks/session-context.md`) | 8,936 | 2,234 | 8,741 | 2,185 | -195 | -2.2% |
| typical bundle (card + 4 skills) | 81,617 | 20,404 | 67,855 | 16,964 | -13,762 | -16.9% |
| extended bundle (+2 skills) | 114,446 | 28,612 | 95,959 | 23,990 | -18,487 | -16.2% |

Per-file working-tree vs. main (chars): `using-causal-powers` 19,210→17,015,
`question-framing` 18,053→14,145, `data-contracts` 16,415→13,519,
`causal-identification` 19,003→14,435, `analysis-checkpoints` 13,227→13,272
(**+45**, essentially flat — consistent with the per-skill loop's own note
that `analysis-checkpoints` legitimately grew slightly as the P1 dedup pass's
canonical locked-document-gate host), `executing-analysis-plans`
19,602→14,832. (For reference, the P4 co-firing bundle above —
typical-bundle skills + `result-verification` instead of the checkpoints/EAP
pair — is 99,088→83,433 chars, 24,772→20,858 ≈tokens, -15.8%.)

**Audit baseline was ~23k–29k tokens for the extended bundle.** Main's
extended bundle measures 28,612 tokens — the top of that range, confirming
the baseline was measuring the same thing. The working-tree extended bundle
now measures 23,990 tokens — just above the *bottom* of the original range,
a 16.2% reduction. The typical (4-skill) bundle shows a comparable 16.9% cut.

## 3. Trigger suite

`python3 scripts/eval-triggers.py` (Part A — free, <1s per case, runs the
real `hooks/prompt-router` against every case in `evals/trigger/*.json` and
diffs against the committed baseline) ran clean:

```
TOTAL (router = backstop)              91/168   178/178 ok   precision violations: 0
OK — no regressions vs baseline.
```

Zero precision violations, zero regressions against `router-baseline.json`,
`frontmatter_parse_check`/`frontmatter_cap_check`/`agents_md_sync_check` all
clean. As a second, independent confirmation (frontmatter blocks are what
both the router and every platform's skill picker actually read), diffed
every `skills/*/SKILL.md`'s frontmatter block (the section between the two
`---` fences) against `main` directly: **all 17 skills' frontmatter is
byte-identical to `main`** — no `description:` was touched by any per-skill
loop, exactly as expected since P3 explicitly scoped agents to skill bodies,
not frontmatter. Part B (`--live`, costs a `claude -p` call per case across
~168 cases) was not run — Part A plus the byte-identical frontmatter diff
already fully confirms the "no regression, nothing to investigate" premise
this task specified, and running ~168 extra API calls to reconfirm a known
byte-identical input would not have added information.

## Run count

13 real graded DeepSeek subject invocations used in the final table
(`A_none` ×3, `B_bundle` ×5, `C_bundle` ×5) + 1 discarded pre-bugfix smoke
run + 1 free 429 error before the provider fallback = **15 total subject
invocations**, well under the 45 cap. Grading (`claude -p`, not
DeepSeek/pi) added 39 per-plant grader calls (13 recs × 3 plants) + 1 retry,
none of which count against the subject budget.

## Files touched

- `evals/behavioral/scenarios/p4-integration/` (new: `generate.py`,
  `task.md`, `plant.md`, `plant-a.md`, `plant-b.md`, `plant-c.md`,
  `data/bid_quarterly.csv`, `data/bid_registry.csv`, `data/codebook.md`,
  `data/prior_readout.md`)
- `evals/behavioral/notes/p4-integration.md` (this file, new)
- `evals/behavioral/runs/20260720-*` (13 valid + 2 discarded run dirs) and
  `evals/behavioral/runs/p4-integration-consolidated/` (`results.json` +
  `report.md`, the per-(arm,rep,plant) table this note's numbers are drawn
  from) and `evals/behavioral/runs/p4-integration-per-plant-grades*.json` /
  `*.log` (raw custom-grader output, kept for provenance)

No `skills/`, `hooks/`, `scripts/`, or `generate_all.py` file was read-write
touched; nothing under `skills/project-organization/` was touched or read.
No git write commands were run.
