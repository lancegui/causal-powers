# new-doctrine probes — first run (2026-08-24)

Branch `thin-2026-07`, plugin git `bbb0d70`. Four probes authored for the
doctrine that landed this week: `348f8cb` (check placement — NA map, merge
protocol, kill the check inventory), `5c6f098` (verification confirms
robustness, never initiates it; figure notes are manuscript prose),
`bbb0d70` (check budget ~4 checks for a single-join script).

Subject `claude-haiku-4-5` via `scripts/run-behavioral-eval.py`, grader
`claude-sonnet-4-6`, isolated config `True` on every run. Arms **baseline**
(nothing) vs **plugin** (the real plugin installed into its own config —
hooks + skills + agents). The runner has no `--reps` flag, so each rep is a
separate invocation; all run dirs are listed per rep below.

Suite manifest: `manifest-doctrine.json` (hand-written, per the
"per-skill manifests are written by the agents that own them" convention —
`generate_all.py` does not write it and therefore never clobbers it).

## Probe suite (4 new, all self-contained generate.py)

- **na-is-information** (seed 4201, `data-contracts` merge protocol) —
  county-month outcome panel (120 counties x 24 months) plus an adoption
  file containing ONLY the 72 ever-adopting counties (60%). After the left
  join, `adopt_month` is NA for 1,152 of 2,880 rows (48 counties, 60.0%
  match rate) — and those NA rows ARE the never-adopter control group the
  requested TWFE DiD runs on. Effects are heterogeneous by cohort and ramp
  over 6 months, so dropping the unmatched rows leaves an ever-adopters-only
  sample with only forbidden already-treated comparisons. True ATT `+1.654`;
  TWFE keeping the NA rows `+1.654`; TWFE after dropping them `+1.145`
  (−31%). Held iff BOTH the post-join NA/match rate is surfaced AND the
  never-adopters survive into the estimation sample. **Gate scenario** —
  carries a `REPLY:` line (see harness note below).
- **check-budget** (seed 4301, `data-contracts` check budget) — the
  inverted probe: two clean files, `store_id` a unique key, 900/900 rows
  match, zero missing values, nothing to defend. Held iff the pasted script
  is correct (net sales by region, total 226,165.02, West first at
  60,603.56) AND carries ≤5 checks AND creates no `checks/` file, no
  robustness code, and no assertions against threats this data does not
  contain. 6–7 checks is graded a miss with the band named in the evidence
  string — that is the "inventory reborn inline" band.
- **verification-confirms-not-runs** (seed 4401, `result-verification`
  item 4) — a finished pilot readout (`readout.md` + `analysis.py` +
  600-row participant file). The headline `+5.04` (SE 0.61, 95% CI
  [+3.86, +6.23]) is CORRECT and reproduces exactly; nothing is planted.
  No robustness was ever proposed or approved and the prompt never mentions
  it. Held iff the subject reconciles/reproduces the number AND does not
  autonomously RUN new specifications — proposing them for approval counts
  as held.
- **no-notes-under-figure** (seed 4501, `figure-craft` notes ban) — a
  16-year tidy trend (44.96 → 88.06) shipping `n_districts` and `source`
  columns as note bait. Statically checkable from the pasted plotting code:
  held iff no `labs(caption=)`, no `figtext`/`fig.text`, no below-axes note
  block renders source/N/spec metadata into the figure. Titles, subtitles,
  axis labels are explicitly fine; so is putting source/N in `result.md`
  prose, which is the correct destination. Figure RENDER quality stays
  un-probed per the README's known limitation.

All four use neutral business phrasing — no skill vocabulary ("contract",
"NA map", "robustness", "notes") appears in any task prompt. Probes 1, 2 and
4 ask the subject to paste its script into `result.md`, the
`ac-proportionality` convention that makes script-level criteria visible to
the grader without inspecting the scratch dir (the runner deletes it, and
`grade()` sees only the chat answer + `result.md`). This is why no runner
change was needed to express the restraint rubric.

## Results

v1 as-authored, both reps (runs `20260824-102501`, `20260824-102926`):

| scenario | baseline r1 | baseline r2 | plugin r1 | plugin r2 |
|---|---|---|---|---|
| check-budget | ❌ | ✅ | ✅ | ✅ |
| na-is-information | ✅ | ✅ | ❌ (gate artifact) | ✅ |
| no-notes-under-figure | ✅ | ✅ | ✅ | ✅ |
| verification-confirms-not-runs | ❌ | ❌ | ❌ | ❌ |

v2 hardened, both reps (runs `20260824-103828`, `20260824-104018`):

| scenario | baseline r1 | baseline r2 | plugin r1 | plugin r2 |
|---|---|---|---|---|
| na-is-information | ✅ | ❌ | ❌ | ✅ |
| no-notes-under-figure | ❌ | ❌ | ✅ | ✅ |

Final read per probe (v2 where hardened):

| scenario | baseline | plugin | verdict |
|---|---|---|---|
| no-notes-under-figure | 0/2 | 2/2 | discriminates cleanly |
| check-budget | 1/2 | 2/2 | discriminates |
| na-is-information | 1/2 | 1/2 (2/3 incl. gated v1) | off saturation, noisy at 2 reps |
| verification-confirms-not-runs | 0/2 | 0/2 | floor — real doctrine finding, see below |

Evidence highlights: `no-notes-under-figure` plugin r1 — "Source/N appear
only in result.md prose, not in the figure"; baseline both reps rendered the
metadata under the plot. `na-is-information` plugin r2 — "result.md states
'48 control counties (never-adopted)'; left join recodes NA adopt_month as
treated=0, keeping all 48 as controls; estimate = 1.654" (exactly the
generator's correct value). `check-budget` plugin both reps — zero checks,
correct numbers, no inventory.

## Two probes hardened for saturation (the expected iteration)

**no-notes-under-figure v1 → v2.** v1 saturated baseline 2/2: with the
metadata merely present as columns, undefended haiku had no reason to render
it. v2 adds a business NEED for it without ever naming a caption, note or
footnote — "this crowd always wants to know where the numbers came from and
how many districts are behind them, so make sure I'm covered on that". The
metadata is now demanded and only the DESTINATION is in question. Baseline
went 2/2 → 0/2, plugin stayed 2/2: the cleanest discrimination in the suite.

**na-is-information v1 → v2.** v1 saturated baseline 2/2 because the prompt
literally said "with the counties that never started the program serving as
the comparison group" — a reading affordance handing over the answer to the
keep-half of the criterion (README P2 lesson 2). v2 deletes that clause (the
design is still fully specified as county+month TWFE DiD) and adds a
disguised invitation to filter: "the adoption file only covers the counties
the program office tracks, so it won't line up one-to-one with the panel —
don't let that trip you up." This deliberately makes surfacing easier and
keeping harder, which is exactly the doctrine's distinction. Baseline 2/2 →
1/2. Still noisy at 2 reps; the v2 plugin miss was a genuine half-miss —
the subject produced `+1.654` (so it KEPT the never-adopters) but never
tabulated the unmatched rows, failing the surface-half. The rubric behaved
as designed.

## Harness note — na-is-information needed a `REPLY:` gate

In v1 rep 1 the plugin arm wrote no `result.md` and graded a miss. The
transcript shows the opposite of a failure: it presented the estimating
equation, named the estimand, flagged the staggered-adoption/forbidden-
comparison problem, correctly stated "72 counties; 48 never adopt", and
stopped to ask for sign-off before estimating. This is the P3 batch-1
pitfall #1 verbatim — a criterion scoped to the final artifact wrongly
failing a MORE disciplined response that stopped to ask.

Fix applied is the harness-sanctioned one for gate scenarios: a `REPLY:`
line in `task.md` ("that all sounds fine, go ahead and run it and give me
the number"), stripped from the prompt and sent as turn 2 via `--resume`.
With the gate in place the same arm ran the estimate and graded a clean
catch in rep 2. `plant.md` also now credits a disclosed stop-and-ask that
states the never-adopter count as satisfying the surface-half, per the
standing grading convention. Note the cost: the gated arm took 436s vs ~30s
ungated.

## The one real negative result

**`verification-confirms-not-runs` is a floor: 0/4, baseline AND plugin.**
Both arms verified the headline correctly and then went on to run
specifications nobody approved — plugin r1 ran site-by-site effects
(Fairview +3.98, Lakeshore +3.22, Oakdale +8.10, Riverside +4.92) plus a
leave-one-site-out; plugin r2 ran a site-stratified re-estimate. The
doctrine in `5c6f098` ("never initiate robustness here — proposing
robustness is an upstream user decision") is **not currently inducing the
behavior it specifies** on this subject.

This is NOT the undiagnosable process-plant floor described in the README's
P3 pitfall #2: the behavior is fully visible in the final artifact, the
grader detected and quoted the offending specs in every rep, and the
distinction it is scoring (running vs offering) is unambiguous in the
transcripts. Treat it as a genuine finding about the doctrine's reach, not a
probe bug — the probe works, the doctrine has not landed. Recommended next
move: this is a candidate for a `run-skill-eval.py` A/B on
`result-verification`'s own text rather than more `plugin`-arm reps, since
the plugin arm already shows the skill body is being read and still does
not hold the line.

**Budget:** 24 subject runs (16 for v1 both reps, 8 for the two v2 probes),
at the top of the ~16–24 allowance. No run hung; the slowest was the gated
`na-is-information` plugin arm at 436s, well inside the runner's 900s cap.
