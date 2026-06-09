# Model-class cards — a template, not a catalog

These cards are **worked examples of one template**, not a menu to pick from. The
durable artifact is the template itself: for whatever structural model your
project develops, fill in the same five rows —

1. **Primitives** — what you estimate (the policy-invariant parameters).
2. **What reduced form can't recover** — why you're paying the structural price.
3. **Identification** — what moves *each* parameter, including the load-bearing
   untestable one and any required shifter/instrument.
4. **Estimation** — the algorithm, and whether analytical gradients are achievable.
5. **Canonical counterfactual(s)** — one per mechanism, equilibrium re-solved.

Characterize your model **adaptively, as it develops** — the right five rows
emerge from the modeling choices the project actually makes, not from matching to
a pre-set class. The cards below apply the template to several common classes so
you can see the pattern; they are illustrative, **not exhaustive**. Models not
listed — sorting/matching, bargaining, insurance/selection, trade, and whatever
your project invents — fit the same five rows. Read a card or two for the pattern,
then write your own.

---

## 1. Differentiated-products demand (logit → random-coefficients / BLP) + supply

**Primitives.** Utility parameters: mean tastes for characteristics, the *price
coefficient*, and the **distribution** of random coefficients (how tastes vary
across consumers). On the supply side: the marginal-cost function and the conduct
(usually Nash–Bertrand).

**What RF can't recover.** Own- and cross-price elasticities *off observed
prices*; the full substitution matrix; counterfactual prices after a merger or
entry; consumer surplus; marginal costs (backed out from pricing FOCs, never
observed directly).

**Identification.**
- *Mean tastes* — variation in product characteristics across products/markets.
- *Price coefficient* — price is endogenous (correlated with the unobserved
  quality ξ), so it needs **instruments**: cost shifters; BLP/Hausman
  instruments; and the **differentiation instruments** of Gandhi–Houde, which are
  what actually identify the *random coefficients* (they capture how crowded a
  product's characteristic-neighborhood is, i.e. local substitution).
- *Random-coefficient (heterogeneity) parameters* — identified by how market
  shares respond to the *configuration* of products on offer, and by micro-moments
  if you have individual data (e.g., demographics × choice). A single market
  can't identify them; you need variation in choice sets / consumer mix.
- *Load-bearing, untestable* — the distributional form of the random coefficients
  and of ξ; the conduct assumption (Nash–Bertrand vs. something else).

**Estimation.** GMM on the moment E[ξ·Z]=0. The mean utilities δ are recovered by
the **BLP contraction** (a nested fixed point, NFP) that inverts observed shares;
or impose share-matching as constraints and solve the whole thing as **MPEC**
(Dubé–Fox–Su) to avoid a loose-inner-loop bias. **Analytical gradient is
achievable and standard**: ∂s/∂δ and ∂s/∂θ₂ have closed forms, and the objective
is a sum over markets — derive and compute the gradient **market by market**.
Use Halton/MLHS draws for the share integral; report the number of draws.

**Canonical counterfactual.** Merger simulation: change ownership in the pricing
FOCs, hold costs and tastes fixed, **re-solve the Bertrand price equilibrium**,
report price and welfare changes. New-product / removed-product counterfactuals
follow the same re-solve.

**Tool.** `pyblp` — implements the analytical gradient, optimal instruments,
supply side, and MPEC/NFP. Hand-roll only outside its scope, and Monte-Carlo-verify.

---

## 2. Single-agent dynamic discrete choice (Rust / Hotz–Miller / CCP)

**Primitives.** Per-period payoff (utility/cost) parameters, the **discount
factor** (usually fixed, rarely identified), and the transition process of the
state. The agent solves a dynamic optimal-stopping / replacement / adoption
problem.

**What RF can't recover.** The trade-off between current and future payoffs —
e.g., how a forward-looking consumer values durability or future prices; the
response to a policy that changes the *future* (an anticipated tax, a
durable-goods price path). A static regression treats a dynamic choice as myopic.

**Identification.**
- *Flow payoff parameters* — identified by how choice probabilities vary with the
  state, given the continuation value. Need exclusion restrictions: a state
  variable that shifts the *dynamics* (e.g., mileage at replacement) but enters
  the flow payoff in a known way.
- *Discount factor* — typically **not identified** from choices alone (Magnac–
  Thesmar); usually fixed a priori. Identifying it needs an exclusion restriction
  that shifts continuation values but not the flow payoff.
- *Load-bearing, untestable* — the distribution of the choice-specific shocks
  (usually T1EV for tractable CCP) and the fixed discount factor.

**Estimation.** Full-solution nested fixed point (Rust): solve the Bellman
equation in the inner loop, MLE in the outer — heavy but efficient. Or **CCP /
two-step** (Hotz–Miller, Arcidiacono–Miller): estimate choice probabilities
first, invert to continuation values, then estimate payoffs — much faster, mild
efficiency loss. **Analytical gradients** of the likelihood are achievable
(score), and with T1EV shocks the CCP inversion is closed-form. Monte Carlo
recovery matters *especially* here: the discount factor and payoff scale are
easily confounded.

**Canonical counterfactual.** Change a state-transition or a payoff component (a
subsidy, a future price path), **re-solve the dynamic program**, simulate forward,
read the change in adoption/replacement and welfare.

---

## 3. Static and dynamic games (entry/exit, discrete games of interaction)

**Primitives.** Payoff parameters including the **strategic interaction** (how a
rival's presence shifts a firm's payoff), fixed/entry/sunk costs, and the
equilibrium concept (Nash; Markov-perfect for dynamics).

**What RF can't recover.** The competitive effect of an additional entrant
separately from market profitability; counterfactual market structure under a
policy that changes entry costs; the welfare of a merger that changes who competes.

**Identification.**
- *Competitive-effect and cost parameters* — identified by how the number/identity
  of active firms varies with market size and cost shifters. Need **excluded
  market-size / cost shifters** that move profitability without entering the
  strategic term directly.
- *The multiplicity problem* — multiple equilibria mean the model can be **set-,
  not point-, identified** (Tamer; Ciliberto–Tamer); state which equilibrium-
  selection assumption you make, because it's load-bearing and largely untestable.
- *Dynamics* — Bajari–Benkard–Levin / Pesendorfer–Schmidt-Dengler two-step
  estimators use first-stage CCPs to sidestep solving for equilibrium each
  iteration.

**Estimation.** Moment inequalities (set ID) or two-step CCP estimators; MLE only
when a selection rule point-identifies. Gradients depend on the estimator; for
the two-step moment versions the moment Jacobian is achievable. Monte Carlo
recovery must respect the equilibrium-selection assumption you imposed.

**Canonical counterfactual.** Change entry costs / market size / ownership,
**re-solve the entry game** (recompute the equilibrium set of active firms), and
read the change in market structure and welfare.

---

## 4. Auctions (first-price, common-value)

**Primitives.** The **distribution of bidders' private values** (or signals), the
number of bidders, and the auction format / equilibrium bidding strategy.

**What RF can't recover.** Bidder values are never observed — only bids. The
revenue/efficiency of a *different* auction format or reserve price requires the
value distribution, which only the equilibrium bid function recovers.

**Identification.**
- *Value distribution* — identified by inverting the equilibrium bid function:
  Guerre–Perrigne–Vuong (GPV) recover values nonparametrically from bids and the
  bid density, using the first-order condition of optimal bidding. Variation in
  the number of bidders helps separate private- from common-value.
- *Load-bearing, untestable* — the equilibrium assumption (bidders play the BNE of
  the assumed format) and private vs. common value (testable with N-variation in
  some settings — Haile–Hong–Shum).

**Estimation.** Two-step GPV (nonparametric bid density → values), or parametric
MLE/MSM on the value distribution. Gradients are estimator-specific. Monte Carlo
recovery: simulate bids from a known value distribution, confirm you recover it.

**Canonical counterfactual.** Change the reserve price or format, **re-solve the
equilibrium bidding strategy** under the recovered value distribution, and report
revenue/efficiency.

---

## 5. Limited consideration sets

**Primitives.** Preferences (as in any demand model) **and** the
consideration-formation process — the probability that each alternative enters the
choice set (full-set, default-specific, alternative-specific, or
cost-of-consideration formulations).

**What RF can't recover.** Whether a non-purchase is *low utility* or *never
considered*. These imply opposite interventions (price vs. advertising), and RF
bundles them.

**Identification.**
- **The red-line:** preferences and consideration are **not separately
  identified** without a **consideration shifter** — a variable that moves the
  *set* but not *utility* (advertising exposure, shelf/search-result position, a
  default, a reminder). This is the exclusion restriction; without it, STOP.
- Given a valid shifter, the consideration probabilities are identified by how
  choices respond to the shifter holding characteristics fixed; preferences by the
  usual characteristic variation. (Goeree; Abaluck–Adams; Barseghyan et al. for
  set-identification when the shifter is weak.)
- *Load-bearing, untestable* — the functional form of the consideration process.

**Estimation.** MLE / MSM on the choice probabilities, which now integrate over
consideration sets. Analytical gradients are often achievable but the set-integral
can be combinatorial — exploit structure (default-specific or independent
consideration keep it tractable). Monte Carlo recovery is essential: with a weak
shifter the consideration and preference parameters trade off (a near-flat
objective direction — exactly what the surface-mapping check catches).

**Canonical counterfactual.** Full-consideration world (everyone evaluates
everything), holding preferences fixed → the gap from observed behavior is the
welfare cost of limited awareness, and the target of an advertising policy.

---

## 6. Search

**Primitives.** Preferences **and** the **search-cost distribution** (and whether
search is sequential — Weitzman reservation values — or simultaneous /
fixed-sample).

**What RF can't recover.** Why equilibrium price dispersion exists — search
frictions vs. pure taste heterogeneity — and the surplus lost to frictions. RF
sees the dispersion but can't attribute it.

**Identification.**
- *Search-cost distribution* — identified from **observed search behavior**
  (clicks, pages viewed, sequence) if you have it; or from the *shape of price
  dispersion* under the search model if you don't (Hong–Shum; Moraga-González–
  Wildenbeest; De los Santos–Hortaçsu–Wildenbeest). Identification is much
  stronger with search data than with prices alone.
- *Sequential vs. simultaneous* — affects what the data implies; choose on
  institutional grounds and note it as an assumption.
- *Load-bearing, untestable* — the search protocol and the cost-distribution form.

**Estimation.** MSM/MLE matching search and purchase moments. Gradients are
estimator-specific; with reservation-value (Weitzman) structure, much is
closed-form. Monte Carlo recovery: simulate search+purchase from a known cost
distribution, confirm recovery — and confirm it *degrades gracefully* when you
have only prices, not search data (a direct read on how much your identification
leans on data you may not have).

**Canonical counterfactual.** Lower search costs (a price-comparison tool / search
subsidy), holding preferences fixed, **re-solve** search and pricing → the change
in price dispersion, search intensity, and consumer surplus attributable to the
friction.
