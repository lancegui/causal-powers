# Contract helpers — copy-paste preludes (Python / R / Julia / Stata)

The one-liners in SKILL.md cover a single check at a single line. The moment a
script has two or more joins, a reconciliation, or a baseline to freeze, you end
up wanting *functions* — and rewriting them per session is how they quietly lose
their teeth. Copy the block for your language into the script (or a small
`contracts.{py,R,jl}` next to it) and use it everywhere. Three design rules these
all follow:

1. **Fail loudly with a diagnostic**, not `False` — the error message names the
   keys/rows that broke the contract, so the failure IS the bug report.
2. **Bracket, don't trust** — row counts asserted *around* the operation, never
   inferred after the fact.
3. **Baselines are small committed text files** — diffable in git, not pickles.

---

## Python (pandas)

```python
import json, numpy as np, pandas as pd

def assert_join(left, right, on, how="left", expect="m:1", allow_unmatched=False):
    """Merge with declared cardinality + row-count bracket + unmatched/NA report."""
    validate = {"1:1": "one_to_one", "1:m": "one_to_many", "m:1": "many_to_one"}[expect]
    out = left.merge(right, on=on, how=how, validate=validate, indicator=True)
    if how == "left":
        assert len(out) == len(left), (
            f"left join fanned out: {len(left)} -> {len(out)} rows")
    unmatched = (out["_merge"] != "both").sum()
    if unmatched:
        if not allow_unmatched:
            bad = out.loc[out["_merge"] != "both", on].drop_duplicates().head(10)
            raise AssertionError(
                f"{unmatched} rows unmatched on {on}; sample keys:\n{bad}")
        # unmatched allowed -> the NAs it minted must still be SEEN, not silent
        new_cols = [c for c in out.columns if c not in left.columns and c != "_merge"]
        print(f"[assert_join] {unmatched}/{len(out)} rows unmatched on {on}; "
              f"NA in merged-in cols: {out[new_cols].isna().sum().to_dict()}")
    return out.drop(columns="_merge")

def reconcile(parts_sum, total, label, rtol=1e-6):
    """Totals must reconcile to source — the check that catches silent filters."""
    assert np.isclose(parts_sum, total, rtol=rtol), (
        f"RECONCILE FAIL [{label}]: parts={parts_sum:,.4f} vs total={total:,.4f} "
        f"(diff {parts_sum - total:+,.4f})")

def na_audit(df, cols=None, max_new_na=0, baseline=None, label="df"):
    """The NA map — call at FIRST LOAD of every dataframe. Reports missingness;
    pass a baseline dict to catch new NAs minted by later steps."""
    na = df[cols or df.columns].isna().sum()
    print(f"[na_audit] {label} ({len(df)} rows): "
          f"{ {c: int(n) for c, n in na.items() if n} or 'no NA' }")
    if baseline is not None:
        grew = {c: (int(na[c]), baseline.get(c, 0)) for c in na.index
                if na[c] > baseline.get(c, 0) + max_new_na}
        assert not grew, f"missingness grew vs baseline: {grew}"
    return na.to_dict()

def freeze_baseline(stats: dict, path):
    """Write the validated summary (counts, totals, key stats) as committed JSON."""
    json.dump(stats, open(path, "w"), indent=2, sort_keys=True, default=float)

def check_baseline(stats: dict, path, rtol=1e-9):
    frozen = json.load(open(path))
    for k, v in frozen.items():
        got = stats[k]
        ok = np.isclose(got, v, rtol=rtol) if isinstance(v, (int, float)) else got == v
        assert ok, f"BASELINE DRIFT [{k}]: frozen={v} vs now={got}"
```

Usage: `panel = assert_join(orders, customers, on="customer_id", expect="m:1")`,
then `reconcile(panel.rev.sum(), orders.rev.sum(), "revenue through join")`, and at
the end `freeze_baseline({"rows": len(panel), "rev": panel.rev.sum()}, "baseline.json")`.

---

## R (dplyr ≥ 1.1)

```r
library(dplyr)

assert_join <- function(left, right, by, how = "left", expect = "m:1",
                        allow_unmatched = FALSE) {
  rel <- c(`1:1` = "one-to-one", `1:m` = "one-to-many", `m:1` = "many-to-one")[[expect]]
  join_fn <- switch(how, left = left_join, inner = inner_join, full = full_join)
  out <- join_fn(left, right, by = by, relationship = rel)  # errors on violation
  if (how == "left") stopifnot("left join fanned out" = nrow(out) == nrow(left))
  bad <- anti_join(left, right, by = by)
  if (nrow(bad) > 0) {
    if (!allow_unmatched) stop(sprintf(
      "%d rows unmatched on %s; sample keys: %s", nrow(bad), paste(by, collapse = ","),
      paste(utils::head(unique(bad[[by[1]]]), 10), collapse = ", ")))
    # unmatched allowed -> the NAs it minted must still be SEEN, not silent
    new_cols <- setdiff(names(out), names(left))
    na <- colSums(is.na(out[new_cols]))
    message(sprintf("[assert_join] %d/%d rows unmatched on %s; NA in merged-in cols: %s",
      nrow(bad), nrow(out), paste(by, collapse = ","),
      paste(sprintf("%s=%d", names(na), na), collapse = ", ")))
  }
  out
}

na_audit <- function(df, label = deparse(substitute(df))) {
  # The NA map — call at FIRST LOAD of every dataframe.
  na <- colSums(is.na(df))
  hit <- na[na > 0]
  message(sprintf("[na_audit] %s (%d rows): %s", label, nrow(df),
    if (length(hit)) paste(sprintf("%s=%d", names(hit), hit), collapse = ", ") else "no NA"))
  invisible(na)
}

reconcile <- function(parts_sum, total, label, tol = 1e-6) {
  if (!isTRUE(all.equal(parts_sum, total, tolerance = tol))) stop(sprintf(
    "RECONCILE FAIL [%s]: parts=%.4f vs total=%.4f (diff %+.4f)",
    label, parts_sum, total, parts_sum - total))
}

freeze_baseline <- function(stats, path)            # stats: named list
  jsonlite::write_json(stats, path, auto_unbox = TRUE, digits = 12, pretty = TRUE)

check_baseline <- function(stats, path, tol = 1e-9) {
  frozen <- jsonlite::read_json(path, simplifyVector = TRUE)
  for (k in names(frozen)) {
    ok <- if (is.numeric(frozen[[k]])) isTRUE(all.equal(stats[[k]], frozen[[k]], tolerance = tol))
          else identical(stats[[k]], frozen[[k]])
    if (!ok) stop(sprintf("BASELINE DRIFT [%s]: frozen=%s vs now=%s",
                          k, frozen[[k]], stats[[k]]))
  }
}
```

---

## Julia (DataFrames.jl)

```julia
using DataFrames, JSON3

function assert_join(left, right; on, how=:left, expect="m:1", allow_unmatched=false)
    expect in ("1:1","m:1") && @assert allunique(right[!, on]) "right key not unique ($on)"
    expect in ("1:1","1:m") && @assert allunique(left[!, on])  "left key not unique ($on)"
    out = how == :left ? leftjoin(left, right, on=on) : innerjoin(left, right, on=on)
    how == :left && @assert nrow(out) == nrow(left) "left join fanned out: $(nrow(left)) -> $(nrow(out))"
    bad = antijoin(left, right, on=on)
    if nrow(bad) > 0
        allow_unmatched || error("$(nrow(bad)) rows unmatched on $on; sample: $(first(unique(bad[!,on]), 10))")
        # unmatched allowed -> the missings it minted must still be SEEN, not silent
        new_cols = setdiff(names(out), names(left))
        na = Dict(c => count(ismissing, out[!, c]) for c in new_cols)
        @info "[assert_join] $(nrow(bad))/$(nrow(out)) rows unmatched on $on; missing in merged-in cols: $na"
    end
    out
end

function na_audit(df; label="df")
    # The NA map — call at FIRST LOAD of every dataframe.
    na = Dict(c => count(ismissing, df[!, c]) for c in names(df))
    hit = filter(p -> p.second > 0, na)
    @info "[na_audit] $label ($(nrow(df)) rows): $(isempty(hit) ? "no missing" : hit)"
    na
end

reconcile(parts_sum, total, label; rtol=1e-6) =
    @assert isapprox(parts_sum, total; rtol) "RECONCILE FAIL [$label]: $parts_sum vs $total"

freeze_baseline(stats::Dict, path) = open(io -> JSON3.pretty(io, stats), path, "w")

function check_baseline(stats::Dict, path; rtol=1e-9)
    frozen = JSON3.read(read(path, String), Dict)
    for (k, v) in frozen
        ok = v isa Number ? isapprox(stats[k], v; rtol) : stats[k] == v
        @assert ok "BASELINE DRIFT [$k]: frozen=$v vs now=$(stats[k])"
    end
end
```

---

## Stata

Stata ships the contract primitives natively — use them instead of reimplementing:

```stata
* --- NA map at first load of every dataset ---
misstable summarize                   // per-variable missing counts, into the log

* --- key uniqueness: the precondition of every merge ---
isid customer_id                      // hard-fails if not unique

* --- merge with declared cardinality + match contract ---
merge m:1 customer_id using customers, assert(match master) keep(match master)
* assert() IS the cardinality+match contract: it hard-fails on any _merge
* value you didn't declare. Never `merge` without assert() or an explicit
* tab _merge + count check right after.

* --- row-count bracket around any step that must not change N ---
count
local n_before = r(N)
* ... transformation ...
count
assert r(N) == `n_before'

* --- totals reconcile (float-tolerant) ---
quietly summarize revenue
local total_after = r(sum)
assert abs(`total_after' - `total_before') < 1e-6 * max(abs(`total_before'), 1)

* --- freeze a validated dataset state ---
datasignature set, reset saving(baseline, replace)   // freeze
datasignature confirm using baseline                  // any later run: drift -> error
```

A note on scope: the family's guidance prose is written for R/Julia/Python, but
research repos are polyglot and Stata is common in economics — these primitives
(`isid`, `merge, assert()`, `datasignature`) make Stata the easiest language of
the four to contract, so there's no excuse to skip it there.

---

## Watch-it-bite applies to helpers too

After dropping a prelude in, break something once on purpose — duplicate one key
row, perturb one total — and confirm the helper *fires with a useful message*.
A helper you've never seen fail is decoration (SKILL.md, "Watch it bite").
