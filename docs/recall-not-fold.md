# v0.22.0 — recall, not fold (the two-layer learning model)

A design decision the user drove, after asking the right question: *"are lessons
and memory being used effectively — I don't want it to become bloat?"* The audit
that prompted it:

- The card had **re-bloated 970 → 1256 words** since the v0.19.0 diet — every
  "improvement" added to it with no eviction rule.
- The project's `docs/LESSONS.md` was **rich but write-only**: ~16 high-quality
  lessons, **0 ever read back** (grep: 4 capture sites in the skills, 0 recall
  sites).
- One **22 KB memory file** on a dormant project — a document, not a fact.

## The decision: lessons live in the project; skills point to them

The tempting fix — fold lessons into the general skills — is **wrong**, because
the lessons are domain-specific (ARCOS, CBSA vintage, OTP ring-overlap). Folding
them would bloat the shared family with one project's idiosyncrasies and ship
*other* users a `data-contracts` skill muttering about opioid-treatment
geocoding. The user's reframe was correct:

> Lessons should stay inside each project (they're domain-specific); the skills
> should be **pointed to** the lessons/memory, not absorb them.

So the model is **two layers with a recall link**:

| Layer | Content | Property |
|---|---|---|
| General skills + card | the *method* — domain-free discipline | lean, stable, shareable; never absorbs project trivia |
| Project `LESSONS.md` + memory | the *scar tissue* — domain-specific failures | per-project, grows there, that's its home |
| **The link (this release)** | **recall** — skills point to the project store at the right moment | one pointer, O(1) as lessons grow — no skill bloat |

The real gap was never "lessons → skill edits"; it was **recall**. Capture
without consult is a write-only journal. And **evolution and de-bloat are the
same act**: the moment you go to *consult* a store is exactly when you'd notice
it has rotted — so recall carries a tail: *if it's bloated/stale while you're in
there, suggest a consolidation pass* (demand-driven, never scheduled, never
auto-run).

## What shipped

**Recall + consolidation-suggestion wiring** (the only permanent addition — text
in 3 existing files, no new skill):
- **Card** — a "Consult the project's memory, and keep it lean" section: consult
  `LESSONS.md` + memory at start / before a join / before reporting; recalled
  here, *not folded into the skills*; if a store is bloated/stale while
  consulting, *suggest* consolidation.
- **`result-verification`** — "Capture what bit you" became **"Consult — and
  capture — what bit you"**: read the scar tissue at the start and before
  reporting (recall), capture at the end, and folding upward is explicitly the
  *rare* exception (pattern-only, sign-off required), not the default.
- **`data-contracts`** — before a merge, consult the project log for prior
  join/coverage/vintage failures in *this* data (the recall half of the
  capture loop).

**Two domain-free pattern folds** (the *pattern* stripped of domain; the
instance stays in the project — the rare exception, done deliberately):
- `data-contracts` invariant catalog — **versioned/vintage join keys** (CBSA,
  FIPS, codes, crosswalks) must assert the *same vintage* on both sides, not
  just the same key. (Generalizes the project's CBSA-vintage mismatch lesson.)
- `result-verification` item 4 — a robustness check that returns a number
  **identical to the baseline didn't perturb anything** and is a silent no-op,
  not evidence. (Generalizes the project's leave-one-out no-op lesson.)

**Card re-diet + eviction rule** — 1256 → 1156 words *while adding* the recall
section (so the pre-existing prose compressed ~210 words), plus a top-of-file
budget comment: every future addition must compress or evict, target ≤ ~1050.

**Memory consolidation** (run via the `consolidate-memory` skill, on the
suggestion model — surfaced because the need was evident): the 22 KB dormant
proxy file → **3 KB** (−86%), keeping the orientation + the one durable
multi-session conclusion + gotchas, dropping the superseded phase-by-phase
narrative and re-derivable commands/test-names; refreshed the stale index line.

## How "evolving" should feel now

The general family evolves *slowly and deliberately* (it's the method — you
don't rewrite the textbook per dataset). What *compounds* is the **project**:
you'll feel it the first time a session says *"this project's LESSONS flags a
vintage-join trap in this geography — asserting vintage before I merge."* That's
recall firing — the project remembering its own scars — and it's now wired at
the three moments it matters, without growing the shared skills by more than a
pointer.
