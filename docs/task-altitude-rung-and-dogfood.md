# v0.21.0 — task-altitude planning, from real-session dogfood

Driven by reviewing the user's actual sessions (the `PE_OTP_Health_Crime`
project + two CCD analysis sessions), not synthetic benchmarks. The transcripts
gave a sharper diagnosis than any eval.

## What the real sessions showed

**Working in production (v0.20.0, opus/fable):**
- The discipline genuinely fires: `analysis-checkpoints` caught *"drop the
  non-panel clinic"* (refused to silently change the treated sample),
  `causal-identification` fired on a SUTVA/ring-overlap contamination question,
  `wrong-number-debugging` on a co-located-coordinate smell.
- **The Stop-gate shipped that morning was already firing** — the project's
  `.causal-powers/ledger.jsonl` has real entries, and a session shows the block
  reaching the model (*"wrong-number-debugging ran this session but no lesson
  was logged"*).
- **The lessons loop is compounding** — `docs/LESSONS.md` (13 KB, entries dated
  the same day) captures exactly the right failure classes (geocode
  co-location adjudication; a pooled-ATT-≠-displayed-curve estimand trap).

**The gap the user named (sharper than "superpowers owns planning"):**
causal-powers plans at the **study altitude** (estimand / PAP / model card) but
**hand-waves at the task altitude.** "Do a DiD on X and Y" works; *"merge these
two messy sources"* and *"diagnose why this number is off"* get a dive, not a
roadmap-you-agree-to-first. Evidence: on the co-located-coordinate bug the agent
dove into record-dumping and the user had to **interrupt** — *"before doing
anything you need to dig about Milwaukee exact same coordinate issues first"* —
to impose an order. And there is **zero `analysis-plan.md`** in the project
(every planning doc is a superpowers design doc), so the task-level roadmap
artifact never gets produced.

## The fix — task-altitude planning rung

Generalized the existing "write it down before you build" discipline from study
altitude to **task altitude**, carried by the skill bodies (where the user's
real sessions get it) with the always-on card as backstop:

- **`wrong-number-debugging`** — REPRODUCE now ends by *stating the diagnostic
  roadmap (stages, order, where you start) and getting a nod before running
  scans*; LOCATE executes the agreed roadmap. Directly fixes the Milwaukee
  interrupt.
- **`analysis-craft`** — the multi-step build/refactor gets a *numbered roadmap
  confirmed before coding*, and an approved upstream study design explicitly
  does **not** waive the task-level build steps.
- **`data-preparation`** — fires for an *ad-hoc mid-analysis merge/reconcile*
  (not only a from-scratch build), and lays out the phased plan to be *agreed*
  before executing.
- **Card + gateway** — "always a written plan" reframed to **two altitudes**,
  same `write → agree → loop autonomously → checkpoint-on-deviation` pattern;
  guarded by the existing threshold (more than a couple of steps, or touches
  sample/spec/design) so trivial edits aren't taxed.

## Two measurements

1. **Viz-trigger validation (the gate for #1).** `eval-triggers.py --live
   --competitors`, haiku, on `question-framing` with the full competitor menu
   (incl. `superpowers:brainstorming`): **positives won 17/19, negatives clean
   20/20.** All five viz cases (leaflet map, choropleth, dashboard-from-data)
   were wins — brainstorming did *not* steal them; the 2 "losses" went to the
   causal-powers gateway (in-family). The v0.19.0 viz broadening is validated,
   and the precision boundary held (React app / math-function plot /
   design-system Map component correctly did not fire).

2. **Roadmap-first behavioral, card-alone, haiku: 0/1.** The new
   `pressure-roadmap-first` scenario ("just start digging") — the **card arm
   still dove in.** This is *not* a failure of the rung; the behavioral runner's
   card arm injects only `session-context.md`, not the skill bodies, and we
   already knew (v0.20.0 pressure suite) that **card text alone does not change
   a weak model's behavior under a direct instruction.** The rung is delivered
   by the skill *bodies* — which a card-only headless run cannot load, and which
   the user's real opus/fable sessions *do* load. Validating the body-level rung
   needs the full-plugin benchmark arm (plugin installed in the isolated config)
   — the same gap flagged in the v0 benchmark doc — or a real-session re-test on
   the user's tier. The honest status: **implemented where it lands (bodies),
   card-backstop confirmed weak on small models, body-level validation
   deferred to the full-plugin arm.**

## Also in 0.21.0

- **Lesson-nudge recurrence** (`hooks/stop-gate`): the lesson gate now re-fires
  as *new* debugging accumulates without a lesson (capped at 2/session, only on
  growth in the debugging-invocation count), and the escape hatch is to write
  one line to `LESSONS.md` — the lesson *or* a `no-lesson: <why>` note — turning
  a silent dismissal into a recorded decision. Motivated by the live ledger: 5
  debugging stops, 0 lessons logged. Results and lesson gates now use
  independent per-obligation markers.
- **Re-trigger context cost**: the re-trigger rule (card + gateway) now
  distinguishes *re-applying the discipline* (always) from *reloading the skill
  body* (only when it has scrolled out or was compacted away) — a long session
  was reloading full `SKILL.md` bodies on every re-trigger.
