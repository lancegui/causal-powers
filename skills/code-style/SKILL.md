---
name: code-style
description: >-
  Use when WRITING a NEW script or code chunk in R, Julia, or Python for this author (data-processing,
  stylized-facts, estimation, counterfactual, or scraping scripts), or when asked to write code the
  way they would, in their style, like their other scripts, as a flat script. Defines the house script
  voice. A flat top-to-bottom lab-notebook script (library block, loads, short dplyr pipes reassigned
  in place, hash-wall banners, bare-expression checks at data boundaries, save and reload at each
  heavy step); Julia written as the paper's equations (Greek parameters, one-liner formulas,
  SharedVector + @threads, JLD2 checkpoints); Python as a flat script with helpers above a
  module-level driver and no main(). Eight default-on one-line improvements (explicit join keys,
  forward-slash relative paths, seed before draws, column list named once, one parameterized scenario
  function). Runs alongside analysis-craft; figures stay with figure-craft.
---

# Code Style

## Overview

`analysis-craft` says *match the existing style*. This skill is that style written down, for the file that has no neighbor yet. It was distilled from the author's research repositories (54 R and 38 Julia scripts in the buprenorphine-pharmacy project, plus the scrapers) and it is a **voice**, not a linter: a script you write should be indistinguishable from one the author wrote last month, plus a handful of one-line improvements the author agreed to.

**Core principle: a script is a lab notebook, not a program.** It is run chunk by chunk in an editor with a live REPL, top to bottom, with the state inspected between chunks. Everything below follows from that — no entry point, no indirection, state saved to disk at every expensive step, checks that are bare expressions printed to the console.

What this skill does **not** own: how much machinery is too much (`analysis-craft`), figure styling (`figure-craft`), where the file goes (`project-organization`), whether the number is right (`data-contracts`). It owns idiom only.

## The shape every script has (R, Julia, Python)

1. **Imports first, nothing above them.** One per line, no comments between, the same core set every time (below). No `install.packages` / `Pkg.add` inside the script.
2. **Then the loads.** Each input into a descriptively named object. The main table is `df`; a vector of keys is `ids`; a lookup you will join is named for what it is (`pharm_link`, `bup_ndc`, `zcta_attributes`).
3. **Then chunks.** A chunk is one idea in 5–30 lines, ending in a state you can look at. When the topic changes, a hash-wall banner with a short lowercase title: `################ stock-out rate by chain ################`. Banners are the only structure; no function wraps a chunk.
4. **Checks are bare expressions.** `nrow(df)`, `summary(df)`, `mean(x)`, `sum(a) / sum(b)`, `@time f(x)` — printed at a data boundary (after a load, a join, a filter, a fit). No test framework, no logger, no `print("checking...")` wrapper.
5. **Save after anything expensive, reload at the top of the next chunk** — `saveRDS` / `readRDS`, `write_parquet` / `open_dataset`, `@save` / `@load`. Any chunk can be re-entered from disk without rerunning the ones above it.
6. **A function only when the body runs per unit** (inside `map_dfr`, `lapply`, `Threads.@threads`) **or would otherwise be pasted twice.** Define it right above its first use. Julia numerical helpers shared by several scripts live in `Utility_Functions/utility.jl` and are `include`d; R almost never sources a utils file.
7. **Names.** snake_case, descriptive, in the economics (`other_opioid_shipment`, `stock_out_rate`, `coef_by_pharmacy`, `distance_from_default`). Scripts are `Capitalized_Snake_Case.R` / `.jl`: a verb first for pipeline steps (`Create_Inventory.R`, `Process_Medical_Claims.R`, `Link_Pharmacy.R`), a noun for facts and results (`Default_Option.R`, `Who_Carry_Bupe.R`, `Plot_Counterfactuals.jl`).
8. **Comments are sparse, lowercase, one line, and say what the chunk is for or why a choice was made** — `# exclude current day`, `# need to remove default pharmacy or purchased pharmacy is 50 miles away`, `# then I hand cleaned to create WA_APCD_pharmacy_v3.csv`. Commented-out code is a toggle and stays.
9. **Paths are project-root-relative with forward slashes** (`"Data/x.parquet"`, `"Plots/x.png"`); the working directory is the repo root. Folders are pipeline stages: `Data/`, `Temp_Analysis_Data/`, `Data_Processing/`, `Stylized_Facts/`, `Estimation/`, `Counterfactuals/`, `Simulation/`, `Plots/`, `Utility_Functions/`, `Tex/`.
10. **Not in this voice:** `main()`, `if __name__ == "__main__"`, argparse, classes, Julia modules or abstract types, config files / YAML, `here::here`, roxygen or docstrings on a one-off, unit tests, a logging framework, a `utils` file of one-call helpers, a fifteen-verb pipe.

## R — dplyr as the sentence

- **`%>%` and `<-`.** Never `|>`, never `=` for assignment. 2-space indent. `TRUE` / `FALSE` spelled out.
- **The library block:** `arrow`, `dplyr`, `readr`, `lubridate`, `stringr`, `fixest`, `ggplot2`, `ggthemes`, plus `data.table` (for `fread` of big delimited text), `purrr` + `broom` (when looping fits), `slider` / `zoo` (rolling windows). `tidyr::` and `scales::` are called namespaced inline — never `library(tidyr)`, never `library(tidyverse)`.
- **Big inputs stay lazy:** `open_dataset("Data/PHARMACY_CLAIMS") %>% filter() %>% select() %>% ... %>% collect()` — verbs first, `collect()` as late as possible. Small inputs: `read_csv` (`fread(..., sep = "*")` for the `*`-delimited raw text). Intermediates: `saveRDS(x, "Temp_Analysis_Data/x.RDS")`; a final analysis dataset: `write_parquet`.
- **Pipes are short (3–6 verbs) and reassign in place.** One analytical decision per pipe — a join, a filter, a recode — then `df <- df %>% ...` again. A derived table gets its own name (`last_observation`, `sd_long`, `coefs_wide`), not `df2`.
- **The idioms:**
  - keys: `ids <- df %>% distinct(internal_member_id) %>% pull()`; then `filter(internal_member_id %in% ids)`
  - join a trimmed lookup: `left_join(pharm_link %>% select(pharmacy_id, BUYER_DEA_NO), by = "BUYER_DEA_NO")`, and collapse a fan-out right after with `distinct(key, .keep_all = TRUE)`
  - `group_by() %>% summarise(..., .groups = "drop")`; `ungroup()` after a grouped `mutate`
  - `ifelse` / `if_else` for two branches, `case_when` for three or more; fill with `mutate(x = ifelse(is.na(x), 0, x))`
  - a calendar: `group_by(id) %>% tidyr::complete(date = seq(min(date), max(date), by = "day"), fill = list(x = 0)) %>% ungroup()`; windows: `slide_index_dbl(.x, .i = date, .f = sum, .before = days(30), .after = -1)`
  - reshape: `tidyr::pivot_longer` / `tidyr::pivot_wider`
- **Per-unit fits** are a `map_dfr` over `ids` with the guard, the `tryCatch`, and `tidy()`:

```r
coef_by_pharmacy <- map_dfr(pharmacy_ids, function(pid) {
  data_subset <- inventory %>% filter(pharmacy_id == pid)
  if (nrow(data_subset) < 10) return(NULL)
  model <- tryCatch(glm(shipment_exist ~ predict_sales + lag_inventory, data = data_subset, family = binomial(link = "probit")),
                    error = function(e) NULL)
  if (is.null(model)) return(NULL)
  tidy(model) %>% mutate(pharmacy_id = pid)
})
```

- **Regressions are `fixest`:** `feols(y ~ x1 + x2 | zip + year, data = df, cluster = "pharmacy_id")`; tables via `etable(..., tex = TRUE)`; summary statistics via `stargazer(type = "text", summary.stat = c("mean", "sd", "min", "p25", "median", "p75", "max"))`.
- **Plots are piped into ggplot** — `df %>% mutate(...) %>% ggplot(aes(...)) + geom_*() + theme_hc() + scale_fill_ptol() + theme(legend.title = element_blank())` then `ggsave("Plots/x.png", width = 2000, height = 1500, units = "px")`. The styling rules are `figure-craft`'s.

## Julia — write the paper's equations

- **The `using` block**, then `include(joinpath(@__DIR__, "..", "Utility_Functions", "utility.jl"))` when a shared helper is needed. Core set: `DataFrames`, `LinearAlgebra`, `Statistics`, `Random`, `Distributions`, `Optim`, `ForwardDiff`, `JLD2`, `Parquet2` (`using Parquet2: Dataset`) or `CSV`, `Base.Threads`, `SharedArrays`, `SpecialFunctions`, `Plots`. 4-space indent.
- **Load:** `df = Dataset("Data/estimation_data.parquet") |> DataFrame`. Subset rows with a mask: `df = df[df.availability .== 1, :]`.
- **Build variables as columns, then the matrix from a named column list:**

```julia
df[!, :constant] = ones(nrow(df))
df[!, :price_medicaid] = df[!, :price] .* df[!, :medicaid]
df[!, :age_squared] = df[!, :age] .^ 2

consumption_cols = [:constant, :price, :price_medicaid, :distance_from_default, :age, :age_squared]
X = Matrix{Float64}(df[!, consumption_cols])
Y = Vector{Float64}(df[!, :purchased])
```

  The coefficient table is built from the same vector — `DataFrame(Column_Name = consumption_cols, Theta_Value = θ_hat, se = se)` — so labels and columns cannot drift.
- **Notation is the paper's.** Greek for parameters and latent quantities — `θ`, `β`, `λ`, `δ`, `μ`, `ϕ`, `σ` — and `θ_hat` for an estimate; single capitals for data matrices and indicators — `X`, `Z`, `Y`, `D`, `A`, `O`, `U`, `R`, `W`, `C`. Slice the parameter vector where the model does: `β = θ[1:34]; λ = θ[35:70]`.
- **A formula is a one-liner function:** `Fz(z, δ, μ) = exp(-exp(δ - z))`, `f(y) = Base.MathConstants.eulergamma - y + expint(exp(-y))`. Broadcast with dots; use matrix algebra where the math is matrix algebra (`δ = X * β`); write a loop only where the math is a loop.
- **`function … end` for anything with a loop or a branch;** `!` suffix when it mutates an argument (`compute_one_patient!`); type-annotate only hot-path signatures (`c_matrix::Matrix{Float64}`); a callable struct replaces a closure inside a root-finding hot loop:

```julia
struct FMinusC{F, T}
    f::F
    c::T
end
(fmc::FMinusC)(y) = fmc.f(y) - fmc.c
```

- **Likelihood and inference:**

```julia
function likelihood(θ, X, Z, Y, D, O)
    β = θ[1:size(X, 2)]
    λ = θ[size(X, 2) + 1:end]
    δ = X * β
    μ = log.(1 .+ exp.(Z * λ))
    util = (δ .- μ) .* (1 .- D) .+ δ .* D
    util = util .* (1 .- O)
    P = util .- log.(groupby_sum(member_key, exp.(util)))
    return -sum(P .* Y)
end

@time likelihood(θ0, X, Z, Y, D, O)

result = optimize(θ -> likelihood(θ, X, Z, Y, D, O), θ0, LBFGS(),
                  Optim.Options(show_trace = true, iterations = 1500, g_tol = 1e-6))
θ_hat = Optim.minimizer(result)
@save "Data/Estimation_Result/estimation_result.jld2" θ_hat

H = ForwardDiff.hessian(θ -> likelihood(θ, X, Z, Y, D, O), θ_hat)
se = sqrt.(diag(inv(H)))
```

- **Per-unit parallel work:** preallocate `SharedVector{Float64}(length(ids) * S)` (one slot per unit × draw), one function per unit that writes its own slice, `Threads.@threads for idx in eachindex(ids)` with `try … catch e; @error "Error for patient $i" end`, `@inbounds @simd` on the innermost loop, then `@save` the vectors immediately and `@load` them back at the top of the next chunk.
- **A scenario is a keyword argument, not a second copy of the function.** `compute_one_patient!(i, out...; ϕ = df.ϕ, A = df.availability, bounds = (-0.1, 0.1))` is defined once and called once per counterfactual with different inputs.
- **Checks:** bare expressions (`sum(purchase_bupe) / length(purchase_bupe)`, `mean(search_stop)`), `@time` on the first call of anything heavy; when the script must also run non-interactively (`julia file.jl` prints nothing for a bare expression), `@show` is the same check and stays one line. A scratch block at the bottom (`i = 1` and the function body unrolled) for stepping through one unit is normal.
- **Plots.jl:** `p = bar(labels, ys; alpha = 0.6, label = "", legend = false, dpi = 1000)`, `savefig(p, "Plots/Round_2/x.pdf")` — styling per `figure-craft`.

## Python — a flat script for tooling

Python is for scraping and tooling (the language profile), and it is written as a script, not a program:

```python
import re
import time
import os
import pandas as pd
import requests

INPUT_CSV = "Data/bup_NDC_final.csv"
OUTPUT_CSV = "Data/bup_NDC_ndclist.csv"
DELAY_BETWEEN_REQUESTS = 1.5

def parse_product_page(html):
    ...
    return result            # a plain dict, or None on failure

df = pd.read_csv(INPUT_CSV, dtype={"NDC_NO": str})
done = set(pd.read_csv(OUTPUT_CSV, dtype={"NDC_NO": str})["NDC_NO"]) if os.path.exists(OUTPUT_CSV) else set()
to_process = df[~df["NDC_NO"].isin(done)]
print(f"Remaining: {len(to_process)}")

rows = []
for i, (_, row) in enumerate(to_process.iterrows()):
    print(f"[{i+1}/{len(to_process)}] NDC: {row['NDC_NO']}")
    ...
    time.sleep(DELAY_BETWEEN_REQUESTS)
    if (i + 1) % 10 == 0:
        pd.DataFrame(rows).to_csv(OUTPUT_CSV, mode="a", index=False, header=not os.path.exists(OUTPUT_CSV))
        rows = []
```

- `import` block, then the constants in ALL_CAPS right below (`INPUT_CSV`, `OUTPUT_CSV`, `SEARCH_BASE`, `DELAY_BETWEEN_REQUESTS`).
- `def` helpers above the driver, each doing one named thing (`make_driver()`, `get_first_result_url(driver, ndc)`, `parse_product_page(url)`), returning plain dicts / `None` on failure. Then the **driver loop at module level** — **no `def main()`, no `if __name__ == "__main__":`, no argparse**.
- `pandas` for tables; `print(f"[{i+1}/{n}] {key}")` progress; `time.sleep(DELAY)` between requests; `try/except` around the network call only; append to the output CSV every k records and skip already-processed keys on restart, so a crash costs nothing.
- 4-space indent, f-strings, type hints only where they read as documentation, no classes, no `logging`.

## Default-on minimal improvements (agreed; each is one line in the same voice)

1. **Explicit join keys, always:** `left_join(..., by = c("pharmacy_id", "TRANSACTION_DATE"))` — the message-driven natural join was half the joins, and a renamed column turns it into a silent cross. After a join that could fan out, print `nrow(df)` before and after (or collapse with `distinct(key, .keep_all = TRUE)` as before); a script that runs unattended may use `stopifnot(nrow(df) == n0)`.
2. **Forward-slash project-relative paths everywhere** — no `"Data\\x.csv"`, no `C:/Users/...`; Julia `include(joinpath(@__DIR__, …))`. The scripts moved machines; the hard-coded paths broke.
3. **Seed before any draw** — `set.seed(…)` / `Random.seed!(…)` at the top of a chunk that calls `rand`, `sample`, or inverse sampling. Counterfactual numbers must reproduce.
4. **Name the column list once** (Julia) and build the design matrix and the coefficient table from the same vector.
5. **One scenario function with keyword arguments**, called N times, instead of redefining `compute_one_patient!` N times in one file.
6. **A magic number used twice gets a name at the top of its chunk** — `meters_per_mile <- 1609.34`, `max_distance_miles <- 50`; a denominator like `59579` is computed (`n_distinct(df$internal_member_id)`), not typed.
7. **`.groups = "drop"` on every grouped `summarise`**, so nothing stays grouped by accident.
8. **No duplicate or unused `using` / `library` lines.**

Kept on purpose (offer, never impose): hash-wall banners; REPL-print checks; commented-out toggles; `_v2` / `_final` / `_202508` file suffixes (git could carry versions — the author's call); no tests.

## Red flags — STOP and rewrite in the voice

- `def main():` / `if __name__ == "__main__":` / `argparse` in a script.
- `|>`, `library(tidyverse)`, `=` for assignment, `here::here()`.
- A class, a Julia `module`, a config YAML, a `utils.R` of one-call helpers, a docstring on a one-off.
- One pipe with a join, a filter, a recode, and a summarise in it.
- `left_join()` without `by =`; `Data\\` in a path; `rand` / `sample` with no seed above it.
- The same function defined twice in one file with one line changed.
- A figure built here with its own theme — hand it to `figure-craft`.

## Common rationalizations

| Excuse | Reality |
|---|---|
| "A `main()` makes it importable and testable." | Nobody imports a stylized-facts script. The author runs it chunk by chunk; `main()` hides the state they want to inspect. |
| "I'll make the column list a config." | A named vector at the top of the chunk *is* the config. A file is indirection. |
| "The natural join found the keys." | Until a rename makes it a cross join and the total doubles. `by =` costs eight characters. |
| "A fresh helper file keeps the script clean." | It keeps the logic out of sight. Define the function right above its one use. |

## The Process

1. **Is there a neighbor file?** Match it first (`analysis-craft`). No neighbor → this skill's shape and the idioms for the language.
2. **Pick the language from the profile** (R for data / figures / reduced-form, Julia for structural, Python for scraping / tooling) and say so.
3. **Write chunk by chunk:** imports → loads → banner → 5–30 lines → bare-expression check → save. Reload from disk at the start of the next chunk.
4. **Apply the eight default-on improvements silently**; anything beyond them is an offer in one line, not a change.
5. **Hand off:** figures → `figure-craft`; placement and naming → `project-organization`; join cardinality and reconciliation → `data-contracts`.

## The bottom line

```
In the voice   →  flat lab-notebook script: imports → loads → banner'd chunks of short reassigned pipes (R) /
                  the paper's equations in Greek with SharedVector + @threads + @save (Julia) /
                  helpers above a module-level driver, no main() (Python); bare-expression checks at
                  data boundaries; explicit join keys, forward-slash paths, a seed before every draw
Not the voice  →  an entry point, a class, a config file, a utils module, a fifteen-verb pipe,
                  a natural join, a backslash path, the same function pasted seven times
```
