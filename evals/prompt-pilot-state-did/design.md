# Frozen state-DiD prompt pilot

Date: 2026-09-09. This is a prompt-only paired trajectory, not statistical
evidence or a causal estimate of prompt length. The lean arm changes content as
well as length, especially iteration provenance.

## Fixed task

- 40 states, monthly 2018-01 to 2022-12; 20 adopt together in 2021-01.
- Outcome: monthly opioid-prescribing rate per 100,000.
- Primary: treated x post, state and month FE, state-clustered SE; estimand is
  the average post-adoption ATT for treated states.
- Prespecified extension: four policy-by-region coefficients in one pooled
  model with state FE and common month FE (North/South/East/West).
- Sole alternative: add state-specific linear trends, retaining state/month FE
  and state clustering. No discretionary specifications.
- Stage 3 adds an overlapping 2021-07 to 2022-12 revised vintage. Unique key is
  state_id x month. Keep the newest revision_ts within update, update wins on
  overlap, retain v1-only rows, and never drop a panel row. Missing treated and
  adoption_date in update document never-treated states: recode treated to zero
  and leave adoption absent.
- Preserve raw sources and old results. Every build/run records input hashes,
  code/specification, outputs, timestamp, and canonical status.
- This update tests overlapping-vintage replacement, not expanded time coverage.
- Subjects use R fixest and its default finite-sample correction; grading reads
  full-precision artifacts rather than rounded prose.

## Roadmap (authorized by the user's go-ahead)

1. Freeze prompts, seed, inputs, oracle, and rubric before subject execution.
2. Run current and lean arms concurrently through identical Stages 1-3,
   exposing data only when its stage begins and saving each response/artifact.
3. After those subjects finish, use fresh Sol-low contexts for Stage 4 recovery
   from each saved runtime.
4. Score mechanical evidence first and qualitative friction second; report
   failures, elapsed timing/word/artifact counts when measurable, and limits.

Each subject is confined to its own /private/tmp runtime and forbidden from
reading the repo, sibling, or oracle. Model is gpt-5.6-sol, effort low,
fork_turns none. Repository hooks do not run in subject workspaces.
