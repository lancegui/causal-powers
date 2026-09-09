# Outcome-scoped regression registry

For R/fixest, source `scripts/save-regression-result.R` and call
`run_fixest_and_register()`. One call fits the regression, derives the
formula/clustering/weights from the fitted call, stores recoverable evidence,
and only then advances current.

Small projects use two generated files:

- `docs/analysis/results.yaml`: concise current view with shared data builds
  and one current pointer per outcome/result family.
- `docs/analysis/results-archive.rds`: consolidated models, estimates,
  actual source content, predecessors, and experiments keyed by result ID.

Each current entry includes the outcome group and exact fitted outcome
expression, treatment, formula, sample, window,
controls, fixed effects, weights, clustering, estimator, data build, actual
estimation-data hash, code/output identity, run ID, and change reason. Main and
supporting families can remain current together.

The helper validates the build hash, required spec, finite estimates, fitted
call, estimation-data identity, and archive read-back. A fail-fast directory
lock serializes writers. The archive writes first; the atomic current-index
replacement is the commit point. Failed runs cannot move current, though a
failed final index write may leave an unreferenced archive bundle.
Proposed transitions in the archive are audit hints; live current pointers are
the sole authority for completed promotion. Entries record R and fixest
versions. Required packages are `fixest`, `yaml`, `digest`, and
`jsonlite`.

A requested successful replacement advances only its outcome/family pointer;
old bundles stay archived. Experiments enter the archive without replacing
current. Bundle `saved_as` records how it entered; current status has one
source of truth: the live pointer. An already-current identity is a no-op. An explicit requested
reversion may point current to an older archived bundle.

Large projects may split one registry/store pair per outcome. On resume, the
index names only the relevant current registry; read the archive only for a
comparison or recovery.

This guarantee covers helper-mediated R regressions. Direct estimator/output
writes bypass it.

## Minimal R use and recovery

```r
source("skills/analysis-state-management/scripts/save-regression-result.R")
d <- read.csv("data/output/panel.csv")
build <- list(id="panel-2026-09-09", path="data/output/panel.csv",
  sha256=digest::digest("data/output/panel.csv", "sha256", file=TRUE))
spec <- list(treatment="policy", sample="40 states",
  window="2018-01 to 2022-12", controls="none",
  fixed_effects="state + month")
fit <- run_fixest_and_register(
  employment_rate ~ policy | state + month, d, ~state,
  outcome="employment_rate", result_family="main-did", spec=spec,
  data_build=build, code_path="analysis.R",
  change_reason="requested update with revised source vintage")
summary(fit$model)
```

`run_id` defaults to the result-identity prefix and time defaults to UTC.
Recovery reads the archive only on demand:

```r
current <- yaml::read_yaml("docs/analysis/results.yaml")
id <- current$outcomes$employment_rate$families[["main-did"]]$current$result_id
archive <- readRDS("docs/analysis/results-archive.rds")
bundle <- archive$results[[id]]
data <- archive$estimation_data[[bundle$metadata$estimation_data_sha256]]
code <- bundle$code$content
```
