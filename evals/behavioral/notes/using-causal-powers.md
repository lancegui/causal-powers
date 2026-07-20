# using-causal-powers thinning notes (P3, thin-2026-07)

Branch: `thin-2026-07`. Scope: `skills/using-causal-powers/` (SKILL.md only —
`references/` left untouched, out of scope per the per-plan carve-out) + this
notes file. No other shared files touched (`generate_all.py`, the behavioral
README, other skills, `hooks/`, `AGENTS.md` all left alone).

## Why this skill skipped the DeepSeek loop

Per the per-plan rule (P3, batch 3 note in
`docs/plans/2026-07-19-skill-thinning-behavioral-loop.md`): this is the
routing/creed gateway, judged by trigger-eval fidelity + word count, not
in-context behavior induction on a subject model. No `run-skill-eval.py`
arms were run. Verification substitute: full routing-row re-check against
each named skill's current working-tree content (below), before/after word
count, and an inbound-reference grep across the family.

## Word count

| | Words |
|---|--:|
| `main` baseline | 2804 |
| Working tree before this pass (post-P1, "barely touched") | 2799 |
| After this pass | 2391 |

-413 words vs. `main` (-14.7%), -408 vs. the pre-pass working tree (-14.6%).
Comfortably inside the ~2200–2400 target band.

## What was cut

Nothing load-bearing was removed — every skill pointer, every named trigger
phrase in quotes, and every routing decision node survives. Cuts were entirely
connective-tissue compression: filler words, restated clauses, and one
paragraph that had become a near-duplicate of a dedicated skill's own content
now that skill exists on the working tree.

1. **"The rule" section (~682 → ~500 words).** The re-trigger/re-apply-don't-
   reload paragraph (the doctrine explicitly flagged untouchable) was left
   verbatim, word for word. The two-altitudes paragraph and the
   "wherever you're dropped in" / `docs/analysis/` state-folder paragraph
   were tightened: removed a duplicated concrete example ("that join fans
   out" — kept "check Milwaukee first"), shortened parenthetical skill-owner
   tags (`(bisection roadmap)` → `(bisection)`, etc.), and — the one
   substantive delta — compressed the `docs/analysis/` mechanics explanation
   down to a pointer at `analysis-state-management` (added since this
   section was last substantially written; that skill is now the actual
   owner of index.yaml/resume mechanics, so re-deriving them here was
   redundant with a whole dedicated file).
2. **"The fork" closing paragraph.** Cut a recap sentence that restated the
   three bullets immediately above it ("the three arms are partners with
   genuinely different pipelines...") down to the one non-redundant closing
   line. The three routing bullets themselves (with every quoted trigger
   phrase) are untouched in content, only tightened in connective wording
   (`→ the **structural** workflow. The reduced-form relationship...` →
   `→ **structural**: the reduced-form relationship...`).
3. **"The typical flow."** The ASCII diagram (the one piece of real
   sequencing information not in the table) is untouched. The prose below it
   restated `executing-analysis-plans`' own fan-out description (already in
   the family table's row for that skill) — compressed to keep only the
   non-redundant delta: the "just run the regression" trigger-phrase routing
   point, and the structural/prediction-specific fan-out examples not in the
   table row. A closing paragraph on the exploration→locked-rule regime
   split was a near-verbatim duplicate of `data-contracts`' own "Two
   regimes" section (word-for-word overlap: "the mistake is staying in
   regime 1 forever and shipping exploratory code as production" vs. this
   file's "the mistake is staying in exploration forever and shipping it as
   if it were production") — compressed to a one-line pointer.
4. **"The craft principles."** Merged two short paragraphs into one, cut
   the `CONTRACT → … → FREEZE` loop callout (already stated in the family
   table's `data-contracts` row).
5. **Language profile.** Tightened the "Overriding the default" two-tier
   explanation (cut "same pattern as the rest of the project's scar tissue"
   flourish) and the mid-task-switch sentence (now points at the
   `## Instruction priority` section below instead of restating its claim
   inline).
6. **Running on Codex / other agents — corrected, not just cut** (see stale
   reference below). Net length is close to the original after the fix; the
   savings came from folding the "Always-on discipline" bullet into the
   intro paragraph and trimming the Triggering/Tool-names/Resumability
   bullets.
7. **Instruction priority.** Light wording tightening only, no content cut —
   the waive-vs-silently-skip distinction is unchanged.
8. **Family table (routing table).** Left untouched in substance, per the
   task's constraint. Applied only wording-level tightening within four
   rows that were disproportionately long relative to their siblings:
   `question-framing` (cut a redundant restated tag, "The 'what are we
   actually measuring / building' skill", since "brainstorm-before-you-build
   gate" already carries that meaning; adopted the `PAP` abbreviation
   already used elsewhere in the file), `descriptive-evidence` (cut "the
   signature artifact is" filler), `predictive-modeling` (cut the six-field
   parenthetical enumeration of the Prediction Spec's rows — no other
   row in the table enumerates its locked-document's fields at that level of
   detail, so this brought it in line with the `causal-identification` /
   `structural-estimation` rows, which name the gate but not its field
   list). Every skill name, every distinguishing trigger condition, and
   every "this is the X workflow" tag survives unchanged.

## Stale reference found and fixed

`## Running on Codex / other agents` only named Codex and pointed at a single
file, `references/codex-tools.md`. But `skills/using-causal-powers/references/`
has held three platform files since commits `d312bc3` (OpenCode) and
`c9ba9e0`/`e65487f` (the same era as the docs-analysis-state work) —
`codex-tools.md`, `opencode-tools.md`, and `copilot-tools.md` — and the
always-on card (`hooks/session-context.md` / `AGENTS.md`, byte-identical,
not edited here) already names all three platforms and links all three
files. This section had drifted stale relative to both the reference
directory it's supposed to summarize and its own always-on-card counterpart.
Fixed: retitled to `## Running on Codex, OpenCode, Copilot, and other
AGENTS.md agents`, and the "Tool names" bullet now links all three reference
files instead of only `codex-tools.md`. This is a correction, not a
substance change to routing (it doesn't touch which discipline skill fires
when) — flagging it here because it's exactly the class of drift the task
asked me to hunt for, just found in the platform-compat section rather than
the routing table.

## Routing-row confirmation table

Every row of "The family — and when each fires" re-checked against the named
skill's current working-tree `SKILL.md` (all read in full this session).
"Match" = the row's stated firing condition and the skill's own scope/gate
language agree; no row required a content change (see the one wording-only
trim per row noted above where applicable).

| Skill | Row's firing condition | Confirmed against working tree | Status |
|---|---|---|---|
| `question-framing` | Before any analysis or data-built deliverable (incl. viz); pins estimand/metric/population/unit/sources+joins/decision; owns the everyday plan for general work | Matches `## The framing brief` + `## The plan: data, approach, deliverable` sections verbatim in substance | Match |
| `descriptive-evidence` | Deliverable is a description (trend/distribution/Table 1/stylized fact/map); comparability, composition check, distribution, descriptive verbs | Matches `## Fix the comparability choices`, `## The composition check`, `## Show the distribution`, `## Describe, don't infer` sections | Match |
| `pre-analysis-plan` | Confirmatory study; lock hypotheses/spec/robustness before outcomes | Matches `## What the plan locks (before seeing outcomes)` | Match |
| `analysis-state-management` | Create/update/resume/compact durable state; index.yaml + phase/decision/artifact/handoff records | Matches current schema v2 (`index.yaml`, `decisions.yaml`, `artifact_registry.yaml`, `phases/<id>.yaml`) exactly | Match |
| `data-contracts` | Load/transform/join/aggregate/model → assert invariants, join cardinality, reconcile, freeze; "the checker" | Matches `## Overview` ("This is the **checker**") and the `CONTRACT → CHECK IT BITES → COMPUTE → RECONCILE → FREEZE` loop | Match |
| `data-preparation` | Ingest & cleaning PHASE; checkboxed plan + decisions ledger; doer/planner calling `data-contracts`; routes to `analysis-checkpoints`; delegated from `executing-analysis-plans` | Matches `## Doer/planner, not checker` and `## Phase 1 of durable analysis state` sections, and executing-analysis-plans' spine step 1 delegation | Match |
| `wrong-number-debugging` | Number looks wrong/won't reconcile; bisect, don't patch | Matches `## The loop` (`REPRODUCE → LOCATE (bisect) → EXPLAIN → FIX AT THE SOURCE → RE-CONTRACT`) | Match |
| `result-verification` | Before reporting/presenting/done; reconcile, reproduce clean, robustness, tie to prose | Matches `## The verification checklist` (9-item list) | Match |
| `causal-identification` | Causal claim/design; state+test assumptions; mandatory robustness battery; reduced-form workflow | Matches `## The Design Card`, `## The discipline`, `## Robustness, placebo, sensitivity` | Match |
| `structural-estimation` | Estimating primitives or needing a counterfactual; named model classes; structural workflow | Matches `## Primitives`, `## Reduced form or structural?` fork section, and the model-class list in the row aligns with the skill's own description frontmatter | Match |
| `predictive-modeling` | Goal is a prediction; write+sign-off Prediction Spec before fitting; prove eval honest before trusting metric; never read importance as causal; prediction workflow | Matches `## Write the Prediction Spec`, `## Prove the evaluation is honest`, `## Prediction is not causation` | Match |
| `analysis-review` | Review own/others' analysis; silent-failure classes; verify feedback | Matches `## Overview` and `## Receiving review feedback — verify, don't perform` | Match |
| `analysis-craft` | Write/edit analysis code; minimum code, surgical edits, surface tradeoffs | Matches `## Simplicity First`, `## Surgical Changes`, `## Think Before Coding` | Match |
| `analysis-checkpoints` | Throughout execution; your call vs. user's call; design/sample/spec/estimand/PAP-deviation/data-drop | Matches `## The line: your call vs. the user's call` | Match |
| `executing-analysis-plans` | Once plan approved; step-by-step execution; fan independent pieces to subagents | Matches `## The sequential spine vs. the parallel fan-out` | Match |
| `project-organization` | Setup/tidy a research repo; end-of-workflow before commit; paper-centric structure; place-then-tidy | Matches `## The structure` and `## Enforce throughout, tidy before git` | Match |

No row named a section, vocabulary term, or mechanic that has been renamed
or relocated by P1 or a per-skill loop. In particular, checked the three
mechanics explicitly flagged as candidates for staleness in the task
background:
- **Verification checklist** — the gateway does not name a specific section
  of `result-verification`, just points at the skill generically ("reconcile,
  reproduce from a clean state, attack with robustness, tie figures to
  prose"), which matches `result-verification`'s own `## The verification
  checklist` items 1/2/4/6 in substance without depending on the section's
  exact title. No stale pointer.
- **Locked-doc gate mechanics** — the gateway's "rule" section already
  points at `analysis-checkpoints` by name ("owns... the
  write→sign-off→reconstruct mechanics behind every locked plan"), which
  matches `analysis-checkpoints`' own `## The locked-document gate — shared
  mechanics` section (added by P1) exactly, including the same three-step
  naming (write to file / sign-off before the load-bearing step /
  mid-pipeline reconstruct-and-confirm). No stale pointer.
- **State mechanics** — the gateway's `docs/analysis/` paragraph already said
  "schema owned by `analysis-state-management`" before this pass; this pass
  extended that pointer to also cover the resume mechanics (previously
  re-explained inline), matching `analysis-state-management`'s own `##
  Resume Rule` and `## Required Records` sections. Strengthened, not stale.

## Inbound-reference grep

`grep -rln "using-causal-powers" .` (excluding the skill's own directory)
across the whole repo returns: `AGENTS.md`, `README.md`, `CHANGELOG.md`,
`evals/behavioral/notes/analysis-state-management.md`,
`docs/plans/2026-07-19-skill-thinning-behavioral-loop.md`,
`docs/family-audit-and-map.md`, `hooks/session-context.md`,
`skills/analysis-state-management/references/conductor-integration.md`,
`skills/using-causal-powers/references/opencode-tools.md`.

Checked every hit:
- All reference the skill **by name only** (`using-causal-powers`), or by a
  path into `references/{codex,opencode,copilot}-tools.md` (untouched this
  pass) — none reference a specific `SKILL.md` section header or anchor.
- Specifically checked for anchor links to the renamed section
  (`#running-on-codex...`): zero hits anywhere in the repo, so the header
  rename (`## Running on Codex / other agents` →
  `## Running on Codex, OpenCode, Copilot, and other AGENTS.md agents`)
  breaks nothing.
- `README.md:51` describes the skill's role in one line ("Gateway: the
  creed, the map, and routing to the right skill") — generic, unaffected.
- `CHANGELOG.md` hits are historical entries (feature-added log), not live
  cross-references — nothing to reconcile.
- `docs/family-audit-and-map.md:228` records the pre-pass word count
  (2799) in the audit table; that table is explicitly the audit's own
  historical record (out of scope to edit per the shared-file rule — it
  isn't `skills/using-causal-powers/` or the notes file) and will need a
  follow-up row once the orchestrator's integration pass re-derives Map 4‴
  across all thinned skills. Flagging, not fixing (out of scope for this
  agent).

No inbound reference was broken by this pass.

## Kept-and-flagged

1. **Family-table model-class keyword lists** (`structural-estimation` row's
   "BLP/demand, dynamic discrete choice, entry/games, auctions,
   consideration, search") were considered for a cut as partially redundant
   with the row's own primitives parenthetical, but kept — they double as
   keyword-matching surface for a reader/grader scanning the table for a
   specific named method, and cutting them would be a real (if small) loss
   of trigger-phrase coverage, which the task explicitly protects.
2. **The three concrete trigger-phrase examples in "The fork" section's
   structural bullet** (merged-firm pricing / consideration-vs-search /
   entrant surplus) were kept in full rather than trimmed to one or two —
   each covers a materially different sub-case of "why go structural," and
   dropping any one narrows the phrase-matching surface for that specific
   routing decision.
3. **`docs/family-audit-and-map.md`'s stale word-count row** (2799, pre-pass)
   — noted above under inbound-reference grep; not fixed, out of scope.

## Files touched

- `skills/using-causal-powers/SKILL.md` (edited, 2799 → 2391 words this
  pass; 2804 → 2391 vs. `main`)
- `evals/behavioral/notes/using-causal-powers.md` (this file, new)

No other file was written, edited, or staged. No git write commands were
run.
