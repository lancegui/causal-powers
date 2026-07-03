# OpenCode tool mapping

The Causal Powers skills are written with Claude Code tool names. On **OpenCode**
the skills load natively — OpenCode auto-discovers any `SKILL.md` under
`.opencode/skills/`, `.claude/skills/`, or `.agents/skills/` (and their `~/`
globals), reads the `name`/`description` frontmatter, and exposes them through its
built-in `skill` tool. When a skill names a Claude Code tool, use the OpenCode
equivalent:

| Skill references | OpenCode equivalent |
|---|---|
| `Task` tool (dispatch a subagent) | `task` — see [Subagent fan-out](#subagent-fan-out-uses-the-task-tool) |
| Multiple `Task` calls in parallel (the robustness fan-out) | Multiple `task` calls (each runs in its own session/context) |
| `Skill` tool (invoke a skill) | Skills load natively — follow the instructions, or invoke via the `skill` tool / `$<skill-name>` |
| `TodoWrite` (task tracking) | `todowrite` / `todoread` |
| `Read` / `Write` / `Edit` (files) | `read` / `write` / `edit` |
| `Bash` (run commands) | `bash` |
| `Grep` / `Glob` (search) | `grep` / `glob` |

## Subagent fan-out uses the `task` tool

`executing-analysis-plans` fans **independent** work (the chosen ~3 robustness
specs, alternative designs, subsample cuts, placebo tests) out to parallel
subagents, and ships two agents — `robustness-runner` (runs one pre-specified
spec, asserts the data contracts, returns a structured result) and
`analysis-reviewer` (independent silent-failure review). On OpenCode these are
dispatched with the **`task`** tool: it spins up a fresh session for the chosen
subagent with its own context window (and optionally its own model), so several
specs run in parallel without colliding.

One wrinkle: OpenCode **disables `todowrite`/`todoread` for subagents by default**
(so background agents don't clutter the main TODO list). That's fine here — the
fan-out subagents return a *structured result*, they don't need to keep a live
plan. The living `analysis-plan.md` is owned by the **primary** agent, which keeps
`todowrite` and the plan file.

If you'd rather not fan out (or are on a setup where the `task` tool is
restricted), the fan-out **degrades to inline** — run the chosen specs one at a
time in the current session, still bounded to ~3, still each validated with the
data-contracts checks. This is the *inline* arm of the execution-mode choice
`executing-analysis-plans` already presents.

## Re-apply, don't reload (skills don't dedup on OpenCode)

Causal Powers is built to **re-fire per analytical request** — a new spec, a new
cut, a re-run all re-trigger the relevant skill. That re-triggering is correct and
deliberate; it is the guard against "I already have the context."

But **no harness dedups skill loads for you by default** — on OpenCode (as on
Claude Code) the `skill` tool will happily re-inject a skill's **full body** every
time you call it. The failure mode (measured in real sessions): the orchestrator
reloads `using-causal-powers` / `question-framing` **15–19 times in one session**,
~1–2% of total input tokens re-injecting text already on screen — pure token churn
dressed up as discipline.

One optional machine layer exists: the **causal-conductor** OpenCode plugin
(separate repo) rewrites messages in flight via
`experimental.chat.messages.transform`, keeping the first `<skill_content>` load
per skill and stubbing later duplicates. If it's installed, duplicates cost ~a
line instead of a body; set `CAUSAL_CONDUCTOR_DEBUG=1` to observe it (it is
silent otherwise, and the session DB stores pre-transform bodies, so don't look
there for proof). Do not rely on it being present.

The rule (with or without the suppressor):

- **Body still in context?** Don't call the `skill` tool. **Narrate** the
  re-application instead — "re-applying `causal-identification` (still loaded)" —
  and proceed. The discipline re-fires; the file does not.
- **Body scrolled out** (long session, post-compact, or you genuinely can't see
  it)? *Then* re-invoke the `skill` tool to reload it.
- A batch of skills loaded once at the top of a turn is fine; re-loading that same
  batch on **every** subsequent turn is the anti-pattern.

This is the OpenCode-specific enforcement of the *re-apply-don't-reload* line in
the always-on discipline block (`AGENTS.md`).

## What does NOT carry over from Claude Code (and what replaces it)

The plugin's `hooks/` are Claude-Code-only. On OpenCode:

- **Always-on discipline** (the SessionStart injection) → lives in **`AGENTS.md`**.
  OpenCode reads the repo-root `AGENTS.md` (a symlink to `hooks/session-context.md`)
  when you work in that tree, and the global `~/.config/opencode/AGENTS.md`
  everywhere; all instruction files are combined. The `--opencode` installer writes
  the managed discipline block into whichever you pick.
- **Trigger router + skill-chain** (the UserPromptSubmit / PostToolUse backstops)
  → not needed: OpenCode selects skills from their `description` natively, and each
  skill's own `## When to Use` graph + `## The Process` carry the handoffs.
- **`analysis-plan.md` resumability hook** (SessionStart/PreCompact) → you maintain
  the living plan yourself: keep `analysis-plan.md` current and **flush it before
  you compact**, so a fresh OpenCode session resumes from the file (disk-as-RAM).
- **Stop-gate** (the Stop hook that blocks an unverified results-write) → no hook
  equivalent ships here. The **causal-conductor** spine plugin, if installed,
  gates mutating tools behind an approved contract (`tool.execute.before` throws
  until a `<spine_contract>` is approved) — a stricter gate than Claude Code's.
  Without it, *result-verification before reporting* is pure discipline: treat it
  as the gate.
