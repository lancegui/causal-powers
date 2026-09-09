# No-plugin and compact-prompt extension

## Answer

Yes, 24 generated files was too much for this toy DiD. The no-plugin control
also got every number and data update right, but sprawled to 30 files before
recovery. The compact prompt cut that to 14 and recovered the historical
numbers exactly, but it lost the actual Stage 1 code content by editing its only
script in place. I would not adopt that compact prompt unchanged.

The simplest sufficient next version is the compact prompt plus one explicit
code-version rule: keep the reusable script in Git with a recorded commit for
every run, or retain immutable source snapshots referenced by the history.
That should preserve its consolidation benefit without making a code hash point
to content that no longer exists.

## Direct results

All four gpt-5.6-sol low-effort arms produced the exact v1 primary estimate
(-4.3356939590696033; state-clustered SE 0.43794628155454418), correct pooled
regional estimates, and the correct 2,400-row v2 build after resolving 721
update rows to 720 unique keys. Every fresh recovery recomputed the original
v1 coefficient and SE exactly from panel_v1.csv.

The no-plugin control retained its Stage 1 source as analysis.R and recovered
it. The compact arm retained the Stage 1 formula, input hash, result, and old
code MD5 in its consolidated history, but analysis.R had been overwritten by
later-stage code. Its recovery therefore passed numerical/specification
recovery and failed historical-code-content recovery.

“No prompt” means no Causal Powers/plugin-specific prompt. It still received
the normal platform/system scaffolding, isolation rules, and identical staged
user requests.

## Artifact footprint

Counts exclude the two seeded raw inputs, supplied arm instructions, evaluator
snapshots, and .git. “Pre-recovery” counts subject work through Stage 3;
“audit” is the single file added by the fresh recovery agent.

| Arm | Pre-recovery | Audit | Total | Historical code recovered? |
|---|---:|---:|---:|---|
| Current selected package | 36 | 1 | 37 | yes |
| Original lean | 23 | 1 | 24 | yes |
| No plugin-specific prompt | 30 | 1 | 31 | yes |
| Compact v2 | 14 | 1 | 15 | no |

Breakdown before recovery:

| Arm | Scripts | Built data | Models | Result/check/state | Reports/roadmaps | Session/log | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| Current | 3 | 1 | 8 | 11 | 10 | 3 | 36 |
| Original lean | 3 | 1 | 3 | 9 | 7 | 0 | 23 |
| No prompt | 3 | 2 | 6 | 8 | 6 | 5 | 30 |
| Compact v2 | 1 | 1 | 0 | 5 | 7 | 0 | 14 |

The compact arm still exceeded its rough 5-8-file preference because it created
six report/pointer variants. Its useful consolidation was the single estimates
table, history, reconciliation table, and reusable script. The obvious next
cut is one human report/current pointer rather than per-spec report files.

For consolidated tables, preservation was judged by retained keyed historical
rows and reproducibility, not whole-container byte identity. Both extension
arms retained their historical numerical rows. Actual code content was assessed
separately, which is where compact v2 failed.

## What this changes

The toy task does not show a numerical advantage from Causal Powers prompting:
all packages and the no-plugin control were correct. Prompting mattered for how
the work was organized and recovered. The current package produced the most
state machinery; no prompt produced stage-by-stage duplication; original lean
preserved history clearly but still produced 24 files; compact v2 reduced
sprawl but over-consolidated mutable code.

The best observed package remains original lean because it combined full
recovery with fewer files than current/no-prompt. The best proposed next package
is compact v2 amended with real source-version retention and a single report.
That proposal is not a tested fifth arm.

The original day-versus-month trend ambiguity and saturated 35-lead diagnostic
caveat remain. No new specification or diagnostic was added in this extension,
and no pseudoprecise score was assigned.

