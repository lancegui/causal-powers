# `predictive-modeling` thinning loop — notes (2026-07-20)

Branch `thin-2026-07`. Scope: `skills/predictive-modeling/` only (SKILL.md +
references/) plus `evals/behavioral/scenarios/pm-*`,
`evals/behavioral/manifest-predictive-modeling.json`, this notes file, and
`evals/behavioral/runs/*pm-*`. No shared files touched (`generate_all.py`,
the behavioral README, other skills' manifests).

## Word counts

| File | main | pre-loop (post-P1 dedup) | final (this loop) |
|---|--:|--:|--:|
| `SKILL.md` | 4228 | 3513 | **2903** |
| `references/leakage-and-splits.md` | 2411 | 2411 | 2411 (unchanged) |
| `references/prediction-regimes.md` | 2414 | 2414 | 2414 (unchanged) |
| **Total** | **9053** | **8338** | **7728** |

`SKILL.md` cut 610 words (17.4%) below the pre-loop working tree, 1325 words
(31.3%) below `main`. Predictive-modeling was the family's third-largest
skill (3513 words post-P1, behind descriptive-evidence 4178 and
structural-estimation 4046) — this is a substantial cut relative to that
starting point.

References were left byte-identical. Two reasons, not just caution: (1) Pi
has no Skill tool in this harness (per the plan doc's scope note), so the
`file:skills/predictive-modeling/SKILL.md` arm injects **only** SKILL.md —
references are never read by the subject in any of these runs, so a
reference-file cut cannot be behaviorally verified by this loop at all; (2)
on inspection the references are not bloated relative to SKILL.md — the
redundancy ran in the other direction (SKILL.md restating mechanics the
references already own in full), which is what this loop's cuts fixed by
tightening SKILL.md's explanations into pointers (e.g. the permutation-null
bullet now points to `leakage-and-splits.md` §3 instead of re-deriving the
imbalanced-data trap inline; the nested-CV bullet points to §4). Per the
THINNING RULES ("unsure = keep and flag"), the reference files are flagged
as **not cut, not independently verified as needed** — a future pass with a
Claude-subject harness (which does load Skill-tool references) could extend
verification there.

## Probes

| scenario | plant | discipline exercised | new/existing |
|---|---|---|---|
| `leakage-overlap` | 90/200 test rows are exact duplicates of train | "prove the evaluation is honest" / train-test overlap check | existing (reused as-is, data untouched) |
| `pm-deployment-split` | panel loan data; true score→default relationship ROTATES across 8 quarters (credit_score→debt_to_income); deployment is temporal, random 5-fold CV inflates AUC 0.707 vs 0.643 temporal-holdout | Prediction Spec row 5 / "split must mirror deployment" | new, authored this loop |
| `pm-importance-not-causal` | `support_tickets_opened_90d` is a pure proxy for a latent `dissatisfaction` variable that drives both ticket volume and churn (zero direct causal term); RandomForest importance ranks it #1 (0.596 vs next at 0.155) | "prediction is not causation" / importance ≠ causal effect | new, authored this loop |

Both new scenarios ship a **self-contained `generate.py`** (numpy/pandas/
scikit-learn only) that deterministically writes `data/`, fits the reference
model, and writes `task.md` + `plant.md` with the actual computed numbers —
no dependency on `evals/behavioral/generate_all.py`. Re-running
`generate.py` reproduces identical output (fixed seeds).

## Discrimination (recipe step (a): `--arm none --reps 2`, then topped up)

| scenario | baseline (`none`) result | action |
|---|---|---|
| `leakage-overlap` | 0/3 | kept as-is, no hardening needed |
| `pm-importance-not-causal` | 0/3 | kept as-is, no hardening needed |
| `pm-deployment-split` v1 | 3/3 caught (saturated) | **hardened once** |

`pm-deployment-split` v1 saturated because DeepSeek v4 Pro applies "don't
shuffle time-ordered data" as generic, model-agnostic ML hygiene — the same
"mechanically-verifiable plants saturate baseline unaided" pattern the P2/P3
loops documented for join-cardinality and unit-scale checks. Hardened to v2
by disguising the pressure as ordinary business framing (per the accumulated
lesson: disguise, don't name the trap) — `task.md` now claims a random
80/20 holdout is "the data science team's standard practice ... for
comparability," an authoritative-sounding instruction toward the wrong
split. v2 discriminates cleanly: 0/3 baseline (transcripts show the subject
following the "standard practice" framing and mentioning temporal
validation only as a *future* next step, not as a correction to the
headline number). No leakage-overlap-style hardening was needed for the
other two probes — first draft cleanly discriminated.

## Fixed A/B/C anchor (recipe step (b), reps=3, run once)

Arms: A = `none`; B = `file:@main:skills/predictive-modeling/SKILL.md`
(4228 words); C = `file:skills/predictive-modeling/SKILL.md` (working tree
at the time of the anchor run — the pre-loop 3513-word post-P1 candidate,
"C0").

| scenario | A (none) | B (main, 4228w) | C0 (pre-loop, 3513w) |
|---|--:|--:|--:|
| `leakage-overlap` | 0/3 | 3/3 | 3/3 |
| `pm-deployment-split` (v2) | 0/3 | 3/3 | 3/3 |
| `pm-importance-not-causal` | 0/3 | 2/2 graded (1 ungraded rep) | 3/3 |
| **total** | **0/9** | **8/8** | **9/9** |

Clean discrimination: the skill (either version) takes DeepSeek v4 Pro from
0/9 to ceiling on all three probes. This is the fixed comparison target for
every later thinning pass.

## Thinning iterations (recipe step (c): C-only reruns against the fixed A/B)

**Iteration 1 (C1, 3018 words):** trimmed Overview (evocative prose
tightened, core-principle sentence kept verbatim), the arm-routing table's
prose, Prediction Spec rows 1/2/3/4/6/7 (row 5 — split design, the
`pm-deployment-split`-relevant row — left substantively intact), the label-
regime bullets (unexercised by any probe → wordiness-only trim, flagged),
and the "prove the evaluation is honest" bullets (deduped against
`leakage-and-splits.md` §3/§4 — pointers strengthened, inline mechanics
shortened). Also **added** one reinforcing clause to "Prediction is not
causation" naming the "which lever to pull" framing explicitly as a causal
question in prediction's clothing — a deliberate strengthening aimed at the
`pm-importance-not-causal` probe's exact framing, not a cut.

Result: **9/9** (reps=3, all three scenarios) — no regression from C0.

**Iteration 2 (C2, 2903 words, FINAL):** further wordiness trims only, all
in low-risk areas: Overview (2 more sentences tightened), the arm-routing
prose (further tightened, no claim removed), the Red-flags and Common-
rationalizations tables (every row/claim kept, phrasing compressed), and
the Process checklist (light trim). None of iteration 2's edits touched
Prediction Spec row 5, the "prove the evaluation is honest" bullets, or the
"prediction is not causation" section — the three blocks each probe most
directly exercises were untouched after iteration 1.

Verification of C2 was **interrupted by an Ollama Cloud session-usage limit**
(HTTP 429 "session usage limit," not a transient rate limit — plausibly the
shared account under concurrent load from the parallel per-skill agents).
The first C2 reps=3 batch (9 runs) errored out completely, ungraded, and
still counted against the run budget per the house rule ("a rep that errors
out ... counts toward budget"). Per an explicit mid-loop instruction, the
subject was switched to Pi's direct DeepSeek API
(`--model deepseek/deepseek-v4-pro`, same underlying model weights, no
Ollama Cloud in the path) for the remainder of the loop. Budget remaining
after the errored batch (3 runs) permitted only a **thin, n=1-per-scenario**
re-verification of C2 on the new subject, not a full reps=3 re-anchor:

| scenario | C2 (2903w), n=1, subject = direct DeepSeek API |
|---|--:|
| `leakage-overlap` | 1/1 caught |
| `pm-deployment-split` | 1/1 caught |
| `pm-importance-not-causal` | 1/1 caught |
| **total** | **3/3** |

No regression observed, but this reading is lower-confidence than C1's full
reps=3 result for two compounding reasons: (a) n=1 per scenario is within
the noise band the P2 pilot documented for single-rep reads, and (b) the
subject's serving path changed (Ollama Cloud → Pi's direct DeepSeek API)
between C1's verification and C2's, so it is not a strictly like-for-like
rerun of the fixed anchor. The theoretical risk is assessed as low — every
iteration-2 edit was wordiness-only and none touched the three
probe-exercised mechanisms — but this is flagged rather than asserted as
equally solid to C1. **C2 is shipped as final** on the combination of (i)
the low-risk nature of the specific edits, (ii) the clean 3/3 empirical
read, and (iii) exhausted run budget preventing a fuller re-check; if a
future pass has budget to re-run C2 at reps=3 on a consistent subject, that
would raise confidence but is not expected to change the verdict given (i).

## Run budget

60 DeepSeek subject runs allowed. **57 used, 3 remaining** (preserved as
reserve, not spent). Breakdown:

| stage | runs |
|---|--:|
| `pm-deployment-split` v1 timing test | 1 |
| First discrimination attempt (3 scenarios × 2 reps; subject succeeded, grading failed on a separate Claude session-quota issue, retried) | 6 |
| Discrimination retry (graded) | 6 |
| `pm-deployment-split` hardening v2 test | 2 |
| Anchor arm-A top-up (3 scenarios × 1 rep) | 3 |
| Anchor arms B+C (3 scenarios × 2 arms × 3 reps) | 18 |
| Iteration 1 C-only (3 scenarios × 3 reps) | 9 |
| Iteration 2 C-only, Ollama Cloud (all 9 errored — session-usage limit) | 9 |
| Direct-DeepSeek-API smoke test | 1 |
| Iteration 2 C-only, direct DeepSeek API (n=1 × 2 remaining scenarios) | 2 |
| **Total** | **57** |

## Kept-and-flagged (unsure = keep, per THINNING RULES)

- **references/leakage-and-splits.md, references/prediction-regimes.md** —
  not cut. Not behaviorally verifiable by this harness (Pi never reads
  them); on inspection they are the detail source SKILL.md's shortened
  pointers now lean on more heavily, so gutting them would undercut the
  SKILL.md cuts. Flagged for a future Claude-subject pass.
- **"The label decides the regime" section** (proxy/anomaly/ranking
  regimes) — none of the three probes exercise the proxy-label,
  no-label/anomaly, or ranking-triage regimes specifically (all three probes
  are clean-label). Trimmed for wordiness only, no bullet/claim removed,
  flagged as unexercised.
- **"Why are you modeling?" arm-routing section** (double/debiased ML,
  causal forests, uplift/CATE dual-gate) — this is the skill's owned
  fork-definition, referenced (in their own words, not by pointer) from
  `structural-estimation`, `question-framing`, `causal-identification`, and
  `using-causal-powers`; none of the three probes exercise routing behavior
  directly. Every substantive claim (route by goal not algorithm;
  double/debiased ML is NOT this skill; uplift/CATE runs both gates)
  preserved verbatim in substance; only prose wordiness cut. Flagged.
- **Locked-document-gate pointer to `analysis-checkpoints`** — left
  completely untouched (already minimal, one-line pointer per the P1 dedup;
  no probe in this suite exercises the sign-off gate itself since the pi
  harness is single-turn only, per the P3 finding on gate scenarios).

## Methodology lessons for later agents

1. **A generic-ML-hygiene plant can saturate baseline even when authored
   fresh, not just inherited.** `pm-deployment-split` v1 (an explicit,
   unhidden `application_quarter` column + "go/no-go" framing) was caught
   2-3/3 unaided — "don't shuffle time-series data" is now baseline
   knowledge for this model, same as join-cardinality and unit-scale
   checks in the P2 pilot. Disguising the pressure as an authoritative
   "team standard practice, for comparability" (not naming splits,
   randomness, or leakage) fixed it to 0/3 in one hardening pass — don't
   assume a self-authored probe is safe from the same saturation dynamic
   that hit inherited ones.
2. **Constructing a genuine split-vs-deployment plant needs a DGP where
   test-period separability is held constant, not just "add drift."** A
   first DGP draft (monotonically strengthening a fixed feature's log-odds
   coefficient over 8 quarters) produced a gap in the WRONG direction
   (temporal-holdout AUC 0.89 > random-CV AUC 0.78) because later quarters
   became inherently more separable, and AUC being rank-based rewards that
   regardless of whether the model's coefficients are stale. Fixing this
   required a **rotation** design (credit_score's weight fades while
   debt_to_income's grows, total effect magnitude held ~constant across
   quarters) so no quarter is inherently easier — only then does a
   compromise-fit random-split model actually look better than a
   correctly-temporal one trained on stale weighting. Verify the sign of a
   constructed gap before trusting the plant, not just its existence.
3. **A confounded-proxy causal-misread plant is straightforward to author
   and discriminates immediately.** `pm-importance-not-causal`'s DGP (a
   latent unobserved cause driving both a highly-visible proxy feature and
   the label, zero direct causal term for the proxy) needed no hardening —
   0/2 on the first try. The inverted/over-delivery pressure ("if you can
   put a rough number on how much churn would drop ... even better") for
   this restraint-type obligation matched the accumulated lesson and may
   have contributed to the clean discrimination; a version asking only for
   a ranked list (no magnitude ask) was not tested and might have been
   softer.
4. **`file:skills/<name>/SKILL.md` only injects SKILL.md — references are
   invisible to this harness by construction (Pi has no Skill tool).** This
   means reference-file cuts in a per-skill loop are structurally
   unverifiable here, not just under-tested; treat any reference-file edit
   in these loops as judgment-only, and say so explicitly rather than
   implying the eval covered it.
5. **An Ollama Cloud "session usage limit" (429) is a harder stop than a
   transient rate limit** — 9/9 reps in one batch errored immediately
   (12-35s each, consistent with an instant rejection, not a real
   generation) rather than a few scattered failures. Under concurrent
   parallel-agent load sharing one account, treat this as a signal to
   switch serving path (Pi's direct provider API, same model weights)
   rather than retry-with-backoff on the same path — retrying would have
   burned budget for the same rejection. Once switched, a full anchor
   re-run for strict cross-provider consistency is usually not affordable
   under a tight remaining budget; the pragmatic fallback is a thinner
   same-subject spot-check on the affected candidate, clearly flagged as
   lower-confidence than the reps=3 anchor it's checked against.
6. **Backgrounding on a Bash-tool timeout truncates `| tail -N` output to
   nothing until the pipeline closes** — `tail` with a fixed line count
   can't emit partial results while its stdin is still open, so a
   long-running foreground command piped through `tail` that gets
   auto-backgrounded shows no interim output at all via the usual
   read-the-output-file check. Watching the run directory's per-rep JSON
   file count (written before grading) is a reliable progress signal
   instead; a `Monitor`/`until`-loop on that file count is the right tool,
   not repeated polling of the backgrounded command's own stdout capture.
