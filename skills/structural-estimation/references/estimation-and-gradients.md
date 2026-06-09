# Estimation algorithms, analytical gradients, and Monte Carlo recovery

The structural primitives are recovered by *optimizing an objective*. This file is
the algorithm side of `SKILL.md`: which estimator, when analytical gradients are
achievable and how to derive them group-by-group, the Monte-Carlo-recovery recipe
(with a language-agnostic skeleton), inference, and numerical reproducibility.

## Contents
1. The estimators
2. Analytical gradients — when they're achievable, and the group-by-group structure
3. Monte Carlo recovery — the recipe and a harness skeleton
4. Inference and standard errors
5. Numerical reproducibility

---

## 1. The estimators

| Estimator | Objective | Use when | Notes |
|---|---|---|---|
| **GMM / Method of Moments** | minimize `g(θ)'W g(θ)`, where `g` are sample moments (e.g. `E[ξ·Z]`) | you have moment conditions (instruments, micro-moments) | two-step or CUE for efficiency; the workhorse for BLP and games |
| **Method of Simulated Moments (MSM)** | same, but moments computed by simulation | the moments need an integral (heterogeneity, search) | simulation error enters the variance — see §4 |
| **NLS** | minimize `Σ (y − f(x;θ))²` | a conditional-mean structural relationship | gradient = Jacobian of residuals |
| **MLE** | maximize `Σ log L(θ)` | a full parametric likelihood | efficient if correctly specified |
| **MSL (Simulated ML)** | likelihood with simulated probabilities | the likelihood has an integral (mixed logit, dynamics) | simulation bias in logs — use enough draws / bias correction |
| **Nested Fixed Point (NFP)** | outer optimizer + inner equilibrium solve | the model has an inner fixed point (BLP contraction, Bellman) | inner-loop tolerance must be **tight** or the outer gradient is biased |
| **MPEC** | optimize subject to equilibrium as constraints | you want to avoid the nested inner loop | hand to a constrained solver (Ipopt); removes the tolerance bias |
| **CCP / two-step** | first-stage choice probs → second-stage payoffs | dynamics/games where solving each iteration is costly | Hotz–Miller, BBL, AM; fast, mild efficiency loss |

Choosing the estimator is part of choosing the model — a user-facing decision
(`analysis-checkpoints`), not a silent one.

---

## 2. Analytical gradients — when achievable, and the group-by-group structure

**Why bother.** The optimizer's speed and reliability hinge on the gradient. A
finite-difference gradient is `O(#params)` extra objective evaluations *and* noisy;
the noise forces a loose convergence tolerance; and on an NFP a loose **inner-loop**
tolerance biases the gradient through the chain rule (Dubé–Fox–Su). An analytical
gradient is faster, exact, and lets you tighten everything.

**Is a closed form achievable?** This is a property of the *objective*, and the
answer is "more often than people assume":
- GMM/NLS: the gradient is `2·G(θ)'W g(θ)` where `G = ∂g/∂θ` is the moment/residual
  Jacobian — closed-form whenever the moments are differentiable in θ.
- MLE/MSL: the gradient is the score `Σ ∂log L/∂θ` — closed-form for the standard
  shock distributions (T1EV gives clean logit-form scores).
- **Models with no closed-form *solution* can still have a closed-form
  *gradient*.** When an endogenous object `m(θ)` is defined implicitly by an
  equilibrium condition `H(m, θ) = 0` (a BLP contraction, a Bellman equation, a
  pricing FOC), the **implicit-function theorem** gives
  `∂m/∂θ = −(∂H/∂m)⁻¹ (∂H/∂θ)` — you differentiate the *condition*, never needing a
  closed-form solution. This is how BLP gets `∂δ/∂θ₂` analytically.

**The group-by-group structure (this is the practical key).** Structural objectives
are almost always a **sum over independent groups** — markets, individuals,
auctions, time-paths:
```
objective(θ) = Σ_g  f_g(θ)        ⇒        ∇objective(θ) = Σ_g  ∇f_g(θ)
```
So you **derive and compute the gradient one group at a time**, then sum. Concretely:
- Derive `∇f_g` once, by hand, for a single representative group (one market's share
  Jacobian, one individual's score, one auction's bid-FOC derivative).
- Compute it per group in a loop / vectorized / **parallelized across groups** —
  the blocks are independent, so this maps cleanly onto the fan-out in
  `executing-analysis-plans`.
- For BLP specifically: `∂s/∂δ` and `∂s/∂θ₂` are closed-form per market; the inner
  contraction's `∂δ/∂θ₂` comes from the IFT above; assemble market by market.

**Always check against finite differences.** A dropped term or sign error in the
gradient does **not** throw — it silently steers the optimizer to the wrong point.
At 2–3 random θ, compare the analytical gradient to a central-difference (or
complex-step, which is exact to machine precision) gradient; they should agree to
many digits. This check is minutes of work and catches the single most common
silent structural bug.

```python
# gradient check (works for any objective; complex-step = exact)
import numpy as np
def grad_check(obj, obj_complex, theta, h=1e-6):
    g_analytic = analytic_grad(theta)
    g_fd = np.array([(obj(theta + h*e) - obj(theta - h*e))/(2*h)
                     for e in np.eye(len(theta))])
    # complex-step if obj supports complex input: Im(obj(theta + i*h*e))/h
    return np.max(np.abs(g_analytic - g_fd))   # want ~1e-7 or smaller (fd), ~machine eps (complex-step)
```

**When a closed form genuinely isn't achievable:** use complex-step or central
differences, keep the inner-loop tolerance tight, and prefer **MPEC** so there's no
nested loop whose tolerance can poison the gradient.

---

## 3. Monte Carlo recovery — the recipe and a harness skeleton

The point: **prove the estimator, as coded, recovers known parameters before you
trust it on real data.** It catches coding bugs in the objective/gradient *and*
non-identification (a flat objective). Run it first; keep it as a regression test.

**Recipe.**
1. Fix a true θ★ and simulate a dataset *from the model* at θ★. Keep each fit
   cheap — **shrink the parameter space and the sample size** so the slow
   structural estimator runs fast enough to repeat many times. Then estimate
   **from a θ₀ deliberately far from θ★** and confirm convergence *back* to θ★ —
   the distant cold start is what tests identification and the optimizer, not just
   the code.
2. Estimate θ̂ from the simulated data, from several **starting values** (the
   objective is non-convex; one start finds *a* local min, not *the* min).
3. Repeat over **many simulation seeds** → a sampling distribution of θ̂. Check it
   centers on θ★ (bias ≈ 0) and that coverage of the SEs is right.
4. Repeat the whole thing at **several θ★ across the parameter space** — don't
   certify recovery only in a lucky region.
5. **Vary N** (e.g. small → medium → large) and confirm the estimator concentrates
   on θ★ as N grows (consistency). If it doesn't tighten, suspect non-ID or a bug.
6. **Map the objective surface**: profile each parameter around θ★ holding the
   others at θ★. A **flat axis ⇒ that parameter is not identified** — the optimizer
   returns a number, but it's meaningless. Profiles see only axis flatness;
   flatness along a *combination* of parameters (a ridge) needs the **Hessian /
   GMM-Jacobian rank** — its smallest eigenvalue, and the eigenvector that names
   the unidentified combination. Weak ID shows up as a shallow valley and large
   cross-seed variance.

**Pass criteria** (assert these — `data-contracts` for the estimator):
- θ̂ converges back to θ★ from distant starts, within sampling error, at each θ★.
- θ̂ variance shrinks as N grows.
- No parameter has a flat profile at θ★.
- Analytical and finite-difference gradients agree.

**Language-agnostic skeleton** (Python; the shape is the same in R/Julia):
```python
def monte_carlo_recovery(true_thetas, sample_sizes, n_seeds, starts):
    results = []
    for theta_star in true_thetas:              # 4: across the parameter space
        for N in sample_sizes:                  # 5: consistency in N
            ests = []
            for seed in range(n_seeds):         # 3: sampling distribution
                data = simulate_from_model(theta_star, N, seed)   # 1
                cands = [estimate(data, start) for start in starts]  # 2: multistart
                theta_hat = min(cands, key=lambda c: c.objective).theta
                ests.append(theta_hat)
            results.append(summarize(theta_star, N, ests))  # bias, sd, coverage
    return results

# 6: identification surface — profile each parameter around the truth
def profile(theta_star, data, k, grid):
    out = []
    for v in grid:
        theta = theta_star.copy(); theta[k] = v
        out.append((v, objective(theta, data)))   # flat in v ⇒ param k not identified
    return out
```

The same harness doubles as the recovery regression test: freeze a `(θ★, seed) →
θ̂` baseline and re-run it whenever the estimation code changes.

---

## 4. Inference and standard errors

- **GMM:** two-step (or CUE) with the efficient weight matrix; sandwich SEs from
  `G'WG`. Report the J-test of overidentifying restrictions — but read it as a
  specification signal, not a ritual.
- **Simulation error (MSM/MSL):** simulated moments/likelihoods add variance and,
  for MSL, a *log* bias that shrinks with draws — use enough draws, quasi-MC
  (below), and report the count; the variance formula has an `(1 + 1/S)`-type
  inflation.
- **Two-step estimators (CCP, GPV):** the first stage's estimation error must flow
  into the second-stage SEs — correct analytically or **bootstrap** the whole
  two-step procedure.
- **Clustering:** cluster at the level of the sampling/equilibrium unit (market,
  auction), and worry about too-few clusters as in any panel.
- When analytical variances are messy (set ID, nested estimators), **bootstrap or
  subsample** — and Monte-Carlo-check that the SEs have correct coverage.

---

## 5. Numerical reproducibility

- **Quasi-Monte-Carlo draws** for simulation integrals — Halton or MLHS (modified
  Latin hypercube) beat pseudo-random for the same draw count; report which and how
  many. `pyblp` defaults to good choices; replicate them if hand-rolling.
- **Fix all seeds** for simulation draws and store them with the results.
- **Tolerances:** the inner-loop (contraction/Bellman) tolerance must be *tighter*
  than the outer optimizer's, or the outer gradient inherits the inner slop. State
  both. MPEC sidesteps this.
- **Multiple starting values** on the non-convex objective; report the spread of
  optima reached, not just the best.
- Record the optimizer, tolerances, draw count, and seeds alongside the estimates —
  a structural estimate that can't be reproduced from a clean session is not done
  (`result-verification`).
