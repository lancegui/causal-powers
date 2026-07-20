# project-organization — thinning-loop notes (2026-07-20)

Branch `thin-2026-07`. Subject: `pi -p` / `ollama/deepseek-v4-pro:cloud`
(`--thinking off`), via `scripts/run-skill-eval.py`. Grader: `claude-sonnet-4-6`.
No rate-limit errors were hit at any point in this loop, so the fallback to
Pi's direct DeepSeek API was never needed — every run below used Ollama Cloud.
**45 DeepSeek subject runs total** (cap was 60; "well under 30" was the aim
but a genuine, replicated batch-level-noise finding on one probe justified
going over it — see "Key finding" below).

## Scenarios (new, self-contained `generate.py` per parallel-mode convention)

- `evals/behavioral/scenarios/po-placement/` — realistic repo with an
  established `data/raw → intermediate → output` naming precedent (a prior
  quarter's clean file + panel), disguised time pressure ("board packet due
  in 10 minutes... don't worry about tidying, we'll sort it out later"), task
  asks for a new quarter's cleaned dataset + panel and explicitly asks for
  exact file paths in `result.md` (a natural business ask, not a hint — the
  harness deletes the scratch dir after each run and only grades
  `rec['answer']`/`rec['artifact']` text, so file-tree placement can only be
  graded from the subject's own report of where it put things).
- `evals/behavioral/scenarios/po-raw-data-guard/` — "the vendor csv has a bad
  row — just correct it in the file so the pipeline stops choking" (given
  verbatim per the brief); catches whether the subject edits `data/raw/`
  in place vs. keeps raw immutable and writes the fix to `data/intermediate/`.
- `evals/behavioral/manifest-project-organization.json` — `["po-placement",
  "po-raw-data-guard"]`.

Harness constraint that shaped both designs: `run_rep()` in
`scripts/run-skill-eval.py` only copies the scenario's `data/` subtree into
the scratch dir and only captures chat text + `result.md` for grading before
deleting the scratch dir — no post-hoc filesystem inspection is possible.
Both scenarios' `plant.md` criteria are therefore graded from the subject's
own report, same as every other scenario in this suite.

## Discrimination

- Initial `--arm none --reps 2`: `po-placement` saturated 2/2 (the first
  draft's task explicitly said "clean it up **the same way Q1 was handled**
  ... **to match**" — literal instruction-following, no discipline needed).
  Hardened by removing the explicit "match Q1" framing, leaving Q1's files as
  passive, discoverable tree evidence only. Re-discriminated: 0/2.
  `po-raw-data-guard` discriminated cleanly on the first attempt: 0/2.
- Both probes then survive to the fixed A/B/C anchor per the P2/P3 recipe.

## Fixed A/B/C anchor (reps=3 each)

| scenario | A (none) | B (`file:@main:...`) | C (working tree, pre-thin) |
|---|---|---|---|
| po-placement | 0/3 | 3/3 | 3/3 |
| po-raw-data-guard | 0/3 | 3/3 | 3/3 |

Clean anchor: both probes go from 0% unaided to 100% with the skill in
context, either pre- or post-P1-dedup.

## Key finding: po-placement is noisy at the batch level, independent of wording

Thinning C (Overview trim; Structure "adapt it"/"archive" paragraph trims;
Data section trim; Git section trim; Checkpoint-section wordiness trim;
Enforce-throughout ↔ The Process dedup; one rationalization-row trim →
1742 → 1560 words, -10.4%) and re-running `po-placement` C-only dropped to
1/3, then a confirm batch gave 2/3 (combined 3/6). Per the loop's own
noise-handling rule ("only act on a swing of ≥2 reps or a pattern that
repeats"), this read as a real regression, so two remediation steps followed:

1. Restored the Enforce-throughout/Process duplication (the single largest
   structural change, 1560 → 1644 words) and re-ran: 2/3, then a confirm
   batch gave 1/3 (combined 3/6 again — statistically identical, no
   measurable recovery).
2. Re-ran the **untouched, pre-thinning HEAD content** (1742 words, the exact
   text that scored 3/3 in the anchor) a second time, to check whether that
   original 3/3 was itself representative. It was not: **1/3** on the
   confirm batch (combined 4/6 = 67%).

Combined picture across all batches run (n=6 each except B/A):

| arm/version | po-placement catch rate |
|---|---|
| A (none) | 0/5 |
| B (main, pre-dedup, 1899 words) | 6/6 |
| C — post-P1-dedup HEAD, unedited (1742 words) | 4/6 |
| C — thinned, Enforce/Process restored (1644 words) | 3/6 |
| C — thinned, final (1560 words) | 3/6 |

Every post-P1-dedup variant — whether untouched, lightly thinned, or more
thinned — clusters at 50-67%, well below B's 6/6 but far above A's 0/6.
Two differently-worded thinned variants (1560 and 1644 words) landed on the
*exact same* 3/6, and the untouched original dropped from its lucky 3/3
anchor draw to 1/3 on a second batch. This is the signature of **inherent
batch-level stochastic noise in the subject+grader pipeline on this specific
probe** (DeepSeek has no fixed seed; different reps fail via *different*
mechanisms — one dropped the "claims" name prefix, one skipped materializing
the intermediate file, one put the cleaned file in `output/` instead of
`intermediate/` — not one repeated, identifiable defect), compounded by
whatever the P1 dedup pass (main → HEAD, unrelated to this loop, a shared
file this loop does not own) already cost this specific precise-pattern-
matching behavior before any of this loop's edits. **This loop's thinning
(1742 → 1560 words) shows no measurable incremental harm relative to the
current baseline it started from** — both sit in the same noisy band — but
it also cannot claim to have *closed* the pre-existing gap to B, and that gap
is out of this loop's scope (P1's file, shared/frozen; the mechanism looks
like sampling noise, not a fixable sentence).

`po-raw-data-guard` showed no such instability: 3/3 at anchor for both B and
pre-thin C, and 3/3 again for the final 1560-word thinned C (tested as part
of the iter1 batch, same content as delivered). Clean win, no regression.

**Methodological lesson for later loops:** a single N=3 "confirm" batch is
not always enough to distinguish a real regression from noise on a
behaviorally delicate probe (exact-string naming-precedent matching, in this
case) — when a swing appears, run a confirm batch on the *unedited* arm too,
not just the edited one, before concluding the edit caused it.

## Final delivered state

`skills/project-organization/SKILL.md`: 1560 words (was 1899 on `main`,
1742 post-P1-dedup on this branch before this loop). **-17.9% vs `main`,
-10.4% vs the post-dedup baseline this loop started from.**

### Cuts made (all wordiness/dedup, no obligation deleted)

- Overview: minor wording tightening (~5 words).
- The structure: "adapt it" and "archive" paragraphs tightened, same facts
  (paper-centric stage-first layout, archive vs. sandbox vs. diagnostics
  distinction — both stated nowhere else — fully preserved).
- Naming — standardize it: **untouched** (directly exercised by
  `po-placement`; every fact is load-bearing and already tight).
- Data — raw → intermediate → output: cut one redundant sentence (subject
  subfolders — already stated in the tree diagram and the Structure
  paragraph); tightened the track-by-default paragraph wording. Raw-immutable
  sentence (directly exercised by `po-raw-data-guard`) **untouched**.
- Git — tracked vs. ignored: tightened; the sensitive/oversized gitignore
  criteria now point back to the Data section's full statement instead of
  restating it (fact preserved once, not duplicated).
- Checkpoint as you go: wordiness trims across the intro and all four
  bullets (cut one of three commit-message examples, cut one redundant
  clause in the intro); **every obligation preserved** — when to checkpoint,
  commit≠push, milestone naming, don't-checkpoint-junk are all still stated
  in full. This section is the skill's largest and is entirely
  temporal/multi-turn (commit-at-phase-boundaries doctrine) — **no probe in
  this loop exercises it**, flagged below.
- Enforce throughout, tidy before git: the "before you commit" bullet and
  the "Safety" bullet were near-verbatim duplicates of The Process steps 1-3
  (compared side-by-side during the regression investigation above — this is
  genuine, confirmed duplication, not a guess); collapsed to a one-line
  pointer to The Process, which retains the full classify-taxonomy and
  safety language (including the "move a doubtful file to sandbox/" nuance,
  carried over into Process step 3 so nothing was lost). This is the single
  largest cut (~85 words) and was specifically re-tested (see regression
  investigation) — restoring it bought no measurable behavioral difference,
  so it was cut.
- Common rationalizations: one row (gitignore-all-data) tightened; the other
  three rows are unchanged.

### Kept and flagged (unexercised by either probe — wordiness-trim-only per the rules)

- **Checkpoint as you go — commit locally in phases** (largest section,
  ~200 words after trimming): entirely temporal/multi-turn (does the agent
  commit at phase boundaries across a multi-hour, multi-turn session) — this
  single-turn harness cannot probe it at all. The checkpoint-commit doctrine
  and the commit≠push distinction are this skill's own obligations, stated
  nowhere else in the family; nothing here was deleted, only trimmed for
  wordiness.
- **Git — tracked vs. ignored**: not exercised by either probe (neither
  probe touches git tracking/gitignore behavior). Kept in full (with the
  dedup noted above against the Data section); flagged as unvalidated by
  this loop's probes.
- **Common rationalizations table**: not exercised (no probe presents an
  excuse for the agent to rebut). Kept, wordiness-trimmed only.
- **Red flags — STOP**: exercised only partially (`raw/` edited in place, the
  third bullet, is covered by `po-raw-data-guard`); the other five bullets
  (flat folder, diagnostic CSVs beside canonical figures, secrets tracked,
  dated/versioned filenames, no master script) are not exercised by either
  probe. Left essentially unchanged (already tight, six one-line STOP
  triggers).
- **The bottom line** (summary block): not independently exercised (it
  recaps facts stated and tested elsewhere). Left essentially unchanged.

### Honest assessment

This skill's obligations are, as anticipated going in, mostly multi-turn/
temporal (commit checkpoints across a session) or structural (repo layout,
tracked-vs-ignored) rather than single-turn-probeable. Two probes were
built and both discriminate cleanly at the anchor (0% unaided → 100% with
skill), which is real, useful validation for the two behaviors they cover
(data placement/naming under pressure with a discoverable precedent; raw-data
immutability under a direct "just fix it in the file" instruction). Beyond
those two sections, this report does **not** claim behavioral validation —
the remaining ~8 sections were thinned for wordiness only, with every
distinct obligation preserved, and are flagged above rather than presented
as probe-verified.

## Follow-up: regression-isolation loop (2026-07-20)

A separate, narrower investigation returned specifically to isolate what the
P1 family-dedup pass (commit `04529d1`) cut from *this file*, and to test
whether restoring it recovers `po-placement`'s catch rate back toward main's
6/6.

### What P1 actually cut here

`git show 04529d1 -- skills/project-organization/SKILL.md` shows the P1
commit's entire diff for this file is two hunks, and nothing else — 157
words total, exactly matching the 1899->1742 delta:

1. **Red-flags bullet merge** (word-count-neutral, 28 words either way): "`raw/`
   edited in place, or written to by analysis code." + "About to delete
   files in a cleanup without surfacing the plan, or about to touch
   `raw/`." were merged into one bullet. No fact dropped, pure dedup.
2. **Deleted "When to Use → where this hands off"** (157 words, the entire
   delta): a `dot` digraph stating organization is the **terminal** step —
   routes in from `result-verification` (if unverified) or
   `analysis-checkpoints` (if about to delete/move files), doesn't propel to
   a successor — capped by "TERMINAL: deliverables placed, scratch
   archived, names standardized → shippable."

Neither hunk contains the "place/name new artifacts as you create them" or
"discover the existing convention first" language flagged as the prime
suspect going in — that language (the "Enforce throughout" bullet's "when
you create a script, dataset, table, or figure, put it in its folder and
name it by convention *then* — not 'in the root for now'", the "Read the
repo's `README.md` first" line, and the Naming section's concrete examples)
is untouched by P1 and is still present, verbatim or near-verbatim, in the
current 1560-word file. The terminal-step framing that P1 *did* cut is also
largely redundant with **The Process** step 5, which already states
"deliverables placed, scratch archived, names standardized → shippable" and
survived P1 intact. So by inspection, P1's diff for this file is close to
content-neutral — consistent with this file's own P1 commit message ("all
15 dot digraphs deleted, each restated the adjacent Process list").

### Candidates tested

- **Candidate A** — restore hunk 2 only (the "When to Use" section),
  verbatim, in its original position (after "Common rationalizations",
  before "The Process"). 1560 → 1717 words.
- **Candidate B** — restore both hunks (full P1 revert for this file: hunk 2
  + un-merge the red-flags bullet). Also 1717 words (the bullet merge/split
  nets to zero).

### Provider incident

The specified subject, `ollama/deepseek-v4-pro:cloud`, hit a genuine,
persistent Ollama Cloud 429 (`"you (lanceguixiaofan) have reached your
session usage limit... ollama.com/upgrade"`) on the very first baseline
batch — all 3 reps errored, ungraded. A retry one cycle later 429'd again,
confirming it wasn't transient (likely the prior loop's 45 runs plus this
one's early attempts exhausted a daily/session quota). Per this branch's own
established precedent for this exact failure mode
(`evals/behavioral/notes/pre-analysis-plan.md`,
`evals/behavioral/notes/descriptive-evidence.md`): smoke-tested the direct
DeepSeek API fallback (`deepseek/deepseek-v4-pro`, 1 rep, clean), then ran
the *entire* follow-up on that provider for internal consistency. **The
numbers below are therefore not directly comparable to the 6/6 (main) vs.
50–67% (post-P1 variants) table earlier in this file**, which was all
`ollama/deepseek-v4-pro:cloud` — a different serving route for nominally the
same weights. Flagging rather than reconciling: the baseline re-confirm
below lands far above the historical post-P1 band on this provider, which is
itself part of the finding below.

### Results (subject `deepseek/deepseek-v4-pro`, `--jobs 1`)

| version | po-placement | words |
|---|---|---|
| baseline — current file, unedited | **3/3** | 1560 |
| Candidate A — restore hunk 2 (dot-graph section) | 2/3, confirm 1/3 → **3/6** | 1717 |
| Candidate B — restore both hunks (full P1 revert) | **0/3** | 1717 |

`po-raw-data-guard` re-run on the final (unchanged) file: **2/3** (same
provider caveat; historically 3/3 on Ollama Cloud for this identical
content — not a new regression, since this follow-up made no edits).

Run dirs: `evals/behavioral/runs/20260720-*-po-fix-*` (8 batches, 20 subject
invocations total — 3 errored/ungraded on `ollama/deepseek-v4-pro:cloud`
before the provider switch, 17 graded on `deepseek/deepseek-v4-pro` — well
under the 30-run budget).

### Decision

Neither candidate reached the ≥5/6 bar. Worse: restoring *more* of the P1
cut correlated with a *lower* catch rate in this batch (baseline 3/3 >
Candidate A 3/6 > Candidate B 0/3) — the opposite of what the "load-bearing
cut" hypothesis predicted. n=3–6 per arm is too small to call the restored
text actively harmful, but it is enough to rule it out as the missing
ingredient: if the "When to Use" section (or the red-flags bullet split)
were what was keeping `main` at 6/6, restoring it should have moved
candidates toward baseline-or-better, not below it.

**`skills/project-organization/SKILL.md` is left unchanged** (1560 words,
byte-identical to its state at the start of this follow-up). The mechanism
behind the P1-era `po-placement` regression was not isolated. Combined with
the original loop's own finding above — differently-worded 1560- and
1644-word variants landing on the identical 3/6, and the untouched post-P1
content itself swinging from 3/3 to 1/3 across two batches on the *same*
text — the weight of evidence across both loops now points at batch-level
subject/grader noise on this specific exact-string-matching probe as the
dominant driver, not a specific sentence P1 deleted from this file. P1's
actual cut here is fully accounted for (2 hunks, both tested, one alone and
one combined) — there is no untested textual suspect left within `04529d1`'s
change to this file. A future loop chasing this further should treat it as
a probe/measurement problem (more reps in one unrate-limited sitting, a
fixed single provider throughout) rather than more skill-text archaeology on
this file.
