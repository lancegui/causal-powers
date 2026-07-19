#!/usr/bin/env python3
"""Per-skill behavioral loop: run scenario arms against DeepSeek v4 Pro via headless Pi.

Sibling to run-behavioral-eval.py (left byte-identical) — that script's subject
is always `claude -p` with a fixed baseline/card/plugin arm set. This script
adds the two things the per-skill thinning loop (docs/plans/2026-07-19-*) needs
that don't fit that shape without touching it:

  1. A Pi subject runner: `pi -p --no-session --mode json --model
     ollama/deepseek-v4-pro:cloud`, run with cwd = the scenario scratch dir.
     `--mode json` streams a JSONL event log; the subject's final report is the
     last `text` block of the last assistant message inside the final
     `agent_end` event's `messages` array (fallback: the last `message_end`
     assistant event, for a run that never reached agent_end).
  2. A skill-file arm: the injected context (via `--append-system-prompt`,
     which pi accepts as literal text OR a file path) is an ARBITRARY skill
     file, not a fixed card. Arms are given on the CLI as:
       --arm none                                   no injected context
       --arm file:<path>                             a file in the working tree
       --arm 'file:@<gitref>:<path>'                 `git show <gitref>:<path>`
                                                       (read-only; never writes)
     so a caller can diff A (no skill) / B (skill from main) / C (working-tree
     candidate) in one run.

Grading is UNCHANGED: the grader still runs through `claude -p`, reusing
run-behavioral-eval.py's `grade()` and `isolated_config()` verbatim (imported,
not reimplemented) so the catch-criterion logic never forks.

Reps: DeepSeek has no fixed seed, so `--reps N` (default 3) repeats each arm
per scenario and the report is a compact arm x rep caught-table plus a
catch-rate per arm.

Cost / rate-limit note: Ollama Cloud can rate-limit concurrent requests; on a
runner error (including a rate-limit) the raw error is captured verbatim into
that rep's record and graded as ungraded (not retried).

Usage:
  python3 scripts/run-skill-eval.py --scenarios fanout-join \\
      --arm none --arm file:skills/data-contracts/SKILL.md --reps 2

  python3 scripts/run-skill-eval.py --scenarios fanout-join silent-filter-total \\
      --arm none \\
      --arm 'file:@main:skills/data-contracts/SKILL.md' \\
      --arm file:skills/data-contracts/SKILL.md \\
      --reps 3 --jobs 2 --label data-contracts-p2
"""
import argparse
import concurrent.futures as cf
import importlib.util
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
BEH = ROOT / "evals" / "behavioral"

# Import the sibling script as a module (hyphenated filename, so plain
# `import` can't name it) purely to REUSE its infra: sh(), grade(),
# isolated_config(). Importing does not execute its CLI (guarded by
# `if __name__ == "__main__"`), so this has no side effects.
_spec = importlib.util.spec_from_file_location(
    "run_behavioral_eval", ROOT / "scripts" / "run-behavioral-eval.py")
rbe = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rbe)
sh = rbe.sh

PI_THINKING_LEVELS = ("off", "minimal", "low", "medium", "high", "xhigh", "max")


def resolve_arm(spec: str, arm_ctx_dir: pathlib.Path) -> pathlib.Path | None:
    """Resolve an --arm spec to a file path holding the injected context (or
    None for 'none'). `file:@<ref>:<path>` shells out to READ-ONLY `git show`;
    `file:<path>` reads a working-tree path (absolute, or relative to ROOT)."""
    if spec == "none":
        return None
    m = re.match(r"^file:@([^:]+):(.+)$", spec)
    if m:
        ref, path = m.groups()
        r = sh(["git", "show", f"{ref}:{path}"], cwd=ROOT)
        if r.returncode != 0:
            sys.exit(f"--arm {spec!r}: git show failed: {r.stderr.strip()}")
        text = r.stdout
    else:
        m = re.match(r"^file:(.+)$", spec)
        if not m:
            sys.exit(f"--arm {spec!r}: expected 'none', 'file:<path>', or 'file:@<gitref>:<path>'")
        p = pathlib.Path(m.group(1))
        if not p.is_absolute():
            p = ROOT / p
        if not p.exists():
            sys.exit(f"--arm {spec!r}: file not found: {p}")
        text = p.read_text()
    safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", spec)
    dest = arm_ctx_dir / f"{safe}.md"
    dest.write_text(text)
    return dest


def run_pi_subject(task: str, cwd: pathlib.Path, model: str, thinking: str,
                    sysprompt_file: pathlib.Path | None, timeout: int) -> dict:
    """Run one Pi subject turn; parse --mode json's JSONL event stream.

    Pi's default tools (read/bash/edit/write) are left enabled — the subject
    is meant to actually touch the scenario data. Skills/extensions/context-file
    autodiscovery on THIS machine are disabled so the only injected context is
    what we pass explicitly (analogous to run-behavioral-eval.py's isolated
    CLAUDE_CONFIG_DIR for the claude subject)."""
    cmd = ["pi", "-p", "--no-session", "--mode", "json", "--model", model,
           "--thinking", thinking, "--no-skills", "--no-extensions",
           "--no-context-files", "--no-approve"]
    if sysprompt_file is not None:
        cmd += ["--append-system-prompt", str(sysprompt_file)]
    cmd += [task]
    try:
        r = sh(cmd, cwd=cwd, timeout=timeout)
    except subprocess.TimeoutExpired:
        return {"answer": "(TIMEOUT)", "error": f"pi timed out after {timeout}s"}

    events = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            continue  # e.g. a truncated trailing line if the process was killed

    # Grade on ALL assistant text in turn order, not just the final message: a
    # subject that states its roadmap/checkpoint early and ends with a short
    # closing line would otherwise be invisible to the grader (observed floor
    # effect on pressure-roadmap-first — 0/0/0 across all arms).
    def _assistant_text(msgs):
        parts = []
        for i, m in enumerate(msgs):
            texts = [c.get("text", "") for c in m.get("content", []) if c.get("type") == "text"]
            body = "\n".join(t for t in texts if t).strip()
            if body:
                parts.append(f"--- assistant turn {i + 1} ---\n{body}")
        return "\n\n".join(parts).strip()

    answer, error = None, None
    agent_ends = [e for e in events if e.get("type") == "agent_end"]
    if agent_ends:
        assistant_msgs = [m for m in agent_ends[-1].get("messages", []) if m.get("role") == "assistant"]
        if assistant_msgs:
            last = assistant_msgs[-1]
            if last.get("stopReason") == "error":
                error = last.get("errorMessage", "unknown pi error (stopReason=error)")
            answer = _assistant_text(assistant_msgs)
    if not answer:
        message_ends = [e["message"] for e in events
                         if e.get("type") == "message_end" and e.get("message", {}).get("role") == "assistant"]
        if message_ends:
            answer = _assistant_text(message_ends)
    if not answer:
        answer = f"(no parseable pi report; stdout tail: {r.stdout[-1500:]!r})"

    rec = {"answer": answer, "num_events": len(events)}
    if error:
        rec["error"] = error
    if r.returncode != 0:
        extra = f"pi exited {r.returncode}: {r.stderr[-500:]}"
        rec["error"] = f"{rec.get('error', '')} | {extra}".strip(" |")
    return rec


def run_rep(scenario: pathlib.Path, arm_spec: str, arm_file: pathlib.Path | None, rep: int,
            model: str, thinking: str, timeout: int, outdir: pathlib.Path) -> dict:
    safe_arm = re.sub(r"[^A-Za-z0-9_.-]+", "_", arm_spec)
    scratch = pathlib.Path(tempfile.mkdtemp(prefix=f"cp-skilleval-{scenario.name}-{safe_arm}-r{rep}-"))
    shutil.copytree(scenario / "data", scratch / "data")
    task = (scenario / "task.md").read_text()
    m = re.search(r"^REPLY:\s*(.+)$", task, re.M)
    if m:
        print(f"  WARNING: {scenario.name} has a REPLY: gate line; the pi runner is "
              "single-turn only for now — stripping it and running turn 1 alone.")
        task = task.replace(m.group(0), "").strip()

    t0 = time.time()
    rec = run_pi_subject(task, scratch, model, thinking, arm_file, timeout)
    result_md = scratch / "result.md"
    rec.update({
        "scenario": scenario.name, "arm": arm_spec, "rep": rep,
        "artifact": result_md.read_text() if result_md.exists() else "(no result.md written)",
        "duration_s": round(time.time() - t0, 1),
    })
    d = outdir / scenario.name
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{safe_arm}-rep{rep}.json").write_text(json.dumps(rec, indent=2))
    shutil.rmtree(scratch, ignore_errors=True)
    return rec


def grade_rec(rec: dict, plant: str, grader_model: str, env: dict) -> dict:
    if rec.get("error"):
        return {"caught": None, "evidence": f"RUNNER ERROR (not graded): {rec['error'][:180]}"}
    return rbe.grade(rec, plant, grader_model, env)


def build_report(recs: list, arms: list, reps: int, ts: str, model: str, grader_model: str) -> str:
    by_scenario: dict = {}
    for r in recs:
        by_scenario.setdefault(r["scenario"], {}).setdefault(r["arm"], {})[r["rep"]] = r
    lines = [f"# Skill-eval run {ts}",
             f"\nsubject: pi / `{model}` · grader: `{grader_model}` · reps={reps}"]
    overall = {arm: [0, 0] for arm in arms}
    for name in sorted(by_scenario):
        lines.append(f"\n## {name}\n")
        header = "| arm | " + " | ".join(f"rep{i}" for i in range(1, reps + 1)) + " | caught |"
        lines += [header, "|" + "---|" * (reps + 2)]
        for arm in arms:
            row = by_scenario[name].get(arm, {})
            cells, n_caught, n_graded = [], 0, 0
            for i in range(1, reps + 1):
                v = row.get(i, {}).get("caught")
                cells.append({True: "caught", False: "missed"}.get(v, "ungraded" if i in row else "-"))
                if v is not None:
                    n_graded += 1
                    n_caught += int(v)
                    overall[arm][0] += int(v)
                    overall[arm][1] += 1
            rate = f"{n_caught}/{n_graded}" if n_graded else "-"
            lines.append(f"| {arm} | " + " | ".join(cells) + f" | {rate} |")
    lines.append("\n## catch-rate by arm (all scenarios)\n")
    for arm in arms:
        c, t = overall[arm]
        lines.append(f"- **{arm}**: {c}/{t}" if t else f"- **{arm}**: no graded reps")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(
        description="Per-skill behavioral loop: pi subject (DeepSeek v4 Pro) x skill-file arms.")
    ap.add_argument("--scenarios", nargs="*", help="subset; default = manifest")
    ap.add_argument("--manifest", default="manifest.json",
                     help="suite manifest under evals/behavioral/ (e.g. manifest-pressure.json)")
    ap.add_argument("--arm", dest="arms", action="append", metavar="SPEC",
                     help="repeatable: 'none' | 'file:<path>' | 'file:@<gitref>:<path>'")
    ap.add_argument("--model", default="ollama/deepseek-v4-pro:cloud", help="pi --model")
    ap.add_argument("--thinking", default="off", choices=PI_THINKING_LEVELS, help="pi --thinking level")
    ap.add_argument("--reps", type=int, default=3, help="repetitions per arm per scenario")
    ap.add_argument("--grader-model", default="claude-sonnet-4-6")
    ap.add_argument("--timeout", type=int, default=900, help="seconds per pi subject run")
    ap.add_argument("--jobs", type=int, default=1, help="concurrent runs (keep low: Ollama Cloud rate-limits)")
    ap.add_argument("--label", default="skilleval", help="suffix for the run dir name")
    a = ap.parse_args()

    if not a.arms:
        ap.error("at least one --arm required, e.g. --arm none --arm file:skills/data-contracts/SKILL.md")

    names = a.scenarios or json.loads((BEH / a.manifest).read_text())
    scenarios = [BEH / "scenarios" / n for n in names]
    for s in scenarios:
        assert (s / "task.md").exists(), f"missing scenario: {s}"

    ts = time.strftime("%Y%m%d-%H%M%S")
    outdir = BEH / "runs" / f"{ts}-{a.label}"
    outdir.mkdir(parents=True)
    arm_ctx_dir = pathlib.Path(tempfile.mkdtemp(prefix="cp-skilleval-armctx-"))
    arm_files = {spec: resolve_arm(spec, arm_ctx_dir) for spec in a.arms}

    jobs = [(s, spec, rep) for s in scenarios for spec in a.arms for rep in range(1, a.reps + 1)]
    print(f"run {ts}-{a.label}: {len(jobs)} pi runs ({a.model}, thinking={a.thinking}), "
          f"out={outdir.relative_to(ROOT)}")
    recs = []
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        futs = {ex.submit(run_rep, s, spec, arm_files[spec], rep, a.model, a.thinking, a.timeout, outdir):
                (s.name, spec, rep) for s, spec, rep in jobs}
        for f in cf.as_completed(futs):
            rec = f.result()
            tag = "ERROR" if rec.get("error") else "ok"
            print(f"  done {rec['scenario']:22s} {rec['arm']:40s} rep{rec['rep']} "
                  f"{rec['duration_s']:6.0f}s [{tag}]")
            recs.append(rec)
    shutil.rmtree(arm_ctx_dir, ignore_errors=True)

    print("grading...")
    grader_env, isolated = rbe.isolated_config()
    if not isolated:
        print("WARNING: grader running with non-isolated config — see message above.")
    with cf.ThreadPoolExecutor(max(a.jobs, 2)) as ex:
        futs = {ex.submit(grade_rec, r, (BEH / "scenarios" / r["scenario"] / "plant.md").read_text(),
                           a.grader_model, grader_env): r for r in recs}
        for f in cf.as_completed(futs):
            futs[f].update(f.result())

    report = build_report(recs, a.arms, a.reps, f"{ts}-{a.label}", a.model, a.grader_model)
    (outdir / "results.json").write_text(json.dumps(recs, indent=2))
    (outdir / "report.md").write_text(report)
    print("\n" + report)
    print(f"\nartifacts: {outdir.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
