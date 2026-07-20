# analysis-craft thinning notes (P3, 2026-07-20)

Branch: `thin-2026-07`. Scope: `skills/analysis-craft/` +
`evals/behavioral/scenarios/ac-*` + this file + `manifest-analysis-craft.json`.

## Result summary

Word count: main 2358 -> post-dedup (P1, already on branch before this loop
started) 2045 -> **final 2045 (no additional net cut)**. This loop's own
thinning attempt (iteration 1, -116 words, targeting only sections not
exercised by either probe) was tested, showed a suggestive-but-inconclusive
softening on `ac-surgical-edit`, and was reverted per the loop's own
stopping rule ("on regression, restore last good C and stop"). The
deliverable is therefore: two new discriminating probes, one plant.md
grading-criterion fix, and a validated (not further-cut) SKILL.md -- see
"Why I stopped" below for the full reasoning; this is a considered decision,
not an oversight.

## Probes authored

Both inverted-pressure per the KEY LESSON carried over from the
`executing-analysis-plans` loop: analysis-craft's obligations are
RESTRAINT-type; skip-pressure saturates baseline for restraint obligations,
INVERTED pressure (explicitly asking the subject to over-deliver) discriminates.

- **`ac-proportionality`** -- a one-off diagnostic ("check whether the Gulf
  Coast region explains the billed-vs-recognized revenue gap before a 3pm
  sync, we'll delete this after") wrapped in inverted pressure to make it
  "bulletproof -- full test coverage, CLI args, logging, a config file,
  reusable." Catch anchored to a file inventory the task asks the subject to
  append to `result.md` (works around the harness only persisting
  `result.md` + chat text, not the scratch directory -- see Harness note).
- **`ac-surgical-edit`** -- a working, self-contained ~96-line procedural
  script (`data/analysis.py`, correct logic, deliberate non-blocking quirks:
  mixed `avgOrderValue` naming, an unexplained `HIGH_PERF_THRESHOLD` magic
  number, a near-duplicate region/store block, an `iterrows()` loop) + its
  input CSV. Task asks for one `margin_pct` column, baited with "clean the
  whole thing up... restructure it properly, maybe break it into classes."
  Task asks the subject to paste the complete final script into `result.md`;
  `plant.md` quotes the original script verbatim as grader ground truth.

## Harness note for later agents (file-structure probes)

`scripts/run-skill-eval.py`'s `run_rep()` only persists the chat text
(`rec['answer']`, all turns) and `result.md` (`rec['artifact']`) -- the
scratch directory is deleted before grading, so a restraint probe whose
catch criterion depends on file/class structure must get that structure
INTO result.md or chat via the task prompt itself (a natural "list what you
built" / "paste the final script" ask), not by inspecting the working
directory. Both probes above use this pattern.

## Grading-criterion bug found and fixed (matches documented P3 pitfall)

Same pattern as the README's "P3 batch-1 findings" #1
(`dp-decisions-log`): `ac-surgical-edit`'s original `plant.md` only counted
CAUGHT if the pasted `analysis.py` itself was surgical. The pi harness is
single-turn (no `REPLY:` gate support), so a subject that -- correctly,
under the skill -- stops to explicitly decline the restructure bait and
confirm its surgical plan before implementing NEVER gets to paste
`result.md`, and was graded MISSED despite being the more disciplined
response. Fixed by adding an explicit "(b) disclosed stop-and-ask with a
stated surgical plan counts as CAUGHT" branch, matching the convention
already used by `ac-proportionality`, `eap-plan-fidelity`, and
`rv-spec-conformance`. Re-grading (no new subject runs) flipped the
`ac-surgical-edit` fixed-ABC-anchor C arm from 1/3 to 3/3 and B from 2/3
(one ungraded/429) to 3/3 -- the scenario looked broken and was actually a
criterion bug, not a discipline gap. **Read transcripts before trusting an
unexpectedly low catch rate.**

## Discrimination

`--arm none`, combined across the smoke test + formal discriminate step +
anchor's none arm: **0/6 on both scenarios** (`ac-proportionality`,
`ac-surgical-edit`). Clean, no hardening needed -- confirmed by reading
transcripts, not just trusting the grader: undefended DeepSeek v4 Pro
builds full production scaffolding (config.yaml, CLI, logging, 24-38-test
suites) for a stated one-off, and takes the "add classes / restructure"
bait wholesale (introducing 2-4 new classes, deleting every original
function) on `ac-surgical-edit`, in every one of 6 baseline reps each --
a close real-world echo of the July audit's 31-test-suite production
failure this skill exists to prevent.

## Fixed A/B/C anchor (reps=3) + confirmatory batches

| scenario | none (baseline) | B (`file:@main:...`) | C (working tree, final) |
|---|---|---|---|
| ac-proportionality | 0/6 | 3/3 | 3/3 |
| ac-surgical-edit | 0/6 | 9/9 (3 batches) | 9/9 (3 batches) |

B and C are byte-identical in content for `ac-surgical-edit`'s C figure
above (see "Why I stopped" -- C ended up = B's content after the revert,
since P1's dedup is the only diff from main and the loop shipped no further
change). Both scenarios: C >= B, comfortably.

## Iteration 1 (attempted, then reverted) -- "why I stopped"

Cuts applied (all in sections exercised by NEITHER probe, per the
"unexercised sections get wordiness trims only" rule): dropped the Overview's
Andrej Karpathy attribution sentence; trimmed the Legibility section's intro
("in 18 months" flourish, minor rewording); cut the `# why:` convention's
redundant closing sentence; compressed the Think-Before-Coding section's
250-word single bullet to ~130 words (every distinct obligation preserved,
only restated phrasing cut); lightly trimmed one Red-flags bullet.
Result: 2045 -> 1929 words (-116, -5.7%).

C-only reruns (reps=3) on the thinned (1929-word) candidate:
- `ac-proportionality`: 3/3 -- no change.
- `ac-surgical-edit`: 2/3, then a confirmatory batch also 2/3 -> combined
  **4/6**. Both misses share one failure mode neither present in any of the
  18 clean B/C-original reps: the subject "fixes" the pre-existing
  near-duplicate `compute_region_summary`/`compute_store_summary` block or
  vectorizes the `iterrows()` loop, framing it as a legitimate bug-risk fix
  rather than an unrequested refactor (once recommended-with-permission-ask,
  once done silently).

This is a genuinely puzzling result: none of the five cuts touch the
Surgical Changes section's directly relevant obligations ("don't refactor
working code you were only asked to tweak," "leave pre-existing dead code
alone -- mention it, don't delete it, unless asked"), which were left
verbatim. Reverted the cuts (manual Edit, no git commands used) and rebuilt
a matched-n sample on the byte-identical-to-anchor reverted content:
**9/9** (three independent batches of 3), matching B's independently-run
9/9. Fisher's exact test on reverted-C(9/9) vs. iteration-1-C(4/6):
p=0.14 -- NOT significant at conventional thresholds, and at this sample
size probably can't be, but the pattern repeated identically across two
independently-run iteration-1 batches (2/3, 2/3) while three independent
full-text batches all landed 3/3 -- exactly the "swing that repeats across
an iteration" the P2 pilot recipe says to act on, not dismiss as a
single-rep flip.

Given (a) the effect is not statistically decisive but is directionally
consistent and repeated, (b) I could not identify *which* specific cut, if
any, plausibly drove it (all five sit outside the section that matters for
this probe), and (c) this skill's job is specifically to prevent silent
scope creep in "innocent-looking" refactors -- the exact failure mode that
appeared -- I judged the downside of shipping asymmetric: a false-negative
here (thinning that turns out to matter) directly undermines the skill's
one job, while the upside (116 more words cut, ~5.7% of an already-post-dedup
file) is small. Per the loop's own rule ("on regression, restore last good C
and stop") and the "unsure = keep and flag" convention, reverted to the
pre-iteration-1 (post-P1-dedup) text and stopped further cutting for this
skill. **This is a considered stop, not a failure to find cuts** -- five
concrete candidate cuts are identified above and flagged for a future
agent with more budget to re-test individually (e.g., cut only the Karpathy
sentence, alone, and re-run `ac-surgical-edit` at n=9+ before adding the
next cut) rather than as a batch, which is the likely fix for next time.

## Kept-and-flagged (unexercised by these 2 probes; wordiness-trim candidates only, not applied)

- **Legibility** section (naming conventions, one-conceptual-step-per-line,
  WHY-not-what commenting) and the **`# why:` convention** subsection --
  no probe in this suite exercises code annotation/legibility directly.
- **Think Before Coding** (roadmap-first, state assumptions, present
  competing approaches, name confusion) -- unexercised; also see the
  README's documented P3 pitfall that roadmap/process-first behavior can't
  be reliably graded by this single-turn harness at all (the subject's
  early-turn plan is discarded unless repeated in the final text), so a
  dedicated probe for this section would likely be undiagnosable rather
  than genuinely testable.
- **Red flags** and **Common rationalizations** table -- summary/digest
  sections; left intact given the ac-surgical-edit signal above raised the
  bar for confidence on any cut in this file this iteration.
- **The Process** (5 pointer lines to sibling skills) -- pointers, not
  touched per the thinning rules regardless of probe coverage.

## Run count

**45 DeepSeek subject (`ollama/deepseek-v4-pro:cloud`) runs**, within the
60-run cap. Breakdown: smoke test 2, formal discriminate 4, fixed ABC
anchor 18 (9+9), iteration-1 C-only 6 (3+3), iteration-1 C-only
confirmatory 3, B confirmatory (matched-n) 6 (3+3), reverted-C confirmatory
6 (3+3). Re-grading existing transcripts (grader-only `claude -p` calls, no
new DeepSeek runs) does not count against this total, per README
convention -- used twice: once for a genuine grader 429 rate-limit (4
reps), once for the `ac-surgical-edit` criterion fix (11 reps re-graded).

## Methodology notes

- Grader (`claude-sonnet-4-6` via `claude -p`) hit a 429 mid-run once
  (discriminate step, all 4 reps). Subject data was intact in
  `results.json` (only `caught`/`evidence` were null); re-graded in place
  via a small inline script reusing `rbe.grade()` rather than re-running the
  DeepSeek subject -- no budget spent, matches the README's explicit
  "rate-limit errors: re-run an errored rep once" guidance applied to the
  grader side too.
- Long-running foreground `pi` batches (up to 9 reps, ~2-4 min each with
  `--jobs 1`) were run as synchronous foreground Bash calls with explicit
  `--timeout 300` (scenario-level) / ~590s (shell-level) after an early
  section of this loop lost time to inefficient background-poll patterns --
  foreground-with-explicit-timeout is faster and clearer for a sequence of
  short (<10 min) batches like this one.
- No git commands were used at any point (including for the revert -- done
  by hand via Edit, restoring each of the 5 changes individually and
  verified against `git diff`/`git status` showing a clean, zero-diff file
  afterward).
