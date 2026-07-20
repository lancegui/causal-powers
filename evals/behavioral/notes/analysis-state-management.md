# analysis-state-management — SPLIT notes (thin-2026-07)

## What changed

`skills/analysis-state-management/SKILL.md` mixed two audiences: generic
docs/analysis/ state-management discipline every user needs, and
causal-conductor/OpenCode-specific orchestration schema presented as if
required even without the conductor installed. Split into:

- `skills/analysis-state-management/SKILL.md` — generic core, self-contained.
  The v2 schema (including `topology.nodes` and `plausibility_threats`) is
  kept in full; a single-node phase remains explicitly valid for users with
  no independent work to fan out. One short pointer paragraph, at the end of
  "Principle", sends conductor users to the reference:
  > On OpenCode with causal-conductor installed, the phase contract carries
  > additional required fields and binding semantics — see
  > `references/conductor-integration.md`.
- `skills/analysis-state-management/references/conductor-integration.md`
  (new) — every conductor-specific requirement, moved verbatim in substance,
  with a top-of-file statement that none of it is weakened or optional once
  the plugin is installed.

Word counts: SKILL.md 1800 words -> 1631 words. New reference file: 730 words.
Nothing was deleted; the difference is the added pointer paragraph plus
connective prose in the reference explaining why a rule differs between
plain and conductor use.

## Rule-by-rule accounting (source -> destination)

1. Resume from durable state, not chat/one long file -> SKILL.md, Principle.
2. Core rule: read `index.yaml` first, then only named records -> SKILL.md, Principle.
3. (new) Pointer to conductor-integration.md -> SKILL.md, Principle (addition).
4. `docs/analysis/` folder layout -> SKILL.md, Folder Layout.
5. YAML preferred for hand-edited records; no full logs/diffs in YAML -> SKILL.md, Folder Layout.
6. No separate `current.yaml`; live-state fields merged into `index.yaml` -> SKILL.md, Folder Layout.
7. `index.yaml` required fields -> SKILL.md, Required Records.
8. No constant pointer keys; no `do_not_read_by_default`; no `phases:` list/status in index -> SKILL.md, Required Records.
9. `decisions.yaml` schema -> SKILL.md, Required Records.
10. `artifact_registry.yaml` schema -> SKILL.md, Required Records.
11. Phase record is flat (no `session_plan`/`lifecycle` nesting) -> SKILL.md, phases/<id>.yaml.
12. Phase record required fields -> SKILL.md, phases/<id>.yaml.
13. `plausibility_threats` and `topology.nodes` required & non-empty; single-node phase valid -> SKILL.md, phases/<id>.yaml + Migrating Old Plans + Red Flags.
14. `topology.nodes`: one leaf node per independent piece of work; don't collapse leaves -> SKILL.md, phases/<id>.yaml.
15. `plausibility_threats[]` item must also carry `owner_node`; missing owner = incomplete contract -> conductor-integration.md, "Plausibility threats require owner_node".
16. Deleted-from-v1 fields (`delegated_agents`, `budget:`, `lifecycle:`), generic why -> SKILL.md, phases/<id>.yaml (delegated_agents justification reworded to drop "lane architecture" framing).
17. Fuller conductor reason for deleting `delegated_agents` ("role theater", lane architecture as standing config) -> conductor-integration.md, "Deleted-from-v1 field: delegated_agents".
18. Approval never stored in phase file; status enum restricted; no `approved:` key; approval lives in user's chat sign-off -> SKILL.md, phases/<id>.yaml.
19. Conductor's own bound approval record `{ phaseId, sha256(contract), approvedAt }` -> conductor-integration.md, "Approval binding".
20. How To Update State — smallest-record routing table -> SKILL.md, "How To Update State" (protected anchor, unchanged).
21. Each record carries updated/date + summary + paths + minimal evidence -> SKILL.md, How To Update State.
22. Draft/Review/Approve step 1: draft phase YAML fields, independent nodes from the start -> SKILL.md, Draft Review Approve.
23. Step 1 addendum: `owner_node` must be named before approval (oracle finding -> phase-draft fix, not reapproval) -> conductor-integration.md, "Plausibility threats require owner_node".
24. Step 2: route to review when high-risk, render human-readable summary, ask user to approve -> SKILL.md, Draft Review Approve (role generalized to "independent review / analysis-reviewer").
25. Step 2 conductor detail: review role named "oracle" -> conductor-integration.md, "Draft, Review, Approve — the conductor's review role".
26. Step 3: don't write approval into phase file; approval lives in user's words -> SKILL.md, Draft Review Approve.
27. Step 3 conductor detail: "...and, if present, the conductor plugin's bound record" -> conductor-integration.md, "Approval binding".
28. Step 4 (plain): drift = approved contract changing; scope/topology/acceptance-check changes need new draft + re-approval; index/decisions/other-phase/run/handoff edits are not drift -> SKILL.md, Draft Review Approve.
29. Step 4 conductor elaboration: conductor ignores pure bookkeeping but binds the semantic contract -> conductor-integration.md, "Drift = the approved phase contract changing (semantic, not byte-for-byte)".
30. Step 5: after approval, execution agents work inside approved `topology.nodes`, update index/runs/artifacts/decisions/handoffs -> SKILL.md, Draft Review Approve.
31. Migrating Old Plans (extraction not transcription; 5 steps incl. moving/deleting old file) -> SKILL.md, Migrating Old Plans (unchanged).
32. Handoff record compact schema -> SKILL.md, Handoffs.
33. Example `agent:`/`next_prompt` values used conductor lane name `fixer` -> SKILL.md generalized example to `robustness-runner`; conductor's actual lane naming (fixer/explorer/oracle) documented in conductor-integration.md, "Handoffs — lane naming", cross-referencing skills/using-causal-powers/references/opencode-tools.md.
34. If context pressure > 50%, handoff and stop; don't continue same subagent into new phase -> SKILL.md, Handoffs (kept generic — see Ambiguous section below).
35. Oracle Isolation: oracle reads index.yaml + verification packet; must verify from source, not fixer/explorer prose -> conductor-integration.md, "Oracle Isolation" (verbatim; heading removed from SKILL.md, no inbound reference by name existed).
36. Resume Rule (4 steps) -> SKILL.md, "Resume Rule" (protected anchor, unchanged).
37-41. Red Flags: long-plan reread; phase history mixed with next steps; decisions buried in narrative; artifacts w/o producing record; subagent needing chat history -> SKILL.md, Red Flags (unchanged).
42. Red Flags: empty/missing `plausibility_threats` or `topology.nodes` -> SKILL.md, Red Flags.
43. Red Flags: `plausibility_threats[]` item with no `owner_node` / owner not a declared node -> conductor-integration.md, folded into "Plausibility threats require owner_node".
44. Red Flags: `status: approved` / `approved:` key -> SKILL.md, Red Flags.
45. Red Flags: live `current.yaml` next to `index.yaml` -> SKILL.md, Red Flags.
46. Bottom Line diagram -> SKILL.md, Bottom Line (unchanged).

Every rule from the pre-split file exists afterward, verbatim in substance,
in exactly one of the two files. Nothing was deleted outright.

## Inbound-reference confirmation

Grepped the whole `skills/` tree (working-tree state, including other
agents' in-flight edits) for references to `analysis-state-management` and
its section names.

- `skills/executing-analysis-plans/SKILL.md:85` quotes `"How To Update
  State"` literally. Confirmed: `## How To Update State` unchanged, same
  relative position. Resolves.
- `skills/executing-analysis-plans/SKILL.md:87` references
  `analysis-state-management`'s Resume Rule. Confirmed: `## Resume Rule`
  unchanged. Resolves.
- `skills/data-preparation/SKILL.md:82-87` ("Resumability — what index.yaml
  must hold for Phase 1") references "the general resume rule and
  how-to-update-state mechanics" in prose. Confirmed: both sections exist
  with unchanged names/content. Resolves.
- `skills/executing-analysis-plans/SKILL.md:41` — "schema owned by
  `analysis-state-management`, the normal case under causal-conductor on
  OpenCode" re: `topology.nodes`. Confirmed: `topology.nodes` remains part
  of the plain schema in SKILL.md (not moved to the reference). Resolves.
- `hooks/plan-resume:14,82,91` invokes `analysis-state-management` to
  migrate v1 files, naming `index.yaml` + `phases/<id>.yaml` with
  `plausibility_threats`/`topology.nodes`. Confirmed: `## Migrating Old
  Plans` unchanged; field names unchanged. hooks/ not edited. Resolves.
- `hooks/session-context.md:56`, `AGENTS.md:56`, `hooks/skill-chain:38`,
  `hooks/prompt-router:117` reference the skill by name only, no section
  anchors. Resolves (frontmatter untouched).
- `skills/pre-analysis-plan/SKILL.md`, `skills/question-framing/SKILL.md`,
  `skills/causal-identification/SKILL.md`,
  `skills/analysis-checkpoints/SKILL.md`,
  `skills/using-causal-powers/SKILL.md`,
  `skills/using-causal-powers/references/{codex,opencode}-tools.md` — all
  reference the skill by name or by generic schema fields (`index.yaml`,
  `docs/analysis/`), no section-name anchors. Resolves.
- No file anywhere links `#oracle-isolation`, `#resume-rule`, or
  `#how-to-update-state` as a markdown anchor (grepped, zero hits), so
  removing the "Oracle Isolation" heading breaks no anchor link.

No inbound reference was broken. Both protected anchors ("How To Update
State", "Resume Rule") are unchanged in name, position, and content.

## Ambiguous / kept-and-flagged

1. `budget_status.context_pressure` / `continue_same_thread` — the task
   background lists this under conductor-specific schema, but it does not
   appear in `skills/using-causal-powers/references/opencode-tools.md`
   (which does document the fixer/oracle/explorer lane mapping) or anywhere
   else in the repo outside this one file. The underlying rule ("note
   context pressure in a handoff; stop and hand off past ~50% pressure")
   reads as generically useful for any subagent dispatch, conductor or not.
   Kept it in SKILL.md's generic Handoffs section rather than moving it to
   the reference. Flagging in case conductor tooling does parse this field,
   in which case it should be additionally documented (not moved out) in
   conductor-integration.md.
2. `skills/data-preparation/analysis-plan-template.md:55` — this copy-paste
   template (outside edit scope) still includes `owner_node: build-panel`
   unconditionally in its example phase YAML, with no conductor caveat.
   After this split, a plain (non-conductor) user copying that template
   picks up a field SKILL.md no longer documents as part of the default
   schema. Pre-existing artifact of commit 751e99a (which added owner_node
   to SKILL.md and this template together). Not fixed here — out of scope
   per the shared-file rule. Flagging for whoever owns data-preparation to
   reconcile.
3. "Independent review" role generalization — Draft/Review/Approve step 2
   originally read "oracle review"; generalized to "independent review (a
   fresh reviewing session, or an agent such as `analysis-reviewer`)".
   `analysis-reviewer` is a real, generic Causal Powers agent, so this is a
   genuine plain-user equivalent, not a placeholder.
4. `next_action: draft phase-2 topology, request oracle review` (example
   value in the Required Records `index.yaml` sample) also baked "oracle"
   into an illustrative example. Changed to "request independent review"
   for consistency with #3; not explicitly called out in the task
   background but within the spirit of the split.

## Files touched

- `skills/analysis-state-management/SKILL.md` (edited, 1800 -> 1631 words)
- `skills/analysis-state-management/references/conductor-integration.md`
  (new, 730 words)
- `evals/behavioral/notes/analysis-state-management.md` (this file, new)
