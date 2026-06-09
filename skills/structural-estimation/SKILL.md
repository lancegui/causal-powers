---
name: structural-estimation
description: Use whenever an analysis estimates the PRIMITIVES of an economic model rather than a reduced-form relationship — preferences/utility, costs, information/consideration, search, or conduct — or whenever the question requires a COUNTERFACTUAL the data doesn't contain (a merger, a new product, a tax, a removed friction, consumer welfare/surplus, equilibrium re-pricing). Fires for structural demand estimation (logit, random-coefficients/BLP), supply-side markup-and-cost recovery, dynamic discrete choice (Rust/CCP), entry and dynamic games, auctions, limited consideration sets, and search models — estimated by GMM/method of (simulated) moments, NLS, or maximum (simulated) likelihood. Forces the structural workflow — justify going structural over reduced form, name what identifies each parameter, PROVE the algorithm recovers known parameters via Monte Carlo before trusting real data, derive analytical gradients group-by-group when the estimator admits them, re-solve equilibrium for counterfactuals with one scenario per mechanism. Use in R, Julia, or Python even when the user just says "estimate a demand model", "simulate the merger", "recover marginal costs", "what's the welfare effect", or "fit a structural model" — a converged optimizer is not an identified model, and a clean estimation run says nothing about whether the counterfactuals are right.
---

# Structural Estimation

## Overview

Reduced form measures a relationship that *held in the data*. Structural estimation recovers the **primitives** — the preferences, costs, information, and conduct that generated the data — so you can ask what happens in a world that has *not* occurred: a merger, a new product, a tax, a removed search friction, the consumer surplus from an entrant. The trade is steep, and the failure mode is the mirror image of reduced form's. In reduced form, confounding masquerades as an effect. In structural work, a **misspecified model fits in-sample and lies confidently out-of-sample**, or a parameter the data cannot identify still gets a number from the optimizer. A clean estimation run earns you nothing on its own: the model can be internally consistent, converge beautifully, and be wrong about every counterfactual you built it to answer.

**Core principle:** structural estimation buys *policy-invariant primitives* at the price of assumptions the data cannot test. Earn that price — justify the model over reduced form, name what identifies each parameter, prove the algorithm recovers truth, and stress every counterfactual against the assumption it leans on hardest.

## Reduced form or structural? — choose the workflow before you model

This is the fork. Two questions decide which family you're in, and they lead to two different workflows:

- **Does the decision live inside the support of the data?** "What was the effect of the price cut we ran?" "Did the policy work?" → **reduced form.** A well-identified DiD / IV / RDD answers it and is *more* credible precisely because it leans on fewer assumptions. Use the reduced-form workflow → **`causal-identification`**.
- **Does the decision require a world you haven't observed, a welfare number, or a mechanism the data can't separate?** "What price would the merged firm set?" "How much of low uptake is taste vs. not knowing the product exists?" "What's the consumer surplus from a new entrant?" → **structural.** The relationship you'd estimate in reduced form *shifts* when the policy changes (the Lucas critique), so there is no reduced-form coefficient to extrapolate. Use this skill's workflow.

Don't go structural for its own sake. If a quasi-experiment answers the question, it wins. Go structural only when the question genuinely lives *outside* the data.

**First question** (the analog of "what's your experiment?"): *what counterfactual do you need, and which primitive must be policy-invariant for that counterfactual to be valid?* If you can't name the counterfactual, you don't need a structural model yet.

## The discipline

```
WRITE THE MODEL (primitives + equilibrium)  →  ARGUE IDENTIFICATION (per parameter: what moves it)
  →  WRITE THE SPEC & GET APPROVAL  ‖ ← the gate, before any estimation machinery is built
  →  PROVE RECOVERY (Monte Carlo: converge back to known θ from a distant start, across the parameter space)
  →  GRADIENTS (derive analytically when the estimator admits them, group by group; check vs finite-difference)
  →  ESTIMATE  →  VALIDATE FIT (in- and out-of-sample)
  →  COUNTERFACTUALS (re-solve equilibrium; one scenario per mechanism)  →  DECOMPOSE & INTERPRET
```

Each arrow is a gate, not a suggestion. Skipping "prove recovery" is how a coding bug or a non-identified parameter rides all the way into a published counterfactual.

## Primitives — what you are actually estimating

A **primitive** is a parameter of the economic environment that is *invariant to the policy you want to study* — that invariance is the entire license for the counterfactual. Across IO models the primitives are some subset of:

- **Preferences** — utility parameters, including the *distribution* of heterogeneous tastes (random coefficients), price sensitivity, and switching/search costs as they enter utility.
- **Technology / costs** — marginal cost functions; fixed and sunk costs (entry); adjustment costs (dynamics).
- **Information & choice sets** — what agents know and which alternatives they actually evaluate: consideration sets, beliefs, information frictions.
- **Conduct / equilibrium concept** — how agents interact: Nash–Bertrand pricing, Cournot, collusion, Markov-perfect dynamics, auction equilibrium, single-agent optimal stopping.

The Lucas-critique test: a parameter is a primitive *only if it would not change under your counterfactual*. A "price elasticity" is **not** a primitive — it moves with the environment; the taste and cost parameters that *generate* it are. If your counterfactual would alter something you're treating as fixed, the model is the wrong tool for that counterfactual.

## Mechanisms reduced form cannot recover

This is *why* you pay the structural price. Name the specific mechanism your model buys you over reduced form, or you are carrying the cost without the benefit.

- **Separating non-preferred from non-considered from non-searched.** A product with near-zero sales is equally consistent with low utility, *not being in the consideration set*, or a search cost that stopped the consumer before they found it. The three are observationally identical in reduced form and imply **opposite** policies — cut the price, advertise to expand awareness, or remove the search friction. Only a model with an explicit consideration/search stage — and a *shifter* that moves it (see identification) — can decompose them.
- **Out-of-support substitution and welfare.** Reduced form gives an elasticity *at observed prices*; a demand system gives the whole substitution matrix, counterfactual prices, and consumer surplus / compensating variation — numbers reduced form simply does not contain.
- **Equilibrium responses.** When the policy changes, firms re-optimize: merger price effects, entry/exit, re-pricing. The reduced-form relationship *shifts*, which is exactly why you can't extrapolate it.
- **Decomposition of a reduced-form effect into channels.** A structural model lets you turn one mechanism off at a time and read how much each contributes — which the reduced-form effect bundles into a single number.

## Identification — name what moves each parameter

The discipline that separates a credible structural estimate from a curve-fit: for **every** parameter, name the feature of the data — the variation, or the moment — that identifies it, and argue why it moves *that* parameter and not another. "The model is identified because the optimizer converged" is not identification; a non-identified parameter converges too, to a value the data never pinned down.

- **Per parameter, what determines its movement.** Heterogeneity (random-coefficient) parameters are identified by variation in choice sets / market composition that changes *who* faces *what* — not by a single market. A mean price coefficient is identified by **cost-shifter variation that moves price for reasons unrelated to demand** — price is endogenous, so you need instruments here exactly as in IV. Dynamic parameters (e.g., a switching cost) are identified by how choices respond to state variation over time. Make this map explicit; the modern tool is the **sensitivity of estimates to moments** (Andrews–Gentzkow–Shapiro) — which moments, if perturbed, move which parameter.
- **The untestable core, stated.** Like every design, there is a load-bearing assumption no data tests — the distributional form of the unobservables, the conduct/equilibrium assumption, the exclusion of an instrument. Name it and argue it; the counterfactual rests on it.
- **The consideration/search non-identification red-line.** Preferences and consideration are **not separately identified** without an exclusion restriction — a *consideration (or search) shifter* that moves the set or the search process but **not** utility: advertising exposure, shelf or search-result position, a default option, the rollout of a price-comparison tool. This is the structural analog of an instrument. Claiming to recover consideration or search costs without such a shifter is the structural version of "an effect with no named design" — **STOP**.

## Write the model spec and get approval — before you estimate

A structural model is the most expensive and least reversible commitment in the whole family: coding the data-generating process, deriving gradients, building the estimation machinery, and running it is days to weeks, and the modeling choices — utility/payoff form, the random-coefficient distribution, the conduct/equilibrium concept, what counts as a primitive versus what's held fixed — silently decide what *every* number downstream means. So a structural project gets the same treatment a confirmatory study gets from `pre-analysis-plan`: **write the model spec to a file and get the user's sign-off before any estimation machinery is built.** This is the gate where "choosing the model is the user's decision" actually bites — *before* the compute is spent, not after a result comes out wrong.

The spec is short and states:

- **The target counterfactual(s) and the decision they inform** — the estimand — and one line on why reduced form can't answer it.
- **The primitives to be estimated, and what's held fixed or externally calibrated** (and why those are policy-invariant for this counterfactual).
- **The model** — utility/payoff, the equilibrium concept, and the DGP mapping primitives → observables.
- **The identification argument, per parameter** — what moves each one, the shifters/instruments it leans on, and the load-bearing untestable assumption.
- **The estimation plan** — estimator (GMM/MoM, NLS, MSL…), the moments or likelihood, the instruments, and the Monte-Carlo-recovery design that will validate it.
- **The counterfactual design** — one scenario per mechanism, primitives changed vs. held fixed.

Get approval, *then* build and estimate. Everything below this line (recovery, gradients, estimation, counterfactuals) is executing an approved plan — and any change to the approved spec once you're underway routes back through `analysis-checkpoints`, not a silent edit.

## Prove the algorithm recovers truth — Monte Carlo, before real data

You estimate by *optimizing an objective* — GMM / method of (simulated) moments, NLS, maximum (simulated) likelihood. Two things can be silently broken: the objective **as you coded it**, and whether the data **identifies** the parameters at all. Monte Carlo recovery catches both, and it is **not optional**:

1. **Simulate from the model at a known θ★, then estimate starting from a θ₀ deliberately *far* from θ★, and confirm it converges *back* to θ★.** The distant cold start is the real test: it checks that the objective is coded right, that the parameters are identified, and that the optimizer finds the truth rather than a comfortable local min next to where it started. To keep this loop affordable — structural estimators are slow — **shrink the parameter space and the sample size** so each fit is cheap and you can run many starts and many reps. *If you cannot recover parameters from data you generated yourself, you cannot believe estimates from real data* — full stop.
2. **Do it across the parameter space**, not at one point — several true-θ draws — so you don't certify recovery only in a lucky region.
3. **Vary the sample size** and watch the estimator concentrate on truth (a consistency check). If it doesn't tighten as N grows, suspect non-identification or a coding bug.
4. **Map the objective surface** around the optimum — profile each parameter one at a time; a **flat axis means that parameter is not identified** (the optimizer still returns a number, but it's meaningless). Single-parameter profiles catch only *axis* flatness, though — non-identification along a *combination* of parameters (a ridge) is invisible to them and shows up instead as a near-singular Hessian (or GMM Jacobian), whose smallest-eigenvalue direction names the unidentified combination. Weak identification shows up as a near-flat valley and enormous variance across MC repetitions.

Run this *before* touching real data, and keep it as a regression test — this is `data-contracts` discipline applied to the estimator: assert recovery, then freeze it. The recipe and a language-agnostic harness skeleton are in `references/estimation-and-gradients.md`.

## Analytical gradients — when the estimator admits them, derive them group by group

The estimator is an optimizer, and its speed and stability hinge on the gradient. A numerical (finite-difference) gradient is slow and noisy; a noisy gradient forces loose convergence tolerances, and loose tolerances on a nested inner loop (e.g., a share-inversion contraction) **silently bias** the gradient and the estimates (Dubé–Fox–Su). So:

- **First assess whether a closed-form gradient/Jacobian is achievable** for *your* objective — this is a property of the estimation algorithm, not the model. For GMM/NLS it's the Jacobian of the moments/residuals w.r.t. parameters; for MSL it's the score. Many IO objectives have closed-form derivatives even when the model itself has **no** closed-form solution — the implicit-function theorem gets you ∂(endogenous object)/∂θ.
- **Exploit the group/block structure.** The objective is almost always a sum over independent units — markets, individuals, auctions. So the gradient is a sum of per-group blocks you can derive, compute, and parallelize **group by group**. That block structure is what makes the derivation tractable and the code fast.
- **Always check the analytical gradient against finite differences** at a few parameter points before trusting it. A sign error or a dropped term does not throw — it just steers the optimizer somewhere wrong and converges there. The check is cheap; skipping it is how an entire estimation goes quietly bad.
- **When a closed form genuinely isn't achievable**, say so, use a high-quality numerical derivative (complex-step or central differences), keep the inner-loop tolerance *tight*, and prefer a constrained formulation (**MPEC**) that removes the nested-tolerance problem entirely.

## Counterfactuals — one scenario per mechanism, equilibrium re-solved

Counterfactuals are where misspecification does its damage, because here you leave the data. Three rules:

- **Re-solve the equilibrium.** Under the counterfactual primitives, agents re-optimize — recompute the Nash equilibrium / fixed point / optimal policy. A "counterfactual" that holds prices (or any endogenous object) fixed while the policy moves them is just reduced form wearing a model's clothes.
- **Design exactly one scenario per mechanism — whatever your model's mechanisms are.** This rule is model-agnostic: read off the mechanisms *your* model added beyond reduced form, and for each one build the counterfactual that *isolates* it — change that primitive, hold the others fixed, re-solve, read the difference. The mechanisms come from the model the project actually developed, not from a fixed list. Each scenario must: name the mechanism, state which primitive changes and which are held fixed, re-solve equilibrium, report the result in **welfare / interpretable units**, and name the assumption it leans on hardest.

  A single clean scenario is often a single primitive knocked to a limit — e.g. *set the search cost to zero and read what happens to the purchase rate and to consumer surplus*; that one number is the search friction's bite, isolated. If a model layers **preference + consideration + search**, the three scenarios are the obvious set — turn off limited consideration (impose full awareness) to size the cost of not-knowing; zero out search cost to size the friction; perturb a characteristic to read taste and substitution — each holding the others fixed. But that trio is an *illustration of the rule*, not the rule: a dynamic-adoption model's mechanisms might be the discount/forward-looking channel vs. a state-transition channel; an entry model's might be the competitive-effect channel vs. the fixed-cost channel. Same discipline, different knobs.
- **Bound the counterfactual by its weakest assumption** and report sensitivity. The number is only as good as the least-tested primitive feeding it — so report a range, not a point, when the binding assumption is shaky.

## Choosing or changing the model is the user's decision

Picking the utility functional form, the distribution of random coefficients, the conduct assumption, the consideration/search mechanism — and **changing any of them once estimation is underway** — decides what is even being estimated and what the counterfactuals mean. These are the user's calls, not yours to make silently. When a model fits badly, a parameter won't identify, or a counterfactual comes out implausible, the move is **not** to quietly switch Nash–Bertrand to collusion, add a random coefficient, or re-specify utility until it behaves. Surface the threat, the candidate model changes, and your recommendation as a checkpoint (`analysis-checkpoints`) — it's a deviation from the approved spec, not a silent edit. A re-specification smuggled in to fix a magnitude is the structural twin of the redesign-as-bug-fix failure mode the whole family watches for.

## Breadth — characterize *your* model, don't pick from a menu

The pipeline above is model-agnostic, and so is the way you should approach a new model: as the project develops its specific structural model, **fill in the same five rows for it** — *primitives / what reduced form can't recover / what identifies each parameter / estimation algorithm (and whether analytical gradients are achievable) / the canonical counterfactual per mechanism*. That template is the durable artifact; the model classes are just worked examples to learn the pattern from, not a catalog to choose from.

`references/model-classes.md` works those five rows for several common classes — differentiated-products demand (logit → random-coefficients/BLP) + supply, single-agent dynamic discrete choice, static/dynamic games, auctions, limited consideration, and search — precisely so you can *see the template applied* and then apply it to whatever your project builds, including classes not listed (sorting/matching, bargaining, insurance/selection, trade). Read a card or two for the pattern, then characterize your own model the same way. See **`references/estimation-and-gradients.md`** for the estimator / gradient / Monte-Carlo recipes and a recovery-harness skeleton.

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

`pyblp` (Conlon–Gortmaker, *Best Practices for Differentiated Products Demand Estimation*) encodes the modern defaults — analytical gradients, optimal instruments, tight tolerances, supply-side moments. Reach for it before hand-rolling BLP; hand-roll (and Monte-Carlo-verify) when the model is outside what a package covers.

## Red flags — STOP

- Estimation machinery built and compute spent before the model spec — primitives, per-parameter identification, the target counterfactual, the estimation plan — was written down and approved.
- A structural model built where a clean quasi-experiment would have answered the question.
- A counterfactual reported **without re-solving equilibrium** — prices or other endogenous objects held fixed while the policy moves them.
- **No Monte Carlo recovery** — estimates from real data trusted before the algorithm was shown to recover known θ.
- A parameter reported with **no statement of what identifies it**; a flat objective direction noticed and ignored.
- The analytical gradient **never checked** against finite differences; or a loose inner-loop tolerance feeding the gradient.
- Consideration or search costs "recovered" with **no consideration/search shifter** (no exclusion restriction).
- Conduct or a distributional form *assumed*, never flagged as load-bearing and untestable.
- The model **re-specified mid-estimation** to fix a magnitude, without surfacing it as the user's decision.
- A counterfactual magnitude reported with a shrug instead of bounded by its weakest assumption.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "The estimation converged, so the model is identified." | A non-identified parameter converges too — to a number the data didn't pin down. Map the objective surface. |
| "Numerical gradients are fine." | Until a loose tolerance biases them and the optimizer stops at the wrong point. Derive the gradient, or at least check it against finite differences. |
| "We don't need Monte Carlo — the code is simple." | Then recovery costs almost nothing and proves it. If you won't run it, you're not actually sure the algorithm works. |
| "Structural is more rigorous than reduced form." | It's more *assumption-laden*. Rigor is proving recovery and disciplining the model with a fact, not adding equations. |
| "We'll just hold prices fixed in the counterfactual." | Then it isn't a counterfactual — it's reduced form with extra steps. Re-solve the equilibrium. |
| "More model detail = more realism." | More primitives you can't identify = more ways to be confidently wrong. Add only what a shifter or a moment identifies. |
| "The optimizer found the global min." | On a non-convex objective, from one start, it found *a* min. Use multiple starts and good instruments. |

## Relationship to sibling skills

- Decide reduced-form vs. structural at the top with **`using-causal-powers`**; if the question lives inside the data, you want **`causal-identification`**, not this.
- Frame the counterfactual and the decision it informs with **`question-framing`** before building anything.
- The model spec *is* the structural **`pre-analysis-plan`** — write it to a file and get approval before estimation; it locks the model, identification, estimand, and estimation plan the way a PAP locks a confirmatory design.
- The price-endogeneity instrument and the consideration/search shifter are IV arguments — **`causal-identification`** on exclusion/relevance applies directly.
- The data feeding the model still needs **`data-contracts`**; the Monte-Carlo recovery harness *is* `data-contracts` discipline applied to the estimator (assert recovery, freeze it as a regression test).
- A counterfactual that comes out implausible is often the *model*, not a data bug — but rule out the data bug with **`wrong-number-debugging`** first.
- Any change to the model once estimation is underway is a user decision — route it through **`analysis-checkpoints`**.
- Once the spec is approved, **`executing-analysis-plans`** carries it out — the recovery reps, starting values, and per-mechanism counterfactual scenarios fan out to parallel subagents.
- Before reporting, validate fit out-of-sample as part of **`result-verification`**; have the estimates reviewed for the structural silent failures (non-identification, no recovery test, prices held fixed) with **`analysis-review`**.

## The bottom line

```
Structural claim  →  counterfactual named, primitives policy-invariant, each parameter's identification stated,
                     algorithm proven to recover truth (Monte Carlo), gradients derived/checked,
                     equilibrium re-solved per mechanism
Otherwise         →  a simulation with confident output and untested assumptions
```
