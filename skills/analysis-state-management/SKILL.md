---
name: analysis-state-management
description: Use whenever an analysis plan, phase state, decision log, artifact registry, run record, or subagent handoff needs to be created, updated, resumed, or compacted. Replaces the old habit of growing and rereading one root analysis-plan.md with a small docs/analysis/ YAML index and task-specific records. Use at phase boundaries, before/after compaction, when recording approved deviations, when registering outputs, and when briefing fresh subagents from durable state.
---

# Analysis State Management

## Principle

A long analysis should resume from durable state, not from a bloated chat or a
single growing markdown file. The default memory surface is a small YAML index
that points to the few records needed for the current task.

**Core rule:** read `docs/analysis/index.yaml` first, then only the records it
names. Do not read a whole `analysis-plan.md` by default.

## Folder Layout

Use this layout unless the repo already has an equivalent convention:

```text
docs/analysis/
  index.yaml
  current.yaml
  decisions.yaml
  artifact_registry.yaml
  phases/
  evidence/
  runs/
  handoffs/
  scratch/
```

YAML is the agent-facing memory because it is compact, diffable, and easy to
address by field. Markdown is still allowed for human narrative and detailed
evidence, but it should be referenced from YAML rather than read by default.
JSON is acceptable for generated records; YAML is preferred for hand-edited
plans. Do not put full logs, full diffs, or long prose in YAML.

## Required Records

`index.yaml` is the only default read:

```yaml
updated: 2026-07-08
active_phase: phase-1b
current: current.yaml
decisions: decisions.yaml
artifact_registry: artifact_registry.yaml
read_for_current_task:
  - phases/2026-07-08_phase-1b.yaml
  - evidence/label-rule-choice.yaml
latest_handoffs:
  fixer: handoffs/fixer_phase-1b_2026-07-08.yaml
  oracle: handoffs/oracle_phase-1b_2026-07-08.yaml
do_not_read_by_default:
  - scratch/
  - old phase markdown
  - archived logs
```

`current.yaml` names the live state:

```yaml
updated: 2026-07-08
goal: apply chosen label rule to production pipeline
phase: phase-1b
status: in_progress
next_action: run production pipeline after label assertions pass
blockers: []
```

`decisions.yaml` is a compact ledger:

```yaml
decisions:
  - id: label-rule-choice
    date: 2026-07-08
    decision: use mme_q, WINDOWN_Q=2, SCALE_FRAC=0.20
    basis:
      - evidence/phase-1a-sensitivity.yaml
    supersedes: []
```

`artifact_registry.yaml` maps truth to files:

```yaml
artifacts:
  production_score:
    path: Detection/results/score_2007_2010.parquet
    produced_by: Detection/scripts/18d_deploy_production_score.R
    last_verified: 2026-07-08
    checks:
      - runs/2026-07-08_smoke.yaml
```

Phase records carry the plan. Each non-trivial phase should cover two horizons:
what this session will do, and where the work sits in the full lifecycle.

```yaml
id: phase-1-data-prep
updated: 2026-07-08
status: planned
owner: causal-powers:data-preparation
session_plan:
  goal: build validated cleaned panel
  scope:
    - inventory sources
    - assert join cardinality
    - write cleaned output
  out_of_scope:
    - estimating treatment effects
  acceptance_checks:
    - row/key deltas logged after each join
    - totals reconciled to source
  delegated_agents:
    preflight:
      - git-specialist
      - cleanliness-specialist
    execution:
      - fixer
    verification:
      - oracle
  budget:
    context_pressure_red_at: "50%"
    fresh_subagent_each_phase: true
lifecycle:
  previous_phase: phase-0-framing
  next_phase: phase-2-primary-spec
  dependencies:
    - decisions.yaml#source-selection
  verification_gate: oracle verifies data contracts before estimation
  state_updates:
    - current.yaml
    - artifact_registry.yaml
    - runs/
checklist:
  - item: source inventory with provenance
    status: pending
  - item: each join cardinality declared and asserted
    status: pending
outputs: []
next_action: inventory source files
```

## How To Update State

Update the smallest record that changed:

- phase status or next step -> `current.yaml` and the active phase YAML;
- consequential decision or approved deviation -> `decisions.yaml`;
- new or changed output -> `artifact_registry.yaml`;
- command/result reproducibility -> `runs/*.yaml`;
- subagent continuation -> `handoffs/*.yaml`;
- routing changes -> `index.yaml`.

Each record should carry `updated` or `date`, a short summary, paths, and the
minimum evidence needed to find the truth. Do not paste full logs, full diffs, or
full data samples into YAML. Store large detail in files and reference paths.

## Draft, Review, Approve

For non-trivial work, create or update draft planning YAML before execution:

1. Write the active phase `session_plan` and `lifecycle` fields.
2. Keep `current.yaml` pointed at the next planning/action step.
3. Route the YAML plan plus the user-facing contract to oracle when plan review
   is needed.
4. After user approval, execution agents work inside the approved scope and
   update runs, artifacts, decisions, and handoffs as they complete.

The draft YAML is allowed to exist before implementation approval because it is
planning state, not implementation. Keep it compact and reviewable.

## Migrating Old Plans

If a root `analysis-plan.md` or old monolithic plan exists, convert it by
extraction, not transcription:

1. Read only enough of the old plan to recover current goal, active phase,
   next action, decisions, artifacts, and blockers.
2. Create `docs/analysis/index.yaml`, `current.yaml`, `decisions.yaml`, and
   `artifact_registry.yaml`.
3. Create one active phase YAML with `session_plan` and `lifecycle` fields.
4. Add only task-relevant old notes to `read_for_current_task`.
5. Put the old markdown path under `do_not_read_by_default` or archive/scratch.

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
  Fresh fixer should continue from current.yaml and verify the production run.
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
2. Read only `current.yaml` and the records named in `read_for_current_task`.
3. Continue from `current.next_action`.
4. If state is missing or stale, repair the state before doing more analysis.

## Red Flags

- A root `analysis-plan.md` is growing and being reread in full.
- Phase history is mixed with current next steps.
- Decisions are buried in narrative instead of a compact ledger.
- Artifacts exist but no record says which script produced or verified them.
- A fresh subagent needs chat history to continue.

## Bottom Line

```
Good state  -> docs/analysis/index.yaml routes to tiny YAML records
Bad state   -> one long markdown plan every agent rereads from the top
```
