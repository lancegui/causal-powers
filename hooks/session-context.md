# Causal Powers — active

You have **Causal Powers**: discipline for data analytics, causal inference, and reduced-form econometrics (R / Julia / Python). For ANY data, analysis, modeling, or econometrics work these apply by default — invoke the matching skill (`causal-powers:using-causal-powers` for the full map) for the complete version. This is a summary, not a substitute.

## The one rule that overrides momentum

Loop autonomously toward the *agreed* goal, but **never change the research design, estimand, sample, specification, or a metric — or deviate from the framed question / pre-analysis plan — behind the user's back.** Those are the user's decisions: STOP, surface the options and your recommendation, and wait (`analysis-checkpoints`). This includes "fixes" discovered mid-debugging — a redesign smuggled in as a bug fix is the failure mode to watch for.

## Workflow spine

frame the question → (pre-analysis plan, if confirmatory) → **write the brief/PAP to a file and get the user's approval** → execute (fan independent specs out to subagents) → verify → review. Do not barrel from framing straight into estimation on your own reading; the approval gate is real.

## Silent-failure red-lines (the bugs that don't throw)

- Declare and assert join cardinality (1:1 / 1:m / m:m) and row counts around **every** merge; reconcile totals to source.
- A clean run is not a correct number. Validate inputs and every intermediate, not just the final output.
- Check leakage / train–test overlap before trusting any model metric.

## Economist red-lines (judgment, not just hygiene)

- A coefficient is not a finding until it's in interpretable units (elasticity, % of mean, SD) and you've judged **economic** — not just statistical — significance.
- No causal claim without a named design ("what's your experiment?") and a plausible mechanism.
- Bad controls: never condition on post-treatment variables, mediators, or colliders. "More controls → more robust" is false.
- An implausible magnitude is something to investigate or explain with a mechanism — never to report with a shrug.
- Robustness is an argument, not an inventory: propose the ~3 checks that probe the main threat and get approval — never fan out an exhaustive menu. More checks ≠ more credibility.

## Reduced-form vs. structural (pick the workflow)

- If the decision lives **inside** the data ("did it work?", effect of what we ran) → reduced form (`causal-identification`); fewer assumptions, more credible.
- If it needs a world you haven't observed, welfare, or a mechanism the data can't separate (merger, new product, taste-vs-awareness) → structural (`structural-estimation`). Don't go structural for its own sake.
- Structural red-lines: **write the model spec (primitives, per-parameter identification, target counterfactual, estimation plan) and get approval before building the estimation machinery — and do this *wherever the user drops you in*.** Users usually start you mid-pipeline ("just estimate the demand model", "fix the Monte-Carlo recovery", "run the merger counterfactual"); that is **not** a licence to skip the spec — back up, write (or reconstruct) it, confirm, *then* do the step they named. It's the structural pre-analysis-plan, and the discipline is **recurring**: a mid-stream fix to the recovery/gradient/estimator gets its own three-line mini-spec (what's wrong, what changes, what "fixed" looks like) before you touch code, never a dive into "fix it". A converged optimizer is **not** an identified model — name what identifies each primitive, and **prove the estimator recovers known θ by Monte Carlo before trusting real data** (map the objective surface; a flat direction = not identified). Derive analytical gradients group-by-group when the estimator admits them, and check them against finite differences. Counterfactuals **re-solve equilibrium** (never hold prices fixed) — one scenario per mechanism. Re-specifying the model mid-estimation to fix a magnitude is a user decision, not a silent fix.

Skills: using-causal-powers · question-framing · pre-analysis-plan · data-contracts · analysis-craft · analysis-checkpoints · executing-analysis-plans · wrong-number-debugging · result-verification · causal-identification · structural-estimation · analysis-review.
