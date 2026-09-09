# State-DiD prompt pilot report

## Decision

I prefer the lean candidate in this trajectory. Both arms were numerically
correct, preserved the raw inputs, built the revised vintage correctly, and
recovered the original baseline in a fresh context. The lean arm made run/build
identity easier to inspect with 24 subject-created files versus 37, and its
recovery did not touch the historical run. The current arm's recovery first
reran the Stage 1 script in place before doing an isolated recomputation, and
its Stage 1 run ledger used the false date 2026-10-20.

This is one paired prompt-only trajectory. It compares instruction packages,
not prompt length: the lean prompt adds stronger iteration rules while removing
other content, and repository hooks were absent.

## Direct evidence

| Check | Current | Lean |
|---|---:|---:|
| V1 primary b / clustered SE | -4.335693959069603 / 0.437946281554544 | same |
| V2 primary b / clustered SE | -4.334461669149849 / 0.441453651282829 | same |
| Four pooled region coefficients | all oracle-exact | all oracle-exact |
| Update rows: raw / dedup / final panel | 721 / 720 / 2,400 | 721 / 720 / 2,400 |
| V1 result bytes unchanged through Stage 3 | pass | pass |
| Fresh-context v1 recomputation | exact | exact |
| Historical result touched during recovery | yes; rewritten identically before isolated audit | no |
| Raw v1/update SHA-256 preserved | pass | pass |

Both recovery probes identified raw v1 hash
02233208ed1646c22685a408d91d4bdc7f5fe73bdffc58f3df0229362b30e6fe,
the state/month-FE specification and state clustering, and reproduced the
stored coefficient and SE. The update hash was
4535f64c92826efcd210a9f72c4abed3820aa5899ad30ccb532edfab6389521b.

The lean arm used elapsed calendar days for state-specific trends consistently
in Stages 2 and 3; the oracle/current arm used integer month index. The prompt
said only “linear trends,” so both are defensible but produce a small difference
(lean v2 -4.0120607; month-index oracle -4.0122678). Following the frozen
rubric's valid-convention rule, this was recomputed under the documented
convention and not scored as an error. This ambiguity should be removed in a
future pilot.

## Major failures and caveats

Both arms added a 35-lead joint pretrend test with only 40 state clusters and
reported a strong rejection. That nearly saturated diagnostic is unstable and
was not a sound basis for a definitive DGP failure claim. The lead profile and
small-cluster/high-dimensional joint inference needed more care. Because the
same problem occurred in both arms, it provides no comparative advantage; each
lost one friction point for the unnecessary broad diagnostic.

The current recovery's initial in-place rerun violated the preservation method
even though the regenerated CSV was byte-identical. The explicit disclosure was
good, but a recovery audit should always recompute to a temporary output first.
The current Stage 1 run record also had an incorrect future date, weakening its
claimed run-time provenance. No coefficients, raw inputs, or historical result
bytes were ultimately lost.

The revised file replaces an overlapping vintage and adds no new months, so
this tests update precedence and provenance rather than panel expansion.

## Frozen weighted score

| Category | Current | Lean |
|---|---:|---:|
| Numerical/statistical correctness (35) | 35 | 35 |
| Data integrity/build (25) | 25 | 25 |
| Iteration/recovery (25) | 22 | 25 |
| Interpretation/judgment (10) | 10 | 10 |
| Workflow friction (5) | 4 | 4 |
| **Total** | **96** | **99** |

Current lost one preservation point for the in-place recovery rerun and two
provenance points for the false Stage 1 date. Both lost one friction point for
the saturated unsolicited diagnostic. Neither asked for redundant approval.

## Measured footprint

The lean instruction file is 232 words. The current always-on card plus the
eight supplied SKILL.md files total 19,661 words. These counts exclude staged
user prompts. At the end of recovery, the current runtime contained 37
subject-created files after excluding 15 seeded instruction files and two raw
fixtures; lean contained 24 after excluding its prompt and two fixtures. These
are file counts, not token, cost, or total-tool-call measures. Subject timing
was only inferable from generated timestamps and is not reported as reliable
elapsed runtime.

## Artifacts

- Frozen design: design.md
- Frozen rubric: rubric.md
- Lean prompt: prompts/lean.md
- Current prompt package and hashes: prompts/current-package/
- Staged prompts: prompts/stages.md
- Generator and hidden evaluator oracle: fixtures/
- Per-stage runtime snapshots and recovery audits: transcripts/

