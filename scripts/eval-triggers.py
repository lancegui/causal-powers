#!/usr/bin/env python3
"""Trigger CI for the causal-powers family.

Two layers, mirroring the two triggering mechanisms:

  Part A (default, free, <1s): pipes every query in evals/trigger/*.json through
  the REAL hooks/prompt-router (the artifact, not a re-implementation) and scores
  it. The router is a high-precision BACKSTOP: low recall on positives is
  expected and merely reported; firing the file's own skill on a
  should_trigger=false query is a precision violation and fails CI. Regressions
  are judged against the committed snapshot (evals/trigger/router-baseline.json):
  CI fails on NEW precision violations or on previously-hit positives that no
  longer fire — so editing a regex safely requires only `--update-baseline` plus
  a human glance at the diff.

  Part B (--live, costs API calls): approximates the primary mechanism —
  description matching — by asking a model, per query, which skill description
  (if any) it would invoke. With --competitors it also lists the superpowers
  skills that overlap this family's turf (brainstorming, systematic-debugging,
  writing-plans, verification-before-completion), which is exactly how the
  real session presents them; a positive query "lost" to a competitor is the
  under-generosity failure mode that motivated this CI (a build-a-leaflet-map
  ask triggering superpowers:brainstorming while question-framing stayed
  silent). Use --sample N per file to bound cost.

Usage:
  python3 scripts/eval-triggers.py                      # Part A, CI mode
  python3 scripts/eval-triggers.py --update-baseline    # bless current router state
  python3 scripts/eval-triggers.py --live --sample 5    # Part B smoke test
  python3 scripts/eval-triggers.py --live --competitors --skill question-framing
"""
import argparse, json, pathlib, re, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ROUTER = ROOT / "hooks" / "prompt-router"
EVALS = ROOT / "evals" / "trigger"
BASELINE = EVALS / "router-baseline.json"
SKILL_RE = re.compile(r"causal-powers:([a-z-]+)")

# Descriptions of the overlapping superpowers skills, as presented to a real
# session (source: obra/superpowers SKILL.md frontmatter). Only the ones that
# compete with this family's turf.
COMPETITORS = {
    "superpowers:brainstorming": "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.",
    "superpowers:systematic-debugging": "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes",
    "superpowers:writing-plans": "Use when you have a spec or requirements for a multi-step task, before touching code",
    "superpowers:verification-before-completion": "Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always",
}


def route(query: str) -> set[str]:
    """Feed one prompt through the real router; return the set of skills it named."""
    out = subprocess.run(
        [str(ROUTER)], input=json.dumps({"prompt": query}),
        capture_output=True, text=True, timeout=10,
    )
    return set(SKILL_RE.findall(out.stdout))


def load_evals(only_skill=None):
    cases = []  # (skill, query, should_trigger)
    for f in sorted(EVALS.glob("*.json")):
        if f.name == BASELINE.name:
            continue
        skill = f.stem
        if only_skill and skill != only_skill:
            continue
        for e in json.loads(f.read_text()):
            cases.append((skill, e["query"], bool(e["should_trigger"])))
    return cases


def part_a(cases, update_baseline: bool) -> int:
    per = {}
    for skill, query, should in cases:
        fired = route(query)
        s = per.setdefault(skill, {"hits": [], "misses": [], "violations": [], "neg_ok": 0})
        if should:
            (s["hits"] if skill in fired else s["misses"]).append(query)
        else:
            if skill in fired:
                s["violations"].append(query)
            else:
                s["neg_ok"] += 1

    print(f"{'skill':32s} {'recall':>12s} {'precision':>12s}")
    tot_h = tot_p = tot_v = tot_n = 0
    for skill, s in sorted(per.items()):
        h, m, v, n = len(s["hits"]), len(s["misses"]), len(s["violations"]), s["neg_ok"]
        tot_h += h; tot_p += h + m; tot_v += v; tot_n += v + n
        rec = f"{h}/{h+m}" if h + m else "—"
        prec = f"{n}/{v+n} ok" if v + n else "—"
        flag = "  <-- VIOLATIONS" if v else ""
        print(f"{skill:32s} {rec:>12s} {prec:>12s}{flag}")
    clean = tot_n - tot_v
    print(f"{'TOTAL (router = backstop)':32s} {f'{tot_h}/{tot_p}':>12s} {f'{clean}/{tot_n} ok':>12s}"
          f"   precision violations: {tot_v}")

    current = {
        sk: {"hits": sorted(s["hits"]), "violations": sorted(s["violations"])}
        for sk, s in per.items()
    }
    if update_baseline:
        BASELINE.write_text(json.dumps(current, indent=2) + "\n")
        print(f"\nbaseline written: {BASELINE.relative_to(ROOT)}")
        return 0
    if not BASELINE.exists():
        print("\nNo baseline yet — run with --update-baseline to bless this state.")
        return 1 if tot_v else 0

    frozen = json.loads(BASELINE.read_text())
    regressions = []
    for sk, s in current.items():
        base = frozen.get(sk, {"hits": [], "violations": []})
        for q in s["violations"]:
            if q not in base["violations"]:
                regressions.append(f"NEW PRECISION VIOLATION [{sk}]: {q[:100]}")
        for q in base["hits"]:
            if q in [c[1] for c in cases if c[0] == sk] and q not in s["hits"]:
                regressions.append(f"LOST RECALL HIT [{sk}]: {q[:100]}")
    if regressions:
        print("\nREGRESSIONS vs baseline:")
        for r in regressions:
            print("  " + r)
        return 1
    print("\nOK — no regressions vs baseline.")
    return 0


def skill_descriptions():
    descs = {}
    for f in sorted((ROOT / "skills").glob("*/SKILL.md")):
        fm = f.read_text().split("---", 2)[1]
        name = re.search(r"^name:\s*(\S+)", fm, re.M).group(1)
        # description may wrap; grab everything after 'description:' to end of block
        desc = fm.split("description:", 1)[1].strip()
        descs[f"causal-powers:{name}"] = desc
    return descs


def part_b(cases, model, sample, competitors) -> int:
    descs = skill_descriptions()
    if competitors:
        descs |= COMPETITORS
    menu = "\n\n".join(f"### {k}\n{v}" for k, v in descs.items())
    by_skill = {}
    for skill, q, should in cases:
        by_skill.setdefault(skill, []).append((q, should))
    wins = losses = viol = neg_ok = 0
    for skill, qs in sorted(by_skill.items()):
        for q, should in qs[: sample or len(qs)]:
            prompt = (
                "You are deciding which skill to invoke FIRST for a user message, "
                "based only on the skill descriptions.\n\n" + menu +
                f"\n\nUser message:\n{q}\n\n"
                "Reply with exactly one line: the single skill id you would invoke "
                "first (e.g. causal-powers:data-contracts), or NONE."
            )
            r = subprocess.run(
                ["claude", "-p", prompt, "--model", model],
                capture_output=True, text=True, timeout=120,
            )
            ans = r.stdout.strip().split("\n")[-1].strip()
            mine = f"causal-powers:{skill}" in ans
            if should:
                if mine:
                    wins += 1
                else:
                    losses += 1
                    print(f"  LOST [{skill}] -> {ans[:60]:60s} | {q[:70]}")
            else:
                if mine:
                    viol += 1
                    print(f"  FALSE-FIRE [{skill}] | {q[:70]}")
                else:
                    neg_ok += 1
    print(f"\n--live ({model}{', +competitors' if competitors else ''}): "
          f"positives won {wins}/{wins+losses}; negatives clean {neg_ok}/{neg_ok+viol}")
    return 1 if viol else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--update-baseline", action="store_true")
    ap.add_argument("--live", action="store_true", help="description-matching via claude -p (costs API calls)")
    ap.add_argument("--competitors", action="store_true", help="include overlapping superpowers descriptions in --live")
    ap.add_argument("--skill", help="restrict to one skill's eval file")
    ap.add_argument("--sample", type=int, help="cap queries per file in --live")
    ap.add_argument("--model", default="claude-haiku-4-5", help="--live model")
    a = ap.parse_args()
    cases = load_evals(a.skill)
    if not cases:
        sys.exit("no eval cases found")
    rc = part_a(cases, a.update_baseline)
    if a.live:
        rc = max(rc, part_b(cases, a.model, a.sample, a.competitors))
    sys.exit(rc)
