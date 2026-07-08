# docs/analysis template

Use this as the initial shape for the analysis-state folder. Agents should read
`docs/analysis/index.yaml` first and then only the YAML records it names.

## docs/analysis/index.yaml

```yaml
updated: 2026-07-08
active_phase: phase-0
current: current.yaml
decisions: decisions.yaml
artifact_registry: artifact_registry.yaml
read_for_current_task:
  - phases/2026-07-08_phase-0-framing.yaml
latest_handoffs: {}
do_not_read_by_default:
  - scratch/
  - archived logs
  - old markdown notes
```

## docs/analysis/current.yaml

```yaml
updated: 2026-07-08
goal:
phase: phase-0
status: not_started
next_action:
blockers: []
```

## docs/analysis/decisions.yaml

```yaml
decisions: []
```

## docs/analysis/artifact_registry.yaml

```yaml
artifacts: {}
```

## docs/analysis/phases/2026-07-08_phase-1-data-prep.yaml

```yaml
id: phase-1-data-prep
updated: 2026-07-08
status: not_started
owner: causal-powers:data-preparation
session_plan:
  goal: build validated cleaned panel
  scope:
    - inventory sources
    - validate per-source schemas and counts
    - assert joins and write cleaned output
  out_of_scope:
    - estimating treatment effects
  acceptance_checks:
    - source inventory with provenance exists
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
    - decisions.yaml
  verification_gate: oracle verifies data contracts before estimation
  state_updates:
    - current.yaml
    - artifact_registry.yaml
    - runs/
checklist:
  - item: source inventory with provenance
    status: pending
  - item: explicit schema and types loaded
    status: pending
  - item: per-source validation before joins
    status: pending
  - item: each join cardinality declared and asserted
    status: pending
  - item: row/key deltas logged after joins
    status: pending
  - item: dedup rule stated and count removed logged
    status: pending
  - item: missingness rule recorded
    status: pending
  - item: recodes and harmonizations recorded
    status: pending
  - item: totals reconciled to source
    status: pending
outputs: []
next_action:
```
