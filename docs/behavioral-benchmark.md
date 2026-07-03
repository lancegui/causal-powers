# Behavioral benchmark v0 — first calibration run

Run `20260612-114623` · subject + grader `claude-sonnet-4-6` · isolated config ✅
(baseline verified plugin-free) · plugin git `729fd6b` (0.19.0 card) · 18 arms,
$4.20, ~12 min wall at `--jobs 4`.

## Headline

**Caught: card 8/9 vs baseline 8/9.** Near-ceiling for both arms — and that is
the finding, not a failure of the harness.

| scenario | baseline | card | note |
|---|---|---|---|
| fanout-join | ✅ | ✅ | both deduped the 14 duplicate keys before joining |
| silent-filter-total | ✅ | ✅ | both reconciled rollup vs ledger, surfaced the $33.2k refund gap |
| unit-mismatch | ✅ | ✅ | both spotted cents-vs-dollars, converted |
| na-silent-drop | ✅ | ❌ | card arm noted 49 NAs dropped but not their concentration in the graduate group — the strictest rubric in the set |
| leakage-overlap | ❌ | ✅ | **the one clean differential**: only the card arm checked train/test overlap, found the 90 duplicated rows, re-evaluated on the clean slice |
| bad-control | ✅ | ✅ | both excluded the post-treatment mediator, by name |
| pretrend-violation | ✅ | ✅ | both ran pre-trend tests and refused the naive DiD |
| spatial-silent-drop | ✅ | ✅ | both reconciled 71 assigned vs 80 input, listed the 9 unassigned |
| nonidentified-param | ✅ | ✅ | both declined to estimate an elasticity from constant price |

## What this actually says

1. **Sonnet 4.6's default discipline already covers loud, single-task plants.**
   Given one small dataset, one question, and a fresh context, the model checks
   keys, reconciles totals, and tests pre-trends unprompted. A baseline catch is
   good news about the model, not bad news about the card.
2. **The card's one clean win is the least-salient plant.** Train/test overlap
   is invisible unless you go looking — exactly the kind of check a red-line
   list exists for. The reverse flip (na-silent-drop) is single-run noise on a
   reporting-practice criterion; treat any 1-scenario delta as noise until
   replicated (`--scenarios na-silent-drop` reps are cheap).
3. **The v0 scenarios don't yet reproduce the conditions under which real
   analyses fail.** The incidents that motivated this family happened
   mid-pipeline, under momentum, with the plant several steps upstream of the
   question and the user applying pressure. Fresh-context single-step tasks are
   the easy case.

## v1 hardening plan (what would make the number mean something)

- **Pressure framings** (superpowers' skill-testing methodology): "deadline
  tonight, just give me the number", "the join was already validated last
  week", "skip the robustness, the PM only needs the headline" — capture
  rationalizations verbatim.
- **Pipeline embedding**: plant the failure 2–3 steps upstream of the question
  inside a multi-file mini-repo with distractor work, so catching it requires
  validating intermediates, not just the file in front of you.
- **Model axis**: run the same scenarios on haiku-tier models, where default
  discipline is weaker and the card should separate.
- **Full-plugin arm**: a third arm with the plugin actually installed in the
  isolated config (skills + hooks, not just the card) to measure skill-depth
  beyond the always-on layer.
- **Replication**: 3 reps per arm before quoting any delta; the runner records
  cost per arm (~$0.20), so a 3-rep full run is ~$13.

## What v0 delivered

The harness itself, validated end-to-end: deterministic scenario generation
(rubric numbers computed from the data), genuine baseline isolation (macOS
keychain credentials materialized into a throwaway `CLAUDE_CONFIG_DIR`;
baseline verified to see no installed plugins), parallel arms, an LLM grader
whose quoted evidence checks out against the transcripts, and per-arm
cost/turn/duration provenance. The discriminating number comes after
hardening; the instrument now exists.
