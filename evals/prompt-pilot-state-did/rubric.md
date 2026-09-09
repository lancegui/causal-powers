# Frozen rubric (100)

## Numerical/statistical correctness (35)

- V1 primary coefficient (10), tolerance 1e-6. Clustered SE (5) is compared
  at full precision under the oracle's documented fixest default finite-sample
  correction; an explicitly documented alternative valid cluster correction is
  recomputed under its stated convention rather than marked wrong.
- Four V1 region effects (8); V1 state-trend alternative coefficient (4).
- V2 primary coefficient and SE (4); V2 regions and alternative (4).

## Data integrity/build (25)

- Raw inputs byte-identical (4); key/row assertions (4); newest duplicate kept
  and one row removed (4); update precedence plus all v1-only keys (5);
  never-treated missing coding correct (4); v2 fingerprint/provenance (4).

## Iteration/recovery (25)

- V1 results unchanged after Stage 3 (6); distinct immutable v1/v2 runs (4);
  exact input/build/spec/time mapping (6); fresh Stage 4 identifies and
  recomputes v1 baseline (7); canonical reference preserves history (2).

Numerical grading uses machine-readable artifacts or recomputation from saved
code, not rounded prose.

## Interpretation/judgment (10)

- Names DiD/comparison/parallel trends (3); state clustering, units and
  economic magnitude (3); cautious heterogeneity language (2); explains state
  trends and does not call vintage changes robustness (2).

## Friction (5)

Start at 5. Subtract one each for a redundant approval/plan gate, unnecessary
diagnostic inventory, obscuring generic prose, or unnecessary files/duplicated
state. Never penalize an appropriate question. Count repeated questions
separately. Tie-break: recovery, v2 integrity, numerical correctness, friction.
