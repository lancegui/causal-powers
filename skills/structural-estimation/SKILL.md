---
name: structural-estimation
description: Use whenever an analysis estimates the PRIMITIVES of an economic model — preferences/utility, costs, information/consideration, search, or conduct — or needs a COUNTERFACTUAL the data doesn't contain (a merger, a new product, a tax, a removed friction, welfare/surplus, equilibrium re-pricing). Fires for structural demand estimation (logit, random-coefficients/BLP), supply-side markup-and-cost recovery, dynamic discrete choice (Rust/CCP), entry and dynamic games, auctions, limited consideration sets, and search models — GMM/method of (simulated) moments, NLS, or maximum (simulated) likelihood. Use in R, Julia, or Python even when the user just says "estimate a demand model", "simulate the merger", "recover marginal costs", "what's the welfare effect", or "fit a structural model" — a converged optimizer is not an identified model, and a clean estimation run says nothing about whether the counterfactuals are right.
---

# Structural Estimation

## Overview

Reduced form measures a relationship that *held in the data*. Structural estimation recovers the **primitives** — preferences, costs, information, and conduct — that generated the data, so you can ask what happens in a world that hasn't occurred: a merger, a new product, a tax, a removed search friction, an entrant's consumer surplus. The failure mode mirrors reduced form's: there, confounding masquerades as an effect; here, a **misspecified model fits in-sample and lies confidently out-of-sample**, or a parameter the data can't identify still gets a number from the optimizer. A clean estimation run earns nothing on its own — the model can converge beautifully and be wrong about every counterfactual you built it to answer.

**Core principle:** structural estimation buys *policy-invariant primitives* at the price of assumptions the data cannot test. Earn that price — justify the model over reduced form, name what identifies each parameter, prove the algorithm recovers truth, and stress every counterfactual against the assumption it leans on hardest.

## Reduced form or structural? — choose the workflow before you model

This is the fork. These questions decide which of the three arms you're in:

- **Does the decision live inside the support of the data?** "What was the effect of the price cut we ran?" "Did the policy work?" → **reduced form** — a well-identified DiD/IV/RDD answers it and is *more* credible for leaning on fewer assumptions. Use `causal-identification`.
- **Does the decision require a world you haven't observed, a welfare number, or a mechanism the data can't separate?** "What price would the merged firm set?" "How much of low uptake is taste vs. not knowing the product exists?" "What's the consumer surplus from a new entrant?" → **structural** — the reduced-form relationship *shifts* when the policy changes (the Lucas critique), so there's no coefficient to extrapolate. Use this skill.
- **Is the goal a prediction to act on, not an effect at all?** ("which unit to flag/score/rank") → neither causal arm — use `predictive-modeling`. (Route by goal, not algorithm: ML used to *estimate an effect* still belongs to the causal arms.)

Don't go structural for its own sake — if a quasi-experiment answers the question, it wins.

**First question:** *what counterfactual do you need, and which primitive must be policy-invariant for it to be valid?* Name the **target world** — "post-merger prices", "welfare with the entrant gone", "uptake if search cost were zero" — not the finished scenario design; that's expensive and comes last, after the estimator is proven (see the pipeline). If you can't name the target counterfactual, you don't need a structural model yet.

## The discipline

```
WRITE THE MODEL CARD (primitives + equilibrium + per-parameter identification + estimand + plan)  →  GET APPROVAL  ‖ ← the gate, before any estimation machinery
  →  PROVE RECOVERY (Monte Carlo: converge back to known θ from a distant start, across the parameter space)
  →  GRADIENTS (AD or analytical derivation, group by group; check vs finite-difference)
  →  ESTIMATE  →  VALIDATE FIT (untargeted moments + held-out; reconcile vs a reduced-form elasticity)
  →  COUNTERFACTUALS (re-solve equilibrium; one scenario per mechanism)  →  DECOMPOSE & INTERPRET
```

Each arrow is a gate, not a suggestion. The first deliverable is the **model card** (next section) — the model and its per-parameter identification are written *into the card*, not as separate informal steps. Skipping "prove recovery" is how a coding bug or a non-identified parameter rides all the way into a published counterfactual.

## Primitives — what you are actually estimating

A **primitive** is a parameter *invariant to the policy you're studying* — that invariance is the entire license for the counterfactual. Across IO models: **preferences** (utility, including the *distribution* of random coefficients, switching/search costs); **technology/costs** (marginal, fixed/sunk, adjustment); **information & choice sets** (consideration, beliefs, frictions); **conduct/equilibrium** (Nash–Bertrand, Cournot, collusion, Markov-perfect, auction equilibrium, optimal stopping).

Lucas-critique test: a parameter is a primitive *only if it wouldn't change under your counterfactual*. A "price elasticity" is **not** one — it moves with the environment; the taste/cost parameters that *generate* it are. If your counterfactual would alter something you're treating as fixed, the model is the wrong tool.

## Mechanisms reduced form cannot recover

Name the specific mechanism your model buys you over reduced form, or you're carrying the cost without the benefit:

- **Separating non-preferred from non-considered from non-searched** — near-zero sales are consistent with low utility, an unconsidered option, or a stalled search, and the three imply **opposite** policies (price cut, advertising, removing the friction); only an explicit consideration/search stage with an identifying shifter can tell them apart.
- **Out-of-support substitution and welfare** — the full substitution matrix, counterfactual prices, and consumer surplus, not just an elasticity at observed prices.
- **Equilibrium responses** — firms re-optimize when the policy changes, so the reduced-form relationship *shifts* and there's nothing to extrapolate.
- **Decomposition** — turn one mechanism off at a time and read its contribution, which a reduced-form effect bundles into one number.

## Identification — name what moves each parameter

The discipline that separates a credible structural estimate from a curve-fit: for **every** parameter, name the feature of the data — the variation, or the moment — that identifies it, and argue why it moves *that* parameter and not another. "The model is identified because the optimizer converged" is not identification; a non-identified parameter converges too, to a value the data never pinned down.

- **Per parameter, what determines its movement.** Heterogeneity (random-coefficient) parameters need variation in choice sets/market composition that changes *who* faces *what* — not a single market. A mean price coefficient needs **cost-shifter variation that moves price for reasons unrelated to demand** — price is endogenous, so it needs instruments exactly as in IV. Dynamic parameters (e.g. a switching cost) are identified by how choices respond to state variation over time. Make this map explicit; the modern tool is the **sensitivity of estimates to moments** (Andrews–Gentzkow–Shapiro) — which moments, if perturbed, move which parameter.
- **The untestable core, stated.** Like every design, there is a load-bearing assumption no data tests — the distributional form of the unobservables, the conduct/equilibrium assumption, the exclusion of an instrument. Name it and argue it; the counterfactual rests on it.
- **The consideration/search non-identification red-line.** Preferences and consideration are **not separately identified** without an exclusion restriction — a *consideration (or search) shifter* that moves the set or the search process but **not** utility: advertising exposure, shelf or search-result position, a default option, the rollout of a price-comparison tool. Claiming to recover consideration or search costs without such a shifter is the structural analog of "an effect with no named design" — **STOP**.

## Write the model card — immediately, and keep it living

A structural model is the most expensive, least-reversible commitment in the family — days to weeks of coding, and the modeling choices (utility form, the random-coefficient distribution, conduct, what's a primitive vs. held fixed) silently decide what *every* downstream number means. So **write it down as a model card the moment you understand the model, even roughly** — the structure, and above all **what would move each parameter and what variation/instrument identifies it.** Write it *before* it's right — a parameter with nothing under "what moves it" is one you can't yet identify, and you want to see that on day one. (Write-to-file, sign-off-before-machinery, and mid-pipeline-reconstruct-and-confirm are `analysis-checkpoints`'s locked-document gate; this is structural's instance of it — sign-off is where "choosing the model is the user's decision" actually bites, before the compute is spent.)

The card states (its filled-in instance of the five rows in `references/model-classes.md`, plus the estimand on top):

- **Target counterfactual + the decision it informs** (the estimand) — and why reduced form can't answer it.
- **Primitives estimated, and what's held fixed/calibrated** — and why those are policy-invariant here.
- **Model** — utility/payoff, the equilibrium concept, the DGP mapping primitives → observables.
- **Identification, per parameter** — what moves each, the shifter/instrument it leans on, the load-bearing untestable assumption. *The heart of the card; a blank here is a parameter not yet identified.*
- **Estimation plan** — estimator (GMM/MoM, NLS, MSL…), moments/likelihood, instruments, and the Monte-Carlo-recovery design that validates it.
- **Counterfactual design** — one scenario per mechanism, primitives changed vs. held fixed. *This row starts as a sketch and is completed after estimation* — the gate needs the **target** counterfactual (row 1), not the finished scenario set; don't let designing scenarios block Monte-Carlo recovery or estimation.

The model card meets the same presentation standard as reduced-form designs (`causal-identification`): equations with every subscript defined, the economic intuition for each mechanism, and the literature precedent for the model class — no shorthand.

**The card is living** — refining as you learn is the point — but a **load-bearing change** (conduct, the random-coefficient distribution, primitive-vs-fixed, the estimand) still routes through `analysis-checkpoints`, never a quiet edit. Every fix beyond a trivial edit gets its own three-line mini-spec first — *what's wrong, what changes, what "fixed" looks like* (recovers θ from a distant start; gradient matches finite differences) — before you touch code. Trivial = a rename/typo/one-liner with no estimand/spec/sample/model decision; that you just do (`analysis-craft`).

## Prove the algorithm recovers truth — Monte Carlo, before real data

You estimate by *optimizing an objective* — GMM/MSM, NLS, or ML/MSL — and two things can be silently broken: the objective **as coded**, and whether the data **identifies** the parameters at all. Monte Carlo recovery catches both and is **not optional**: simulate from the model at a known θ★, then estimate starting from a θ₀ deliberately *far* from θ★, and confirm it converges *back* to θ★ — the distant cold start is what tests identification and the code together, not just whichever local min the optimizer landed near. **Shrink the SAMPLE (N, markets, draws) to keep this affordable, never θ's dimension** — recovering a smaller toy certifies nothing about the real estimator. *If you cannot recover parameters from data you generated yourself, you cannot believe estimates from real data* — full stop.

Do it **across the parameter space** (several true-θ draws, not one lucky region), **vary N** to confirm the estimator concentrates on truth as it grows (a consistency check), and **map the objective surface**: profile each parameter around the optimum — a **flat axis means that parameter is not identified**. Profiles only see axis flatness, so also check the **Hessian's (or GMM-Jacobian's) smallest eigenvalue** — near-zero flags non-identification along a *combination* of parameters (a ridge) that single-parameter profiles miss, and its eigenvector names the unidentified combination.

Run this *before* touching real data, and keep it as a regression test — this is `data-contracts` discipline applied to the estimator: assert recovery, then freeze it. Full recipe, pass criteria (MC-SE units, not %-of-θ★ — vacuous at θ★=0), and a language-agnostic recovery-harness skeleton: `references/estimation-and-gradients.md` §3.

## Gradients — derive them, don't default to numerical

The optimizer's speed and stability hinge on the gradient — a noisy finite-difference gradient forces loose tolerances, and a loose tolerance on a nested inner loop (e.g. a share-inversion contraction) **silently biases** the estimates (Dubé–Fox–Su).

- **AD is a co-equal first option** — ForwardDiff/Enzyme, JAX/PyTorch: exact, and composes with the implicit-function theorem for fixed-point inner loops. Verify once against finite differences, then trust it.
- **Otherwise derive the closed form group by group.** Most IO objectives have one even with no closed-form *solution* (the moment/residual Jacobian for GMM/NLS, the score for MLE/MSL) — structural objectives are almost always a sum over independent groups (markets, individuals, auctions).
- **Always check against finite differences** before trusting it — a sign error or dropped term doesn't throw, it just steers the optimizer somewhere wrong silently.
- **When neither is achievable**, use complex-step/central differences with a tight inner-loop tolerance, or prefer **MPEC** to remove the nested-tolerance problem entirely.

Recipe and the finite-difference check snippet: `references/estimation-and-gradients.md` §2.

## Validate fit — before you trust any counterfactual

Recovery proves the *algorithm* works, not that the *model fits reality* — a model that misfits in-sample will fabricate out-of-sample. Before any counterfactual:

- **Untargeted moments** — match features you didn't fit to (a held-out moment, second-choice patterns); matching only the target proves only that the optimizer ran.
- **Hold-out** — re-fit on a subset of markets/periods and check it predicts the rest.
- **Reconcile against a reduced-form fact** — the model-implied own-price elasticity at observed prices should sit near a credible reduced-form/IV estimate on the same data (`causal-identification`); a large gap means misspecification — listen before extrapolating.

## Counterfactuals — one scenario per mechanism, equilibrium re-solved

Counterfactuals are where misspecification does its damage, because here you leave the data.

- **Re-solve the equilibrium.** Under the counterfactual primitives, agents re-optimize — recompute the Nash equilibrium / fixed point / optimal policy. A "counterfactual" that holds prices (or any endogenous object) fixed while the policy moves them is just reduced form wearing a model's clothes.
- **One scenario per mechanism, model-agnostic.** Read off the mechanisms *your* model added beyond reduced form, and for each: change that primitive, hold the others fixed, re-solve, and read the difference. Every scenario must name the mechanism, state which primitive changes vs. is held fixed, report in **welfare / interpretable units**, and name the assumption it leans on hardest. `references/model-classes.md` has the canonical counterfactual for each common class (merger re-pricing, a re-solved dynamic program, a re-solved entry game, a re-solved auction, full-consideration, lower search costs) — use those as the pattern for *your* model's mechanisms, not as a fixed menu.
- **Bound it by its weakest assumption.** Re-run the counterfactual across a plausible range of the binding primitive (the conduct parameter, the discount factor, the consideration/search functional form, or θ drawn from its estimated distribution) and report the **envelope, not a single point**, when that assumption is shaky.

## Choosing or changing the model is the user's decision

Picking or changing the utility functional form, the random-coefficient distribution, the conduct assumption, or the consideration/search mechanism is `analysis-checkpoints` territory (its structural-model row) — surfaced as threat + candidate changes + your recommendation, never a quiet switch (Nash–Bertrand to collusion, an added random coefficient, a re-specified utility) smuggled in to make a magnitude behave.

## Tooling (R / Julia / Python)

| Task | R | Python | Julia |
|---|---|---|---|
| Random-coefficients demand (BLP) | `BLPestimatoR` | **`pyblp`** (gold standard — analytical gradients, optimal instruments, supply side, MPEC/NFP) | hand-rolled; `NPDemand.jl` |
| Plain/nested logit | `mlogit`, `gmnl` | `pylogit`, `xlogit` | `Logit` via `GLM`/custom |
| Dynamic discrete choice (Rust/CCP) | custom; `Rcpp` inner loop | custom; CCP two-step | custom (fast for the inner loop) |
| Entry / discrete games | custom | custom | custom |
| Auctions (structural) | custom | custom | custom |
| GMM / MSM engine | `gmm`, `momentfit` | `linearmodels`, `statsmodels`, custom | `GMM.jl`, custom |
| Optimizer w/ analytical gradient | `optim`, `nloptr` | `scipy.optimize` (pass `jac`), `pyblp` | `Optim.jl`, `JuMP`+`Ipopt` (MPEC) |
| Quasi-MC draws | `randtoolbox` (Halton) | `scipy.stats.qmc`, `pyblp` (MLHS) | `Sobol.jl`, `QuasiMonteCarlo.jl` |

`pyblp` (Conlon–Gortmaker) encodes the modern defaults — analytical gradients, optimal instruments, supply-side moments. Reach for it before hand-rolling BLP; hand-roll (and Monte-Carlo-verify) only outside its scope.

## Red flags — STOP

- Estimation machinery built, or a mid-work "fix" started, before the model card — primitives, per-parameter identification, the target counterfactual, estimation plan — was written or reconstructed and confirmed.
- A structural model built where a clean quasi-experiment would have answered the question.
- A counterfactual reported **without re-solving equilibrium** — prices or other endogenous objects held fixed while the policy moves.
- **No Monte Carlo recovery** — real-data estimates trusted before the algorithm was shown to recover known θ.
- A parameter reported with **no statement of what identifies it**, a flat objective direction ignored, or the gradient **never checked** against finite differences.
- A counterfactual magnitude reported with a shrug, not bounded by its weakest assumption.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "The estimation converged, so the model is identified." | A non-identified parameter converges too — to a number the data never pinned down. Map the objective surface. |
| "We don't need Monte Carlo — the code is simple." | Then recovery costs almost nothing and proves it. If you won't run it, you're not actually sure the algorithm works. |
| "It's just a mid-stream fix, let me dive in." | A "fix" to the recovery harness, gradient, or estimator changes what the numbers mean. Write the three-line spec first. |
| "Structural is more rigorous than reduced form." | It's more *assumption-laden*. Rigor is proving recovery and disciplining the model with a fact, not adding equations. |
| "We'll just hold prices fixed in the counterfactual." | Then it isn't a counterfactual — it's reduced form with extra steps. Re-solve the equilibrium. |

## The Process

1. **Get the model card written and approved** — primitives, per-parameter identification, the estimand (target counterfactual + decision), estimation plan. Mandatory before any machinery. The *scenario design* is sketched but **not** gated — finalize it at the counterfactual stage, after recovery and fit are proven.
2. **Card approved → invoke `executing-analysis-plans`** — fan the recovery reps, starting values, and per-mechanism counterfactual scenarios out to parallel subagents rather than one slow serial loop.
3. **Estimation + counterfactuals complete → offer `result-verification`** (the user's call) — confirm fit out-of-sample and that equilibrium was *re-solved*.
4. **A counterfactual comes out implausible → invoke `wrong-number-debugging` first** to rule out a data bug before blaming the model.
5. **The model misfits, a parameter won't identify, or an assumption needs changing → STOP and invoke `analysis-checkpoints`.** Never a silent re-spec to fix a magnitude.
