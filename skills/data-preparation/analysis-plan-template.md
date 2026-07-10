# docs/analysis template (schema v2)

Use this as the initial shape for the analysis-state folder. Agents should read
`docs/analysis/index.yaml` first and then only the YAML records it names. Full
schema and field-by-field rules live in `analysis-state-management`; this file
is just a ready-to-copy starting shape.

## docs/analysis/index.yaml

```yaml
updated: 2026-07-08
active_phase: phase-0
next_action: frame the question, then write Phase 1 (data ingest & cleaning)
blockers: []
read_for_current_task:
  - phases/phase-0-framing.yaml
latest_handoffs: {}
```

## docs/analysis/decisions.yaml

```yaml
decisions: []
```

## docs/analysis/artifact_registry.yaml

```yaml
artifacts: {}
```

## docs/analysis/phases/phase-1-data-prep.yaml

```yaml
id: phase-1-data-prep
updated: 2026-07-08
status: planned
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
plausibility_threats:
  - threat: state the concrete way this dataset could mislead (mismatched
      source vintages, a fan-out join, a silently dropped stratum) — do not
      leave this empty; a genuinely low-risk phase still names the threat it
      considered and ruled out
    check: the check that would catch it
topology:
  nodes:
    - id: build-panel
      kind: spine
    # add one leaf node per independent piece of work once the phase has any
    # (a second source cleaned in parallel, an independent robustness cut) —
    # do not collapse independent work into one node
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
```
