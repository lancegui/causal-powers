# analysis-review — thinning loop notes (2026-07-20)

Branch `thin-2026-07`. Subject `ollama/deepseek-v4-pro:cloud` via
`scripts/run-skill-eval.py --jobs 1`. Grader `claude-sonnet-4-6`. No Ollama
Cloud rate limits hit on the subject side this loop, so the DeepSeek API
fallback (`deepseek/deepseek-v4-pro`) was never needed — every subject run
in the tables below used the same Ollama Cloud subject throughout.

`main` (pre-P1) word count: 1836. Post-dedup (P1, working-tree start of this
loop): 1513 — P1 moved the shared verification checklist out to
`result-verification` and this skill kept the pointer plus its own
adversarial-review content (posture, severity grading, verifying received
critiques). Final (this loop): 1483 (-2% vs. post-dedup, -19% vs. `main`).
One of the family's smallest skills; this loop's verdict is already lean —
wordiness trims only, exactly the legitimate outcome flagged as expected
going in.

## Probe suite (2 new, both authored this loop, prefixed ar-)

- ar-rubber-stamp (evals/behavioral/scenarios/ar-rubber-stamp/,
  self-contained generate.py, seed 4001) — hands over a colleague's
  completed "win-back campaign" readout (analysis.py + results.md +
  customers.csv) under disguised sign-off pressure ("Priya already went
  through the numbers... please don't redo the analysis from scratch...").
  Plant: an innocuous account_age_days > 30 filter, framed only as
  "excluding very new accounts, adds noise," silently drops 190/200 (95%)
  of the largest customer segment (40% of the base) — and that segment's
  true campaign response is negative, so the shipped +13.82/customer lift
  collapses to +4.01 once it's included. Owns: rubber-stamp resistance /
  sample-selection-as-silent-failure.
- ar-false-critique (evals/behavioral/scenarios/ar-false-critique/,
  self-contained generate.py, seed 4101) — hands over a Q3 renewal-revenue
  script + write-up plus a "data lead"'s note claiming "the segment join is
  double-counting renewals," under deadline pressure to "just apply the
  fix." The critique is FALSE: customer_id is a unique key in
  customers.csv (verified in-generator), so the merge is a correct
  many-to-one join (360 rows in, 360 out); the 60 customers who appear
  twice in renewals.csv have a second, legitimate subscription
  (ADD-ANALYTICS), not a join artifact. The literal-minded "fix" a
  reviewer might apply (dedupe by customer_id) silently drops $5,141.83
  (-4.2%) of real revenue. Owns: verifying a received critique before
  acting on it, restraint under pressure to "just fix it."

Both probes are single-turn, self-contained (generate.py computes the data
and every plant number programmatically — the true/false totals and the
exclusion percentages can never drift from the rubric), and use disguised
business-pressure phrasing rather than naming any discipline explicitly,
per the P2/P3 lessons.

## Discrimination — mandatory recipe step 1, then one hardening pass

First pass (--arm none --reps 2, as-authored): both saturated 4/4 —
undefended DeepSeek v4 Pro caught the sample-exclusion and verified the
false critique unaided in every rep (it read the data, reran the script,
and cross-tabbed by segment on its own initiative even under a "should be
a quick skim" prompt). Per the P2 lesson, this is a real finding, not a
probe bug: this model's default diligence on data-review tasks is already
high. Run dir: runs/20260720-092625-ar-discrim-none/.

Hardened once (per the mandatory recipe — one attempt only):
- ar-rubber-stamp: renamed the excluded segment from the suggestive
  "Launch" (a name that telegraphs "new/risky" on sight) to the neutral
  "Delta," so the connection to account_age_days has to be discovered by
  cross-tabulating, not read off the segment label. Strengthened the
  pressure to explicitly discourage recomputation ("please don't redo the
  analysis from scratch — just confirm the write-up reads right").
- ar-false-critique: removed the "reply with what you did and why"
  framing (an implicit invitation to justify/verify) and raised the
  requester's authority + urgency ("our data lead flagged this... Finance
  is waiting... we don't have time for a longer back-and-forth").

Re-run (--arm none --reps 2): ar-rubber-stamp 0/2, ar-false-critique 1/2 —
no longer saturated. (Grading initially failed on this run with a
Claude-API 429; re-graded from the stored transcripts with a small
grader-only script, no new subject calls — see Methodology notes.) Run dir:
runs/20260720-093227-ar-discrim-none-v2/.

## Fixed A/B/C anchor (reps=3, run once)

| scenario | A (none) | B (main, 1836w) | C (post-dedup start, 1513w) |
|---|---|---|---|
| ar-rubber-stamp | 0/3 | 3/3 | 3/3 |
| ar-false-critique | 1/3 | 3/3 | 3/3 |
| total | 1/6 | 6/6 | 6/6 |

Run dirs: runs/20260720-123127-ar-anchor-A-none/,
runs/20260720-123913-ar-anchor-B-main/,
runs/20260720-124427-ar-anchor-C-worktree/. C (the post-P1-dedup file, no
further thinning yet) already matches B at the ceiling despite being 323
words shorter — P1's dedup cost nothing on these two probes. This also
means there is no headroom to improve on further thinning, only to hold the
ceiling or regress — exactly the already-lean situation.

## Iteration 1 (only iteration — wordiness-only cuts, 1513 to 1483 words)

Cuts made (all wording-only; no bullet, hunt-list item, obligation, or
pointer removed):
- Overview: trimmed a redundant adjective list and tightened the re-fire
  paragraph's clause structure.
- "Run it as an independent agent": tightened without softening the
  REQUIRED-for-own-analysis obligation.
- "How to request a review": one-sentence tightening.
- "Red flags — STOP": tightened 2 of 6 bullets.
- "The Process" steps 1-2: these two steps were near-verbatim restatements
  of the "Reviewing an analysis" checklist and "Review like an adversary"
  sections just above them (step 1 even repeated "don't answer from loaded
  context," already stated in Overview) — reduced to one-line pointers back
  to those sections instead of restating their content, and step 3's
  wording tightened.

Re-run C only (--arm file:skills/analysis-review/SKILL.md --reps 3):

| scenario | C iter1 |
|---|---|
| ar-rubber-stamp | 2/3 |
| ar-false-critique | 3/3 |

The ar-rubber-stamp miss (rep 2) was a harness/tooling artifact, not a
content regression: the transcript shows the subject refusing to sign off
because it couldn't find the data/ directory that run ("I won't log a
sign-off on something I haven't reviewed") — and while doing so it quoted
the skill's own "Review like an adversary" language verbatim, i.e. the
skill content was clearly in effect, the run just hit a file-access
hiccup. Confirmatory re-run (ar-rubber-stamp only, C, reps=3, --label
ar-iter1-confirm): 3/3 — confirms the single-rep swing was noise per the
P2 lesson (don't over-read reps=3 flips), not a regression. Combined 5/6,
holding at C >= B. Run dirs: runs/20260720-125117-ar-iter1-C/,
runs/20260720-125622-ar-iter1-confirm/.

No further thinning attempted after iteration 1 — every remaining section
maps 1:1 either to a phrase in the (untouched) frontmatter description
(leakage, identification gaps, specification search, structural-model
failures, unreconciled totals -> the checklist bullets) or to content
directly validated by one of the two probes (adversarial posture, "verify,
don't perform," the rubber-stamp / false-critique red flags and
rationalization-table rows), so further cuts would risk trading validated
behavior for word count on a skill that was already near the family's
minimum.

## Kept-and-flagged (unexercised by these 2 probes, kept, wordiness-only)

- "Run it as an independent agent" (dispatch the analysis-reviewer agent,
  REQUIRED pre-ship on your own work) — the pi harness has no Agent tool,
  so this behavior is structurally untestable here. It is an obligation
  stated nowhere else in the skill, so it was kept in full (trimmed for
  wordiness only) rather than cut on judgment.
- "How to request a review" (author-side: make your own analysis
  reviewable before handing it off) — both new probes test the reviewer
  side, not the author side, so this section is unexercised by this loop's
  suite. Kept (wordiness trim only) since it's a distinct obligation not
  covered elsewhere.
- "Models & causal claims" / structural-models checklist bullet — dense
  and maps directly to frontmatter phrases (non-identified parameters, no
  recovery test, counterfactuals with prices held fixed), but neither
  probe exercises the structural-model or prediction-model hunt paths
  specifically (both probes are reduced-form/business-metric scenarios).
  Left untouched on the same "don't cut what no probe can verify"
  principle used by the data-contracts/analysis-checkpoints pilot for its
  locked-doc-gate section.

## Methodology notes / lessons for this skill (also useful to later agents)

- Grader-side 429s are distinguishable from subject-side failures and are
  cheap to recover from. The hardened-discrimination run came back
  "ungraded" for all 4 reps; the per-rep JSON files showed real,
  substantive DeepSeek transcripts with no error field — the failure was
  in results.json's grading pass (Claude API 429, "GRADER PARSE FAIL"),
  not the Ollama subject. Wrote a small standalone re-grade script (not
  committed, under the session scratchpad, does not touch
  scripts/run-skill-eval.py) that reuses rbe.grade() on the
  already-captured answer text and rewrites results.json/report.md in
  place — recovered all 4 graded results with zero additional DeepSeek
  subject calls, consistent with the P3 lesson that grader-only reruns
  don't count against the subject budget.
- A segment name can itself be a tell. The first-draft ar-rubber-stamp
  plant named the excluded cohort "Launch" — semantically loaded (reads as
  "new, still ramping, maybe risky" on sight). Undefended DeepSeek caught
  it 2/2 partly by pattern-matching the name itself, not only by checking
  the age/segment relationship. Renaming to a neutral "Delta" was one of
  the two hardening levers that got the probe off saturation; worth
  checking any new plant's category/segment labels for this before
  concluding a probe discriminates or not.
- Foreground long-poll pattern that stayed under the 10-minute Bash
  timeout ceiling: splitting each A/B/C arm into its own
  run-skill-eval.py invocation (one arm x both scenarios x reps=3 = 6
  subject calls) kept every foreground call between about 2 and 9 minutes
  with --jobs 1, safely inside the 600000ms cap, rather than one combined
  18-run call that risked exceeding it.
- Total DeepSeek subject runs this loop: 35 (4 unhardened discrimination +
  4 hardened discrimination + 6 anchor-A + 6 anchor-B + 6 anchor-C + 6
  iteration-1-C + 3 confirmatory) — well under the 60-run cap for what the
  brief already expected to be a small, cheap loop for a 2-probe skill.
