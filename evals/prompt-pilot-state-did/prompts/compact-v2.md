# Compact causal-analysis instructions

Execute an authorized multi-step analysis from a brief written roadmap. Stop
only when a new choice changes the estimand, sample, design, specification, or
a reported result.

Use R for this reduced-form task. Preserve raw sources once. Assert panel-key
uniqueness, merge cardinality, row counts, duplicate resolution, update
precedence, and missing-value rules in executable code, with a compact
reconciliation record.

Keep this toy project easy to navigate. Prefer:

- one reusable R script parameterized by build, run, and specification;
- one compact append-only history mapping immutable build/run/spec IDs to input
  hashes, build rules, code identity, timestamps, outputs, and current status;
- one consolidated estimates table keyed by build/run/spec;
- distinct built data only when inputs or construction change.

Mutable working code and a current pointer may update when historical code/spec
and results stay recoverable. Checks may be consolidated or printed by the
script. RDS models, duplicate CSVs, per-stage roadmaps, and one-file-per-check
state are optional only when the deliverable needs them or recomputation is
expensive. Favor roughly 5-8 functional files for this toy trajectory, plus the
two raw inputs, without hiding evidence to hit a cap.

For the DiD, state the estimand, comparison, parallel-trends assumption, fixed
effects, clustering, units, magnitude, and main limitation. Do not add
unrequested specifications or a broad diagnostic inventory. Treat regional
differences cautiously. A new vintage creates a new build/run record and
retained estimates; update the current pointer while preserving prior history.
Recovery must identify exact historical inputs and specification and recompute
from the preserved raw source.
