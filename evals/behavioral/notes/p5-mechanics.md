# P5 — mechanics notes (2026-07-20)

Branch `thin-2026-07`. Scope: `hooks/stop-gate`, `scripts/test-stop-gate.sh`,
one section of `skills/project-organization/SKILL.md`. No git commands run;
CHANGELOG/plugin.json untouched (orchestrator's release close-out).

## 1. Stop-gate regex bug (BSD/GNU bracket-expression hazard)

**Finding:** the exact bug described in the July audit — `[^\n]` inside a
grep bracket expression — was **already fixed on this branch** by commit
`1904c2c` (2026-07-03, "C1+C2: stop-gate detectors survive the hook's C
locale"), which predates the 2026-07-19 audit plan that still lists it as
open. A full re-audit of every bracket expression in `hooks/stop-gate`
(`grep -n '\['`, plus a repo-wide scan for `\[[^]]*\\[a-zA-Z][^]]*\]` under
`hooks/ scripts/ src/`) found **no remaining live occurrence** of the hazard
— only the two comments documenting the historical bug. So there was no code
change needed to the live detectors; the work here is (a) verifying that
conclusion empirically, (b) tightening the comment to state the GNU-vs-BSD
difference explicitly (the audit's ask), and (c) adding the regression
coverage that would have caught the original bug, which did not exist before
this pass.

**Root cause (confirmed empirically on this machine, BSD grep 2.6.0-FreeBSD,
`env -u LANG -u LC_ALL`, matching the hook's actual no-LANG runtime):**
POSIX gives backslash no escaping power inside a bracket expression, so
`[^\n]` means "not backslash, not the literal letter n" — two literal
characters — never "not a newline". Any real transcript line has an `n`
in the `,"input":{` gap between the tool name and `file_path` (from
`"input"` itself), so the old pattern's `[^\n]*` broke exactly there, every
time, on BSD grep. GNU grep's glibc regex engine treats `\n` inside a
bracket expression as a real newline escape in many locales — a documented
GNU extension over POSIX — so the identical text can look correct in a
typical GNU/Linux dev shell and only fail once it reaches this hook's
locale-less (`C`) runtime. There is no grep mode where `[^\n]` reliably means
"not a newline" across both implementations; the fix is `.*` (grep is
line-based, so `.*` cannot cross a real newline anyway) or `[^"]*` scoped to
the quoted JSON value.

**Edit made:** expanded the existing one-paragraph comment in
`hooks/stop-gate` (above the `wrote_results` detector) into the fuller
explanation above, so the GNU-vs-BSD contrast is explicit rather than
implied. No functional line changed — `wrote_results` (line 85) and
`lessons_touched` (line 100) already use `.*` / `[^"]*`.

**Empirical demonstration (before/after), run on this machine's BSD grep:**

Reconstructed the pre-fix hook in scratch
(`hooks/stop-gate` with the two detector lines reverted to their
`1904c2c`-parent content, i.e. `[^\n]*` restored) and ran the same fixtures
through both versions, in the hook's real C-locale runtime:

```
=== Fixture 1: real deliverable write, no verification (should BLOCK) ===
-- buggy hook --
(nothing printed — gate stayed silent: wrote_results never set, so the
 results gate never even considers firing)
-- fixed hook --
{"decision": "block", "reason": "A results artifact was written this
 session but causal-powers:result-verification never fired. ..."}

=== Fixture 2: wrong-number-debugging fired, LESSONS.md edited after
    (lesson gate should be satisfied -> silent) ===
-- buggy hook --
{"decision": "block", "reason": "wrong-number-debugging has run 1x this
 session and no lesson is logged. ..."}   <- FALSE POSITIVE: a lesson WAS
 written, but lessons_touched never got set, so the nudge fires anyway
-- fixed hook --
(silent — correctly recognizes the LESSONS.md edit)

=== Ledger contents (wrote_results / lessons_touched columns) ===
buggy: {"wrote_results":0,"verification_fired":0,"debugging_fired":0,"lessons_touched":0}
fixed: {"wrote_results":1,"verification_fired":0,"debugging_fired":0,"lessons_touched":0}
```

This reproduces the "0/62 ledger" symptom directly and shows both failure
directions: the buggy hook silently under-blocks (misses a real
unverified-results case) and over-blocks (nudges for a lesson that was
already written) — both explained by the same broken detector.

**Note on "before" for the committed suite:** the live hook was never buggy
on this branch (the fix landed in `1904c2c`, before this pass started), so
there is no historical committed-suite run to show failing. The "before"
evidence is the scratch reconstruction above (a byte-for-byte copy of the
pre-`1904c2c` detector lines run against real fixtures), which demonstrates
the bug concretely. The new regression cases added to the suite encode the
same check going forward: `wrote_results(BUGGY)-...-regression` and
`lessons(BUGGY)-...-regression` assert the historical buggy pattern
(hardcoded as a fixture, never wired into the hook) returns `nomatch` on a
fixture the live, fixed pattern correctly `match`es — i.e. they PASS today
specifically because the bug is fixed, and would have FAILED had they
existed and been run against the pre-`1904c2c` hook, which is what makes
them a valid regression guard against this exact class of hazard recurring.

**Test-script output, after (current, full suite):**

```
$ bash scripts/test-stop-gate.sh
PASS  deliverable-paths-block
PASS  verified-with-evidence-silent
PASS  plan-and-scripts-silent
PASS  lesson-written-silent
PASS  lesson-missing-nudges
PASS  verified-without-evidence-blocks
PASS  non-deliverable-write-silent
PASS  near-miss-lessons-filename-still-nudges
PASS  wrote_results(fixed)-matches-real-deliverable
PASS  wrote_results(fixed)-no-match-wrong-tool
PASS  wrote_results(fixed)-no-match-non-deliverable-path
PASS  lessons(fixed)-matches-LESSONS-edit
PASS  lessons(fixed)-no-match-near-miss-filename
PASS  wrote_results(BUGGY)-misses-real-deliverable-regression
PASS  lessons(BUGGY)-misses-LESSONS-edit-regression
----
ALL PASS
```

15/15 pass on this machine (BSD grep 2.6.0-FreeBSD, macOS), exit code 0.
8 original cases + 7 new: 2 negative-fixture cases (6, 7) added to the
end-to-end suite, and 5 detector-level `check_re` cases (5 "fixed" +
2 "buggy regression") that isolate the two grep patterns directly —
extracted live from `hooks/stop-gate` via `sed` so they cannot silently
drift out of sync with what ships, compared against a hardcoded historical
copy of the pre-fix pattern kept only as a regression fixture.

**File-level diff summary:** `hooks/stop-gate` +11 lines (comment only,
142 lines total). `scripts/test-stop-gate.sh` +73 lines (56 -> 128 lines):
2 new end-to-end cases (6, 7) plus a "Detector-level regression tests"
section (`extract_grep_pattern`, `check_re`, 5 fixed-pattern + 2
buggy-pattern-regression cases).

## 2 & 3. Checkpoint-commit doctrine + lessons promotion
(`skills/project-organization/SKILL.md`, "## Checkpoint as you go" section)

Edit was surgical: only this section changed (one new leading bullet, one
new trailing bullet, the old intro paragraph's imperative moved into the
new leading bullet). The other four bullets (when to checkpoint, commit≠push,
name the milestone, don't checkpoint junk) are byte-identical to before.

### 2. Commit-nudge mechanics — before/after

**Before:**
> So **commit locally at phase boundaries, proactively, without being
> asked** — "only commit when asked" is the wrong default for a research
> repo.

**After** (new leading bullet, replaces the sentence above):
> - **Nudge once, then act.** At the first phase boundary, ask once whether
>   to commit a checkpoint. If the user waves it off or doesn't answer,
>   **do not ask again** — repeating "commit a checkpoint?" turn after turn
>   trains the user to ignore it while the tree stays uncommitted regardless
>   (observed: asked and ignored ~6 consecutive turns). Instead, state once,
>   briefly, that uncommitted work is at risk, then **commit locally at
>   every later phase boundary without asking** — "only commit when asked"
>   is the wrong steady-state default for a research repo, but a single
>   upfront nudge is not.

The commit≠push line is untouched:
> - **Commit ≠ push.** A **local commit** on your branch is cheap, private,
>   and reversible — that's the checkpoint, and it's yours to make.
>   **Pushing** (or opening a PR) is outward and shared, so *that* stays the
>   user's explicit call (`analysis-checkpoints`). "Only when asked" governs
>   **push**, never the local checkpoint.

### 3. Lessons promotion at phase close — new bullet (after "Don't checkpoint junk")

> - **Promote lessons at the checkpoint, not at session end.** As part of
>   each phase-boundary checkpoint, scan what the phase surfaced — a
>   construct-validity flaw, a bad control identified, a data quirk — for
>   anything durable and reusable, and write it to `docs/LESSONS.md` then.
>   A finding left in a throwaway working ledger and never promoted is a
>   finding lost — this is exactly how two paper-relevant lessons died in a
>   session's scratch audit notes instead of reaching `docs/LESSONS.md`.

### Word-count delta

`skills/project-organization/SKILL.md`: **1560 -> 1713 words (+153, +9.8%)**.
This is a doctrine-mechanics addition, not a thinning edit — it moves the
opposite direction from this branch's overall word-reduction goal by
design, since P5 fixes real gaps the earlier thinning loop could not have
introduced or removed (both new obligations are net-new content: the
"ask once" sequencing and the lessons-promotion trigger did not exist in
any prior wording of this section). No other section of the file was
touched; the rest of the ~1560-word body carries over unchanged from the
project-organization thinning loop's final delivered state recorded in
`evals/behavioral/notes/project-organization.md`.

## Verification: po-placement / po-raw-data-guard re-run after edits 2-3

Ran `scripts/run-skill-eval.py`, `--scenarios po-placement
po-raw-data-guard --arm 'file:skills/project-organization/SKILL.md'
--reps 3 --thinking off` (C-only, the post-edit file) twice:

1. **Subject `ollama/deepseek-v4-pro:cloud`, `--jobs 2`**: all 6 reps hit a
   genuine, persistent 429 ("you (lanceguixiaofan) have reached your session
   usage limit... ollama.com/upgrade") in ~16s each, 0 graded. This matches
   the exact failure mode and message already documented in
   `evals/behavioral/notes/project-organization.md`'s "Provider incident"
   section from the prior loop — not a new problem, a known rate-limit on
   this account. Run: `evals/behavioral/runs/20260720-135239-p5-verify/`.
2. **Fallback, subject `deepseek/deepseek-v4-pro` (direct API), `--jobs 1`**
   per the task's fallback instruction and this branch's established
   precedent for this exact failure: all 6 reps completed and graded.
   Run: `evals/behavioral/runs/20260720-135347-p5-verify-fallback/`.

| scenario | result | recorded band (this file's prior notes) | verdict |
|---|---|---|---|
| po-placement | **3/3** | noisy, 50-100% | pass — within band, at the high end |
| po-raw-data-guard | **3/3** | stable, 2-3/3 | pass — within band |

Both results land inside the previously recorded bands, so the doctrine
edits in this pass (checkpoint-nudge mechanics, lessons-promotion bullet)
show no measurable regression on either probe. Neither probe exercises the
edited section directly (both are single-turn scenarios; the checkpoint
section is explicitly flagged in `project-organization.md` as
"entirely temporal/multi-turn... this single-turn harness cannot probe it
at all") — this re-run is a **non-regression check on the rest of the file
under the new, longer skill text**, not a validation of the new doctrine
itself, consistent with how the section was already scoped in the prior
loop's notes.

**Budget:** 12 subject runs total (6 errored/ungraded on
`ollama/deepseek-v4-pro:cloud`, 6 graded on the `deepseek/deepseek-v4-pro`
fallback) — at the 12-run cap, none over.

## Summary

- `hooks/stop-gate`: no functional change (fix already shipped in `1904c2c`
  on this branch, predating the audit plan that flagged it); comment
  expanded to state the GNU-vs-BSD bracket-expression difference explicitly.
- `scripts/test-stop-gate.sh`: 7 new cases (2 end-to-end negative fixtures +
  5 detector-level `check_re` cases, 2 of which are the buggy-vs-fixed
  regression proof the audit asked for). 15/15 pass on this machine's BSD
  grep.
- `skills/project-organization/SKILL.md`: checkpoint section restructured
  from "ask every time" (in practice, per the audit) to "nudge once, then
  act"; new lessons-promotion-at-phase-close bullet added. +153 words
  (1560 -> 1713), surgical to one section.
- Verification: po-placement 3/3, po-raw-data-guard 3/3, both within
  recorded bands; Ollama Cloud 429'd, direct DeepSeek API fallback used
  and noted; 12/12 subject-run budget used.
