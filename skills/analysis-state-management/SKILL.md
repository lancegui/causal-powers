---
name: analysis-state-management
description: Use whenever an analysis phase, decision log, artifact registry, run record, or subagent handoff needs to be created, updated, resumed, or compacted. Replaces the old habit of growing and rereading one long plan file with a small docs/analysis/ YAML index and task-specific records. Use at phase boundaries, before/after compaction, when recording approved deviations, when registering outputs, and when briefing fresh subagents from durable state.
---

# Analysis State Management

## Principle

A long analysis should resume from durable state, not from a bloated chat or a
single growing markdown file. The default memory surface is a small YAML index
that points to the few records needed for the current task.

**Core rule:** read `docs/analysis/index.yaml` first, then only the records it
names. Do not read a whole legacy plan file by default.

## Folder Layout (schema v2)

Use this layout unless the repo already has an equivalent convention:

```text
docs/analysis/
  index.yaml               # the ONLY default read
  decisions.yaml           # decision ledger
  artifact_registry.yaml   # truth-to-file map
  phases/<id>.yaml         # one file per phase; carries the plan AND the topology
  evidence/ runs/ handoffs/ scratch/   # optional; referenced when used
```

YAML is the agent-facing memory because it is compact, diffable, and easy to
address by field. Markdown is still allowed for human narrative and detailed
evidence, but it should be referenced from YAML rather than read by default.
JSON is acceptable for generated records; YAML is preferred for hand-edited
plans. Do not put full logs, full diffs, or long prose in YAML.

There is no separate `current.yaml` — the live-state fields it used to carry
(`updated`, `active_phase`, `next_action`, `blockers`) are merged into
`index.yaml`. One default read, not two.

## Required Records

`index.yaml` is the only default read:

```yaml
updated: 2026-07-10
active_phase: phase-2-primary-spec
next_action: draft phase-2 topology, request oracle review
blockers: []
read_for_current_task:
  - phases/phase-2-primary-spec.yaml
  - evidence/label-rule-choice.yaml
latest_handoffs:            # optional
  fixer: handoffs/fixer_phase-1b_2026-07-08.yaml
```

There are no constant pointer keys (`current:`, `decisions:`,
`artifact_registry:`) — `decisions.yaml` and `artifact_registry.yaml` are
fixed conventional filenames, not something the index needs to point at.
There is no `do_not_read_by_default` key — the rule "read only what the index
names" already covers it. There is no `phases:` list and no phase status in
the index — **phase status lives in the phase record only** (one source of
truth; `ls docs/analysis/phases/` enumerates what exists).

`decisions.yaml` is a compact ledger, unchanged from v1:

```yaml
decisions:
  - id: label-rule-choice
    date: 2026-07-08
    decision: use mme_q, WINDOWN_Q=2, SCALE_FRAC=0.20
    basis:
      - evidence/phase-1a-sensitivity.yaml
    supersedes: []
```

`artifact_registry.yaml` maps truth to files, unchanged from v1:

```yaml
artifacts:
  production_score:
    path: Detection/results/score_2007_2010.parquet
    produced_by: Detection/scripts/18d_deploy_production_score.R
    last_verified: 2026-07-08
    checks:
      - runs/2026-07-08_smoke.yaml
```

## phases/&lt;id&gt;.yaml — carries the plan AND the topology

Each phase record is flat (no `session_plan`/`lifecycle` nesting) and is both
the plan and the execution topology for that phase:

```yaml
id: phase-2-primary-spec          # MUST match filename
updated: 2026-07-10
status: planned                   # planned | in_progress | done | superseded
goal: estimate primary SDID specification
scope:
  - construct treatment/outcome panel
  - estimate primary spec
out_of_scope:
  - discretionary robustness beyond the approved list
acceptance_checks:
  - join cardinality asserted, totals reconciled
  - primary estimate reproduced from clean session
plausibility_threats:             # REQUIRED, non-empty (a waiver is still an entry)
  - threat: mortality denominator mixes county populations across vintages
    check: recompute rates with fixed-vintage denominators, compare
topology:                         # REQUIRED, non-empty — the enforcement surface
  nodes:
    - id: build-panel
      kind: spine                 # spine | leaf
      writes: [Detection/intermediate/]   # optional
    - id: sdid-main
      kind: leaf
      depends_on: [build-panel]
    - id: sdid-placebo
      kind: leaf
      depends_on: [build-panel]
checklist:                        # optional
  - item: panel built and contract-asserted
    status: pending
outputs: []
```

`plausibility_threats` and `topology.nodes` are both required and non-empty —
a phase record without them is incomplete, not minimal. `topology.nodes` is
what makes independent work visible as independent: **one leaf node per
genuinely independent piece of work** (a robustness spec, a subsample cut, a
placebo test); collapsing several independent leaves into one node is the
mistake that turns a fan-out into a serial bottleneck (see
`executing-analysis-plans`).

Deleted from v1 phase records: `delegated_agents` (role theater — the lane
architecture is standing config, not per-phase state), `budget:` (constants;
they live in the standing prompt/discipline, not per phase), `lifecycle:`
(duplicated the index / standing rules; keep a plain `depends_on:` reference
into `decisions.yaml` at top level if a phase genuinely needs one).

**Approval is never stored in the phase file.** The model writes the file, so
it could stamp its own approval — `status:` values are only
`planned | in_progress | done | superseded`, never `approved`, and there is
no `approved:` key. Approval truth lives outside the file: in the user's
explicit sign-off in chat, and — when the causal-conductor spine plugin is
installed (OpenCode) — additionally in the plugin's own state
(`{ phaseId, sha256(fileBytes), approvedAt }`), never in anything the model
can edit. If you ever see a phase record with `status: approved` or an
`approved:` key, that is a red flag, not a shortcut: fix it, don't rely on it.

## How To Update State

Update the smallest record that changed:

- phase status or next step -> the active phase YAML, then `index.yaml`'s
  `active_phase`/`next_action`/`blockers`;
- consequential decision or approved deviation -> `decisions.yaml`;
- new or changed output -> `artifact_registry.yaml`;
- command/result reproducibility -> `runs/*.yaml`;
- subagent continuation -> `handoffs/*.yaml`;
- routing changes -> `index.yaml`.

Each record should carry `updated` or `date`, a short summary, paths, and the
minimum evidence needed to find the truth. Do not paste full logs, full diffs, or
full data samples into YAML. Store large detail in files and reference paths.

## Draft, Review, Approve

Pre-approval writing is the normal path, not an exception:

1. Draft or refine the active phase YAML directly under
   `docs/analysis/phases/<id>.yaml` — `goal`, `scope`, `out_of_scope`,
   `acceptance_checks`, `plausibility_threats`, `topology.nodes`. Independent
   pieces of work are separate nodes from the start.
2. Route the phase YAML to oracle review when the design is high-risk, render
   a short human-readable summary in chat (the summary is *rendered from* the
   file for the user to read — it is never itself the source of truth), and
   ask the user to approve.
3. On approval, do not write anything into the phase file to record that fact
   — approval lives in the user's words and, if present, the conductor
   plugin's bound record. Implementation work may now proceed inside
   `topology.nodes`.
4. **Drift = the approved phase file's bytes changing.** If you need to
   change scope, topology, or acceptance checks after approval, that is a new
   draft needing re-approval, not a quiet edit. Edits to `index.yaml`,
   `decisions.yaml`, other phase files, or run/handoff records are not drift
   and do not require re-approval.
5. After approval, execution agents work inside the approved `topology.nodes`
   and update runs, artifacts, decisions, and handoffs as they complete.

## Migrating Old Plans

If a root `analysis-plan.md`, another old monolithic plan file, or a v1
`docs/analysis/current.yaml` exists, convert it by extraction, not
transcription. **This is the only section in this skill that legacy
`analysis-plan.md` or `current.yaml` are mentioned — outside a migration,
schema v2 is the only convention.**

1. Read only enough of the old file(s) to recover the current goal, active
   phase, next action, decisions, artifacts, and blockers. If a v1
   `current.yaml` exists, its fields (`updated`, `goal`, `phase`, `status`,
   `next_action`, `blockers`) map directly onto v2 `index.yaml`'s
   `updated`/`active_phase`/`next_action`/`blockers`.
2. Create `docs/analysis/index.yaml` with those fields, plus
   `decisions.yaml` and `artifact_registry.yaml` if they don't already exist.
3. Create one active phase record `docs/analysis/phases/<id>.yaml` with
   `goal`, `scope`, `out_of_scope`, `acceptance_checks`, and — even if the old
   plan never stated them — a non-empty `plausibility_threats` and a
   non-empty `topology.nodes` (a single spine node is a valid minimal
   topology if the work genuinely has no independent pieces yet).
4. Add only task-relevant old notes to `index.yaml`'s `read_for_current_task`.
5. **Move the old file (`analysis-plan.md`, `current.yaml`, or both) to
   `docs/analysis/scratch/` or delete it. Never leave it at the project root
   or as a live `docs/analysis/current.yaml` — the migration is not done
   while a v1 file is still readable as if it were current.**

Do not preserve every paragraph. The migration succeeds when a fresh agent can
resume from `index.yaml` plus the named records without reading the old plan.

## Handoffs

A subagent handoff should be compact:

```yaml
date: 2026-07-08
agent: fixer
phase: phase-1b
status: complete
files_touched:
  - Detection/scripts/02_build_panel.R
commands_run:
  - Rscript Detection/scripts/00_smoke_verify_pipeline.R
large_outputs:
  - logs/phase-1b-smoke.log
next_prompt: >
  Fresh fixer should continue from docs/analysis/index.yaml and verify the
  production run.
budget_status:
  context_pressure: red
  continue_same_thread: false
```

If context pressure is above 50 percent, handoff and stop. Do not continue the
same subagent into a new phase.

## Oracle Isolation

Oracle may read `index.yaml` for navigation and the verification packet for
paths, commands, claims, and expected invariants. Oracle must verify claims from
source files, outputs, and commands, not from fixer/explorer prose.

## Resume Rule

On resume or after compaction:

1. Read `docs/analysis/index.yaml`.
2. Read only the records named in `read_for_current_task`.
3. Continue from `index.yaml`'s `next_action`.
4. If state is missing or stale, repair the state before doing more analysis.

## Red Flags

- A root plan file or long markdown plan is growing and being reread in full.
- Phase history is mixed with current next steps.
- Decisions are buried in narrative instead of a compact ledger.
- Artifacts exist but no record says which script produced or verified them.
- A fresh subagent needs chat history to continue.
- A phase record with empty (or missing) `plausibility_threats` or
  `topology.nodes` — both are required, not optional, even for a
  single-node phase.
- A phase record with `status: approved` or an `approved:` key — the model
  wrote its own approval; approval lives outside the file.
- A live `docs/analysis/current.yaml` next to `index.yaml` — v1/v2 drift; the
  fields belong in `index.yaml` now.

## Bottom Line

```
Good state  -> docs/analysis/index.yaml routes to tiny YAML records
Bad state   -> one long file every agent rereads from the top, or a
               phase record with no topology and no plausibility threats
```
