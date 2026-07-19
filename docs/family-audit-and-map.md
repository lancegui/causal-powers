# Causal Powers — family audit & structural map (2026-06-09, refreshed 2026-07-19)

Audit of all 13 skills + 2 agents + hook/gateway across four lenses: fluff,
LLM-workflow clarity, HITL triggering, pipeline holes. Maps first, then the
tiered fix plan.

**2026-07-19 refresh.** The family grew from 13 to 17 skills: `descriptive-evidence`,
`predictive-modeling`, `analysis-state-management`, and the current phased
`data-preparation` were added after this audit was written. Maps 1–3 below are
updated in place to include the four additions (marked **[new]**). Phase P1 of
`docs/plans/2026-07-19-skill-thinning-behavioral-loop.md` also ran a fresh
redundancy pass across all 17 post-edit files — see **Map 4″** at the bottom,
which supersedes Map 4 / Map 4-done below for anything it re-touched and adds
the new-since-2026-06-09 redundancies those two never covered.

**Framing fact:** only the **hook card** (`session-context.md`) is guaranteed in
context (injected on every startup/clear/compact). Every skill body — and every
HITL gate inside it — loads *only when that skill triggers*. So a gate that lives
**only in a skill body is contingent**; a gate **on the card is reliable**. This
drives most of the holes below.

---

## Map 1 — Pipeline & ownership

```
        ┌──────────────────────────── ALWAYS-ON CARD (hook) ────────────────────────────┐
        │ creed · NEVER-CHANGE-THE-GOAL · WRITE-IT-DOWN · workflow spine · red-lines      │
        └─────────────────────────────────────────────────────────────────────────────┘
 throughout ▸ analysis-craft (legible code)   ▸ analysis-checkpoints (HITL core)
            ▸ analysis-state-management [new] (docs/analysis/ schema — every phase/skill above reads/writes through it)

 FRAME ─▶ [PLAN]* ─▶ APPROVE ─▶ EXECUTE ─▶ MODEL (fork below) ─▶ (DEBUG) ─▶ VERIFY ─▶ REVIEW ─▶ ORGANIZE
   │         │          ▲         │              │                   │          │         │          │
 question  pre-       (gate)   executing-     see fork              wrong-     result-   analysis-  project-
 framing   analysis-           analysis-                            number-    verifi-   review     organization
           plan OR             plans (Phase 1 = data-preparation    debugging  cation                (tidy→git)
           model card          [current], calling data-contracts
           (structural)        per step)

   └─ MODEL fork — four arms, chosen by GOAL not algorithm (description sits BENEATH the fork, not inside it):
        "just a faithful picture of the data?" → descriptive-evidence [new] (often the whole deliverable; else it motivates one of the three below)
        "decision inside the data?"            → causal-identification (reduced-form)
        "world you haven't observed?"          → structural-estimation (structural)
        "a score/rank to drive an action?"     → predictive-modeling [new] (prediction)
 * PLAN only if confirmatory ── and "is it confirmatory?" is a SILENT judgment in the original audit — resolved, see Map 2′ (H1)
```

---

## Map 2 — HITL gates and their reliability  ★ the diagnostic map

Legend:  ✅ on the card (reliable) · ⚠️ skill-body only (contingent on routing) ·
❌ missing / contradictory / too-late

| # | Decision point (user's call) | Gate? | Reliability | Issue |
|--|--|--|--|--|
| 1 | Confirm the framing brief | yes | ⚠️ | body-only; ok-ish (framing fires first) |
| 2 | **Is this confirmatory? → PAP** | **no** | ❌ | silent judgment; if mis-called, PAP gate skipped (H1) |
| 3 | PAP sign-off before outcomes | yes | ⚠️→❌ | fires "before estimating" — too late; should be before *touching outcome data* |
| 4 | Model-card sign-off (structural, greenfield) | yes | ✅ | strong (card + skill) |
| 4b | Model-card sign-off (structural, mid-pipeline) | yes | ⚠️ | softer "confirm" vs greenfield "sign-off" — and mid-pipeline is the *usual* case |
| 5 | Design / identification change | yes | ✅ | card carries it |
| 6 | Estimand / spec / metric change | yes | ✅ | card carries it |
| 7 | **Drop / winsorize / filter (sample)** | yes | ⚠️ | card says "sample" generally, but NOT forward-referenced from data-contracts / wrong-number-debugging where dropping happens (H4) |
| 8 | **Robustness shortlist (propose ~3, WAIT)** | yes | ⚠️ | full gate only in executing-analysis-plans; card frames it as *parsimony*, not a STOP (H2) |
| 9 | **Restoring-fix that moves a seen number** | — | ❌ | contradiction: checkpoints calls join-fix "autonomous" but seen-number "STOP" (H3) |
| 10 | **A verification check fails → stop before reporting** | **no** | ❌ | result-verification only says "say so" → ships behind a caveat (H5) |
| 11 | Delete files (cleanup) | yes | ✅ | card: "don't delete on your own; never touch raw" |
| 12 | **Edit the skill files (lessons)** | **no** | ❌ | result-verification licenses editing skills, no sign-off guard (H6) |
| 13 | **Non-interactive run (no user to WAIT for)** | — | ❌ | every WAIT gate deadlocks or gets rationalized in batch mode (H7) |

Reliable gates cluster where the card carries them (4,5,6,11). The leaks are all
**body-only or missing** (2,3,7,8,9,10,12,13).

---

## Map 3 — Holes (broken / missing edges)

```
 H1  question-framing ──✗── pre-analysis-plan      no forced "is this confirmatory?" gate
 H2  post-approval ────✗── executing-analysis-plans  3 skills grab "estimate"; spine/fan-out owner may never load
 H4  data-contracts / wrong-number-debugging ──✗── analysis-checkpoints   for SAMPLE drops (only design routed)
 H8  result-verification ──✗── analysis-reviewer    no autonomous self-review handoff
 H9  result-verification ──✗── project-organization no autonomous tidy-before-git handoff
 H10 structural "VALIDATE FIT" pipeline step ──✗── (no section anywhere to execute)
```

A handoff that exists only as a sibling-list mention ≠ a step that fires. H8/H9
and H1 are intended-flow steps that only happen if the *user* utters the trigger
phrase — an autonomous agent skips review, tidy, and (worst) the PAP gate.

---

## Map 4 — Redundancy matrix (full restatements; → centralize)

| Rule | Stated in full in… | Keep full in | Reduce to pointer in |
|--|--|--|--|
| write-it-down / ~10-min / compact-at-phase | card · gateway · analysis-craft · executing-analysis-plans · structural | card (1-liner) + executing | gateway, analysis-craft, structural |
| robustness = argument not inventory | card · checkpoints · executing · causal-id · result-verification | executing | card (1-liner) + the other 3 |
| "dropped mid-pipeline ≠ licence to dive in" | gateway · card · structural ×3 | card (1-liner) | structural → keep red-flag + rationalization only |
| "template not a catalog" | structural · model-classes.md | model-classes.md | structural → one-line pointer |

Load-bearing repetition to **keep**: the "never change the goal" rule in every
sibling list — that's what makes HITL survive independent skill loading.

---

## The tiered fix plan

**Tier 1 — correctness / does-the-discipline-fire (highest value)**
- H1: add an explicit "is this confirmatory?" gate to `question-framing` → hand to `pre-analysis-plan`.
- H8/H9: bake "dispatch `analysis-reviewer`" and "tidy with `project-organization`" into `result-verification` as steps.
- Card gates: add **robustness-shortlist STOP** and **sample-drop (drop/winsorize/filter)** to the card's "one rule" list.
- H3: `analysis-checkpoints` tiebreaker — a restoring fix that moves an already-seen number is still a checkpoint.
- H7: shared non-interactive fallback — stop at last validated state, don't implement the checkpoint-class change, return options+recommendation.
- H5: `result-verification` fail-stop (a failed check you can't resolve → stop, surface to user).
- H6: guard the "fold lessons into the skill" instruction (LESSONS.md note / sign-off).
- H3(PAP): move the PAP blinding gate to "before touching outcome data."

**Tier 2 — LLM-workflow clarity**
- `structural-estimation`: collapse pipeline steps 1–3 → `WRITE THE MODEL CARD → GET APPROVAL`; harden the mid-pipeline gate to a real sign-off; add the missing **VALIDATE FIT** section (hold-out + elasticity cross-check).
- Replace the unmeasurable **~10-minute** trigger with "single-file, single-function edit, no new estimand/spec/sample decision"; define **"check it"** = "invoke the Skill tool."
- `question-framing`: move "form your economic prior" *above* the confirm-and-stop (ordering bug).
- `data-contracts`: inline a concrete "make it bite" method into the loop; demote "recall the incident."
- H2: name `executing-analysis-plans` as the execution owner at the post-approval junction.
- `causal-identification`: reconcile "mandatory battery" vs "argument not inventory" (mandatory = threat-relevant subset).
- `analysis-reviewer` agent: add "What you'll be given" + explicit "review-only, don't edit" boundary (mirror `robustness-runner`).
- Reconcile model-card 6 bullets vs 5-row template; make the Hessian/ridge check imperative; give "report a range" a method; fix grad_check skeleton's unused param; add a recovery tolerance default.

**Tier 3 — de-fluff (Map 4)**
- Centralize the 4×/5× repeated rules to one-liner-plus-pointer.
- Halve `structural-estimation`'s "Write the model card" section.
- De-dup the "template not a catalog" sermon.
- Trim local aphorism doublings (keep the creed motif).

**Pre-analysis-plan extras (Tier 1/2):** multiple-comparisons correction for secondary hypotheses; MDE/power so a null is informative.

---

# AFTER — map redrawn (fixes applied, commits c17c77d → 672409a)

## Map 2′ — HITL gates, now

✅ on the card (reliable) · ☑ gated in a body that reliably fires · — unchanged-good

| Decision point | Before | After | How |
|--|--|--|--|
| Design / identification change | ✅ | ✅ | (unchanged) |
| Estimand / spec / metric change | ✅ | ✅ | (unchanged) |
| Model-card sign-off (greenfield) | ✅ | ✅ | (unchanged) |
| Delete files | ✅ | ✅ | (unchanged) |
| **Is this confirmatory? → PAP** | ❌ | ☑ | explicit gate at `question-framing` (fires first) |
| **PAP blinding gate** | ❌ | ✅ | now "before touching outcome data" |
| **Drop / winsorize / filter (sample)** | ⚠️ | ✅ | named on the card + forward-refs in data-contracts & wrong-number-debugging |
| **Robustness shortlist (propose ~3, WAIT)** | ⚠️ | ✅ | on the card as a STOP; ATTACK step + executing |
| **Restoring-fix moves a seen number** | ❌ | ✅ | tiebreaker in checkpoints + on the card |
| **Verification check fails → stop** | ❌ | ☑ | fail-stop section in result-verification |
| **Edit the skill files** | ❌ | ☑ | guarded behind sign-off / LESSONS.md |
| **Non-interactive run (no WAIT)** | ❌ | ✅ | fallback on the card + checkpoints step 5 |
| **Model-card sign-off (mid-pipeline)** | ⚠️ | ☑ | hardened to explicit sign-off, "don't proceed on an unconfirmed card" |

## Map 3′ — holes, now closed

```
 H1  question-framing ──▶ pre-analysis-plan      ✓ "is this confirmatory?" gate at framing
 H2  post-approval ──▶ executing-analysis-plans  ✓ flow + "route execution through it" pointer
 H4  data-contracts / wrong-number-debugging ──▶ analysis-checkpoints (sample drops)  ✓ forward-refs + card
 H8  result-verification ──▶ analysis-reviewer   ✓ verification step 9
 H9  result-verification ──▶ project-organization ✓ verification step 9 + relationship
 H10 structural VALIDATE FIT ──▶ its own section ✓ untargeted moments / hold-out / RF cross-check
```

## De-fluff (Map 4) — done
- structural model-card section halved; "template not a catalog" sermon stated once (model-classes.md); gateway plan paragraph + card compact line tightened.
- "robustness = argument" / "write-it-down" now: one-liner on the card, full version in the owning skill (executing-analysis-plans), reconciled in causal-identification.

## Residual (deliberately left)
- The "never change the goal" rule still restated in every sibling list — **load-bearing** (HITL must survive independent skill loading), kept by design.
- A couple of local aphorism doublings (creed motif) — kept as voice.

---

# Map 4″ — redundancy matrix, re-derived post-P1 (2026-07-19)

An audit ahead of `docs/plans/2026-07-19-skill-thinning-behavioral-loop.md` found
~45,000 words across the (then-)17 skills, a templated tail (Red flags / Common
rationalizations / dot digraph / bottom-line box) making up 21–27% of every
file, and several obligations restated near-verbatim in 15–16 of 17 files. Phase
P1 ran one central dedup pass establishing the conventions below; per-skill
thinning agents (P3) work *within* them rather than re-deciding the dedup
independently. This table re-derives Map 4 from the **post-edit** files —
supersedes the original Map 4 for every row it touches.

| Rule | Was stated in full in… | Now stated in full in | Pointer left in |
|--|--|--|--|
| Locked-doc gate mechanics (write to file → sign-off before the load-bearing step → living-but-load-bearing-changes-checkpoint → mid-pipeline reconstruct-and-confirm) | `question-framing` (brief), `pre-analysis-plan` (PAP), `causal-identification` (Design Card), `structural-estimation` (model card), `predictive-modeling` (Prediction Spec) — near-verbatim in all five | **`analysis-checkpoints`** (new "The locked-document gate — shared mechanics" section) | all five keep only their document's fields + when it fires + a 1–2 line pointer |
| STOP-gate full statement (design/estimand/sample/spec change, drop/winsorize/filter, a number already seen) | restated at varying length in 16/17 skills, incl. a verbatim-duplicate worked example (the "Beverly 2016 near-clinic" scenario) in both `analysis-checkpoints` and `wrong-number-debugging` | **`analysis-checkpoints`** (full list + the one worked example) | every other skill: one line naming its own trigger (a failed diagnostic, a misfitting model, a re-cut spec, a consequential cleaning choice…) + pointer; domain-specific STOP examples that ARE a skill's core content (e.g. `data-preparation`'s four consequential-cleaning triggers) kept, compressed |
| dot/graphviz digraphs restating the adjacent numbered Process list | 15 of 17 skills (`analysis-state-management` and `using-causal-powers` never had one) | *(deleted — no owner; the list wasn't distinct content)* | the prose `## The Process` list, already adjacent in every file, is the only thing left |
| Red flags / Common rationalizations tail tables, uncapped | every skill with a tail — several ran 8–12 rows per table | each skill's own table, capped ~6 rows, keeping only rows unique to that skill's domain | rows that were pure within-file restatement of a Process/discipline point already stated above the table were cut, not relocated (the point survives in the prose) |
| result-verification / analysis-review / wrong-number-debugging checklist overlap (joins, missingness, totals, units/grain, reproduce-from-clean, artifacts-match-prose) | ~85% overlapping across the three | **`result-verification`**'s "The verification checklist" (unchanged, 9 items) | `analysis-review` points to it and keeps only its distinct content (adversarial posture, dispatching the `analysis-reviewer` agent, verifying received critiques); `wrong-number-debugging` points to it (and to `data-contracts`' invariant catalog, the actual source of the "usual culprits" list) and keeps only the bisection method |
| Always-on card word budget | card had crept to 1243 words against its own ≤~1215 comment | compressed in place (`## Describe first, then model`, `## Always a written plan`, `## Keep the repo legible`, `## Platform note`) | now 1206 words; `AGENTS.md` re-synced byte-identical |

**Kept as two distinct obligations, not merged (flagged, not deleted):**
- `question-framing`'s "Watch for the silent reframe" (a metric/estimand definition drifting once data is seen) and `analysis-checkpoints`'s general STOP-gate are related but not the same claim — framing's is about *definitional* drift specifically, checkpoints' is the general design/sample/spec/estimand list. Both kept in full at their own sites; framing's is short enough (~3 sentences) that no further compression was applied.
- `pre-analysis-plan`'s "gate fires at touching outcome data, not at estimation" is a PAP-specific tightening of the general locked-doc gate, not a restatement of it — kept in full as PAP's own content, with only the generic write/sign-off mechanics pointed at `analysis-checkpoints`.
- "Robustness is an argument, not an inventory" remains stated in full in `executing-analysis-plans` (owner) with a card one-liner and reconciling mentions in `causal-identification` and `pre-analysis-plan` — this was already resolved by the 2026-06-09 pass (see "De-fluff (Map 4) — done" above) and P1 left it as is; it was not one of the five convention items in scope for this pass.

## Word counts — before P1 / after P1

| Skill | Before | After |
|--|--:|--:|
| analysis-checkpoints | 2033 | 2116 |
| analysis-craft | 2358 | 2045 |
| analysis-review | 1836 | 1513 |
| analysis-state-management | 1800 | 1800 |
| causal-identification | 2808 | 2485 |
| data-contracts | 2603 | 2434 |
| data-preparation | 2874 | 2446 |
| descriptive-evidence | 4713 | 4178 |
| executing-analysis-plans | 2959 | 2655 |
| pre-analysis-plan | 1692 | 1436 |
| predictive-modeling | 4228 | 3513 |
| project-organization | 1899 | 1742 |
| question-framing | 2737 | 2411 |
| result-verification | 2739 | 2536 |
| structural-estimation | 4674 | 4046 |
| using-causal-powers | 2804 | 2799 |
| wrong-number-debugging | 2282 | 1935 |
| **Family total** | **47039** | **42090** |

`analysis-checkpoints` grew (it absorbed five skills' mechanics plus the full
STOP-gate) while the family total fell ~10.5%; the remaining path to the plan's
≤~30k target is the per-skill thinning agents in P3, working inside these
conventions.
