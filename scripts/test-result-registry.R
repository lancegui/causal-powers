#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(fixest); library(yaml); library(digest)})
source("skills/analysis-state-management/scripts/save-regression-result.R")
root <- tempfile("result-registry-test-"); dir.create(root)
old <- setwd(root); on.exit(setwd(old), add=TRUE)
dir.create("docs/analysis", recursive=TRUE); dir.create("results")
set.seed(19)
d <- expand.grid(id=1:12, time=1:8)
d$treat <- as.integer(d$id<=6 & d$time>=5)
d$w <- 1 + d$id/100
d$y <- rep(rnorm(12), each=8) + rep(seq_len(8)/10, 12) - 2*d$treat +
  rnorm(nrow(d), sd=.1)
d$z <- d$y + rnorm(nrow(d), sd=.2)
write.csv(d, "panel.csv", row.names=FALSE)
writeLines(c("# retained analysis source", "fit <- y ~ treat | id + time"), "analysis.R")
build <- list(id="panel-v1", path="panel.csv",
  sha256=digest("panel.csv", "sha256", file=TRUE))
spec <- list(outcome="y", treatment="treat", formula="placeholder",
  sample="12 units", window="time 1-8", controls="none",
  fixed_effects="id + time", weights="placeholder", clustering="placeholder",
  estimator="placeholder")
run <- function(outcome="y", family="main", reason="initial", id="r1",
                role="current", replace=TRUE, data=d, formula=y~treat|id+time,
                cluster=~id, weights=NULL)
  run_fixest_and_register(formula, data, cluster, weights=weights, outcome=outcome,
    result_family=family, spec=spec, data_build=build, code_path="analysis.R",
    change_reason=reason, run_id=id, role=role,
    requested_replacement=replace,
    created_at=paste0("2026-09-09T00:00:0",id,"Z"))$registration

a <- run()
stopifnot(a$action=="promoted", file.exists("docs/analysis/results.yaml"),
  file.exists("docs/analysis/results-archive.rds"))
cur1 <- read_yaml("docs/analysis/results.yaml")
id1 <- cur1$outcomes$y$families$main$current$result_id
stopifnot(cur1$outcomes$y$families$main$current$spec$clustering=="~id",
  cur1$outcomes$y$families$main$current$spec$weights=="none")

b <- run(id="2")
stopifnot(b$action=="identical-rerun",
  length(readRDS("docs/analysis/results-archive.rds")$results)==1)

d2 <- d; d2$y <- d2$y + .2*d2$treat
c <- run(reason="requested revised outcome", id="3", data=d2)
cur2 <- read_yaml("docs/analysis/results.yaml")
id2 <- cur2$outcomes$y$families$main$current$result_id
stopifnot(id2 != id1,
  !is.null(readRDS("docs/analysis/results-archive.rds")$results[[id1]]$code$content))
archive <- readRDS("docs/analysis/results-archive.rds")
old_bundle <- archive$results[[id1]]
old_data <- archive$estimation_data[[old_bundle$metadata$estimation_data_sha256]]
old_refit <- feols(y~treat|id+time, old_data, cluster=~id)
stopifnot(identical(unname(coef(old_refit)["treat"]),
  unname(old_bundle$model$coefficients["treat"])))

invisible(run(family="regional", reason="supporting", id="4", data=d2))
invisible(run(outcome="z", reason="other outcome", id="5", data=d2,
  formula=z~treat|id+time))
invisible(run(family="weighted", reason="weighted supporting", id="5w",
  data=d2, cluster=~time, weights=~w))
invisible(run(family="log-main", reason="transformed outcome", id="5l",
  data=d2, formula=log(y-min(y)+1)~treat|id+time))
cur3 <- read_yaml("docs/analysis/results.yaml")
stopifnot(cur3$outcomes$y$families$main$current$result_id==id2,
  !is.null(cur3$outcomes$y$families$regional$current),
  !is.null(cur3$outcomes$z$families$main$current),
  cur3$outcomes$y$families$weighted$current$spec$clustering=="~time",
  cur3$outcomes$y$families$weighted$current$spec$weights=="~w",
  grepl("^log\\(", cur3$outcomes$y$families[["log-main"]]$current$
    spec$outcome_expression))

before <- digest("docs/analysis/results.yaml", "sha256", file=TRUE)
try(run(reason="failed", id="6", data=d2, formula=y~missing|id+time), silent=TRUE)
stopifnot(digest("docs/analysis/results.yaml", "sha256", file=TRUE)==before)
invisible(run(family="alternative", reason="experimental", id="7", data=d2,
  role="experimental"))
stopifnot(is.null(read_yaml("docs/analysis/results.yaml")$outcomes$y$
  families$alternative$current))

rev <- run(reason="requested reversion", id="rev", data=d)
stopifnot(rev$action=="promoted",
  read_yaml("docs/analysis/results.yaml")$outcomes$y$families$main$
    current$result_id==id1)

dir.create("docs/analysis/results.yaml.lock")
locked <- try(run(family="locked", id="8", data=d2), silent=TRUE)
stopifnot(inherits(locked, "try-error"))
unlink("docs/analysis/results.yaml.lock", recursive=TRUE)
all_current <- read_yaml("docs/analysis/results.yaml")
for (onode in all_current$outcomes) for (fam in onode$families)
  if (!is.null(fam$current))
    stopifnot(!is.null(readRDS("docs/analysis/results-archive.rds")$
      results[[fam$current$result_id]]))
archive_ok <- readRDS("docs/analysis/results-archive.rds")
current_before_broken <- digest("docs/analysis/results.yaml", "sha256", file=TRUE)
unlink("docs/analysis/results-archive.rds")
broken <- try(run(id="9"), silent=TRUE)
stopifnot(inherits(broken, "try-error"),
  digest("docs/analysis/results.yaml", "sha256", file=TRUE)==current_before_broken)
saveRDS(archive_ok, "docs/analysis/results-archive.rds")
stopifnot(setequal(list.files("docs/analysis"),
  c("results.yaml", "results-archive.rds")))

atomic_ok <- .rr_atomic
d3 <- d2; d3$y <- d3$y + .1*d3$treat
archive_before_fault <- digest("docs/analysis/results-archive.rds",
  "sha256", file=TRUE)
current_before_fault <- digest("docs/analysis/results.yaml",
  "sha256", file=TRUE)
.rr_atomic <- function(value, path, writer, validator=function(path) TRUE) {
  if (grepl("archive", path)) {
    tmp <- tempfile(".injected-", dirname(path)); on.exit(unlink(tmp), add=TRUE)
    writer(value, tmp)
    stop("injected staged archive failure")
  }
  atomic_ok(value, path, writer, validator)
}
stopifnot(inherits(try(run(id="10", data=d3), silent=TRUE), "try-error"),
  digest("docs/analysis/results-archive.rds","sha256",file=TRUE)==archive_before_fault,
  digest("docs/analysis/results.yaml","sha256",file=TRUE)==current_before_fault)

.rr_atomic <- function(value, path, writer, validator=function(path) TRUE) {
  if (grepl("results.yaml$", path)) stop("injected current-index failure")
  atomic_ok(value, path, writer, validator)
}
stopifnot(inherits(try(run(id="11", data=d3), silent=TRUE), "try-error"),
  digest("docs/analysis/results.yaml","sha256",file=TRUE)==current_before_fault)
.rr_atomic <- atomic_ok
cat("result-registry lifecycle: PASS\n")
