# Compact and no-plugin-control extension

Date: 2026-09-09. Authorized continuation of the frozen pilot.

Two new gpt-5.6-sol low-effort arms receive the identical staged task and data:

1. No plugin-specific prompt: platform/system scaffolding plus runtime isolation
   and the staged user requests only.
2. Compact candidate: the same task plus prompts/compact-v2.md.

Each uses an isolated /private/tmp runtime and cannot read another arm, the
repository, or oracle. Inputs appear only at their original stage. Fresh
contexts perform Stage 4 recovery. Prior arms, rubric, data, and results are
unchanged. Correctness, raw preservation, and recovery remain primary; file
count and navigability are secondary. File accounting separates subject-created
pre-recovery files from recovery-audit files and excludes evaluator snapshots
and seeded prompts/raw inputs.

For consolidated append-only tables, preservation means historical keyed
records and values remain present and exactly reproducible; the growing
container file need not remain byte-identical. Whole-file byte preservation is
reported separately as a format choice. Historical code/specification
recoverability is checked alongside numerical rows. This applies equally to
both extension arms and does not alter the original rubric or results.

This extension retains the original ambiguities: a consistent documented
day- or month-scale state trend is accepted, and the prior 35-lead diagnostic
caveat remains. No new diagnostic or specification is introduced.
