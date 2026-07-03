#!/usr/bin/env python3
"""Behavioral benchmark: does the always-on discipline card catch planted silent failures?

For each scenario in evals/behavioral/scenarios/ this runs two arms through
`claude -p` in a scratch directory containing only the scenario's data/:

  baseline  the task prompt, nothing else
  card      the task prompt + hooks/session-context.md via --append-system-prompt
            (the always-on layer the plugin guarantees in every session)

Both arms run under an ISOLATED CLAUDE_CONFIG_DIR so plugins installed on this
machine can't contaminate the baseline. An LLM grader then applies each
scenario's plant.md catch-criterion to the arm's final report and returns
caught=true/false. Headline metric: scenarios caught, card vs baseline.

Cost note: 2 arms x N scenarios of real agentic analysis on --model (default
sonnet) plus 2N small grader calls. A full 9-scenario run is ~18 agent runs.

Usage:
  python3 scripts/run-behavioral-eval.py                  # full run
  python3 scripts/run-behavioral-eval.py --scenarios fanout-join --jobs 1
  python3 scripts/run-behavioral-eval.py --arms card --model claude-opus-4-8
"""
import argparse, concurrent.futures as cf, json, pathlib, re, shutil, subprocess, sys, tempfile, time

ROOT = pathlib.Path(__file__).resolve().parent.parent
BEH = ROOT / "evals" / "behavioral"
CARD = ROOT / "hooks" / "session-context.md"


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def seed_plugin(cfg: pathlib.Path) -> None:
    """Install THIS repo as the causal-powers plugin inside an isolated config dir,
    replicating the real installed layout (installed_plugins.json v2 +
    cache/<marketplace>/<plugin>/<version>/ + enabledPlugins in settings.json) so
    the plugin arm exercises the actual product: hooks, skills, agents, card."""
    version = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text()).get("version", "0.0.0")
    dest = cfg / "plugins" / "cache" / "causal-powers" / "causal-powers" / version
    dest.mkdir(parents=True)
    ignore = shutil.ignore_patterns(".git", "descriptive-evidence-workspace", "runs", "__pycache__")
    for part in (".claude-plugin", "hooks", "skills", "agents"):
        src = ROOT / part
        if src.exists():
            shutil.copytree(src, dest / part, ignore=ignore, symlinks=False)
    (cfg / "plugins" / "installed_plugins.json").write_text(json.dumps({
        "version": 2,
        "plugins": {"causal-powers@causal-powers": [{
            "scope": "user", "installPath": str(dest), "version": version,
            "installedAt": "2026-01-01T00:00:00.000Z", "lastUpdated": "2026-01-01T00:00:00.000Z",
        }]},
    }, indent=1))
    (cfg / "plugins" / "known_marketplaces.json").write_text(json.dumps({
        "causal-powers": {"source": {"source": "github", "repo": "lancegui/causal-powers"},
                          "installLocation": str(dest), "lastUpdated": "2026-01-01T00:00:00.000Z"},
    }, indent=1))
    (cfg / "settings.json").write_text(json.dumps(
        {"enabledPlugins": {"causal-powers@causal-powers": True}}, indent=1))


def isolated_config(with_plugin: bool = False) -> tuple[dict, bool]:
    """Fresh CLAUDE_CONFIG_DIR (copying credentials if file-based). Returns (env, isolated)."""
    import os
    cfg = pathlib.Path(tempfile.mkdtemp(prefix="cp-eval-config-"))
    src = pathlib.Path.home() / ".claude" / ".credentials.json"
    if src.exists():
        shutil.copy(src, cfg / ".credentials.json")
    else:  # macOS: credentials live in the keychain; materialize into the sandbox
        kc = sh(["security", "find-generic-password", "-s", "Claude Code-credentials", "-w"])
        if kc.returncode == 0 and kc.stdout.strip():
            (cfg / ".credentials.json").write_text(kc.stdout)
    if (cfg / ".credentials.json").exists():
        (cfg / ".credentials.json").chmod(0o600)
    if with_plugin:
        seed_plugin(cfg)
    env = dict(os.environ, CLAUDE_CONFIG_DIR=str(cfg))
    env.pop("CLAUDECODE", None)  # allow nesting inside a Claude Code session
    probe = sh(["claude", "-p", "reply with exactly: ok", "--model", "claude-haiku-4-5"],
               env=env, timeout=120)
    if probe.returncode == 0 and "ok" in probe.stdout.lower():
        return env, True
    detail = (probe.stderr.strip() or probe.stdout.strip())[:200]
    hint = " (CLI auth: run `claude /login` in a terminal)" if "not logged in" in detail.lower() else ""
    print(f"WARNING: isolated config probe failed ({detail}){hint}; "
          "falling back to user config — baseline may be contaminated by installed plugins.")
    env = dict(os.environ)
    env.pop("CLAUDECODE", None)
    return env, False


def run_arm(scenario: pathlib.Path, arm: str, model: str, max_turns: int, env: dict, outdir: pathlib.Path):
    scratch = pathlib.Path(tempfile.mkdtemp(prefix=f"cp-eval-{scenario.name}-{arm}-"))
    shutil.copytree(scenario / "data", scratch / "data")
    task = (scenario / "task.md").read_text()
    cmd = ["claude", "-p", task, "--model", model, "--max-turns", str(max_turns),
           "--output-format", "json", "--dangerously-skip-permissions"]
    if arm == "card":
        cmd += ["--append-system-prompt", CARD.read_text()]
    t0 = time.time()
    try:
        r = sh(cmd, cwd=scratch, env=env, timeout=900)
        payload = json.loads(r.stdout) if r.stdout.strip().startswith("{") else {}
        answer = payload.get("result", r.stdout[-4000:])
    except subprocess.TimeoutExpired:
        payload, answer = {}, "(TIMEOUT after 900s)"
    result_md = scratch / "result.md"
    artifact = result_md.read_text() if result_md.exists() else "(no result.md written)"
    rec = {
        "scenario": scenario.name, "arm": arm,
        "answer": answer, "artifact": artifact,
        "duration_s": round(time.time() - t0, 1),
        "cost_usd": payload.get("total_cost_usd"),
        "num_turns": payload.get("num_turns"),
    }
    if arm == "plugin":
        # Wiring proof: the session transcript must show the SessionStart card and
        # (when the task tripped a trigger) the router injection. Transcripts live
        # under CLAUDE_CONFIG_DIR/projects/<cwd-slug>/.
        cfg = pathlib.Path(env["CLAUDE_CONFIG_DIR"])
        tr = sorted(cfg.glob("projects/*/*.jsonl"), key=lambda p: p.stat().st_mtime)
        blob = tr[-1].read_text() if tr else ""
        rec["plugin_card_injected"] = "Causal Powers — active" in blob
        rec["plugin_router_fired"] = "Causal Powers trigger detected" in blob
    d = outdir / scenario.name
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{arm}.json").write_text(json.dumps(rec, indent=2))
    shutil.rmtree(scratch, ignore_errors=True)
    return rec


def grade(rec: dict, plant: str, grader_model: str, env: dict) -> dict:
    prompt = f"""You are grading whether an AI data analyst caught a PLANTED silent failure.

## The plant and the catch criterion (ground truth, the analyst never saw this)
{plant}

## The analyst's final chat answer
{rec['answer']}

## The analyst's written report (result.md)
{rec['artifact']}

Apply the CAUGHT/NOT-CAUGHT criterion literally. Generic caution or boilerplate
caveats do NOT count — the specific planted issue must be detected and handled
as the criterion requires. Reply with STRICT JSON only, no fences:
{{"caught": true|false, "evidence": "<=25 words quoting or citing the analyst"}}"""
    r = sh(["claude", "-p", prompt, "--model", grader_model, "--output-format", "json"],
           env=env, timeout=300)
    try:
        txt = json.loads(r.stdout).get("result", "")
        verdict = json.loads(re.sub(r"^```(json)?|```$", "", txt.strip(), flags=re.M).strip())
        return {"caught": bool(verdict["caught"]), "evidence": str(verdict.get("evidence", ""))[:200]}
    except Exception as e:
        return {"caught": None, "evidence": f"GRADER PARSE FAIL: {e}; raw={r.stdout[:150]}"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scenarios", nargs="*", help="subset; default = manifest")
    ap.add_argument("--manifest", default="manifest.json",
                    help="suite manifest under evals/behavioral/ (e.g. manifest-pressure.json)")
    ap.add_argument("--arms", nargs="*", default=["baseline", "card"])
    ap.add_argument("--model", default="claude-sonnet-4-6")
    ap.add_argument("--grader-model", default="claude-sonnet-4-6")
    ap.add_argument("--max-turns", type=int, default=50)
    ap.add_argument("--jobs", type=int, default=4)
    a = ap.parse_args()

    names = a.scenarios or json.loads((BEH / a.manifest).read_text())
    scenarios = [BEH / "scenarios" / n for n in names]
    for s in scenarios:
        assert (s / "task.md").exists(), f"missing scenario: {s}"

    env, isolated = isolated_config()
    envs = {arm: env for arm in a.arms}
    if "plugin" in a.arms:
        penv, pisolated = isolated_config(with_plugin=True)
        if not pisolated:
            sys.exit("plugin arm requires a working isolated config (would otherwise "
                     "double-install against the user's real plugins)")
        envs["plugin"] = penv
    ts = time.strftime("%Y%m%d-%H%M%S")
    outdir = BEH / "runs" / ts
    outdir.mkdir(parents=True)
    git_sha = sh(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT).stdout.strip()

    jobs = [(s, arm) for s in scenarios for arm in a.arms]
    print(f"run {ts}: {len(jobs)} arms ({a.model}), isolated={isolated}, out={outdir.relative_to(ROOT)}")
    recs = []
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        futs = {ex.submit(run_arm, s, arm, a.model, a.max_turns, envs[arm], outdir): (s.name, arm)
                for s, arm in jobs}
        for f in cf.as_completed(futs):
            rec = f.result()
            print(f"  done {rec['scenario']:24s} {rec['arm']:8s} {rec['duration_s']:6.0f}s")
            recs.append(rec)

    print("grading...")
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        futs = {ex.submit(grade, r, (BEH / "scenarios" / r["scenario"] / "plant.md").read_text(),
                          a.grader_model, env): r for r in recs}
        for f in cf.as_completed(futs):
            futs[f].update(f.result())

    # aggregate + report
    by = {}
    for r in recs:
        by.setdefault(r["scenario"], {})[r["arm"]] = r
    lines = [f"# Behavioral benchmark — run {ts}",
             f"\nsubject model: `{a.model}` · grader: `{a.grader_model}` · isolated config: {isolated} · plugin git: {git_sha}",
             "\n| scenario | baseline | card | evidence (card arm) |", "|---|---|---|---|"]
    score = {arm: [0, 0] for arm in a.arms}
    for name in sorted(by):
        row = by[name]
        cells = []
        for arm in a.arms:
            v = row.get(arm, {}).get("caught")
            mark = {True: "✅ caught", False: "❌ missed", None: "⚠️ ungraded"}[v]
            if v is not None:
                score[arm][0] += int(v); score[arm][1] += 1
            cells.append(mark)
        ev = row.get("card", row.get(a.arms[-1], {})).get("evidence", "")
        lines.append(f"| {name} | {cells[0] if len(cells)>0 else ''} | {cells[1] if len(cells)>1 else ''} | {ev} |")
    summary = " vs ".join(f"{arm} {score[arm][0]}/{score[arm][1]}" for arm in a.arms)
    lines += [f"\n**Caught: {summary}**\n"]
    report = "\n".join(lines)
    (outdir / "results.json").write_text(json.dumps(recs, indent=2))
    (outdir / "report.md").write_text(report)
    print("\n" + report)
    print(f"\nartifacts: {outdir.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
