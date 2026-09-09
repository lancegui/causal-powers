.rr_sha_file <- function(path) {
  if (!file.exists(path)) stop("missing file: ", path)
  digest::digest(path, algo = "sha256", file = TRUE)
}
.rr_atomic <- function(value, path, writer, validator=function(path) TRUE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(".result-registry-", dirname(path)); on.exit(unlink(tmp), add=TRUE)
  writer(value, tmp)
  if (!isTRUE(validator(tmp))) stop("staged artifact validation failed: ", path)
  if (!file.rename(tmp, path)) stop("atomic replacement failed: ", path)
}
.rr_required <- function(x, fields, label) {
  bad <- fields[!vapply(fields, function(n) !is.null(x[[n]]) && length(x[[n]]) &&
    !all(is.na(x[[n]])) && any(nzchar(as.character(x[[n]]))), logical(1))]
  if (length(bad)) stop(label, " missing: ", paste(bad, collapse=", "))
}
.rr_slug <- function(x) {
  out <- gsub("(^-+|-+$)", "", gsub("[^A-Za-z0-9._-]+", "-", x))
  if (!nzchar(out)) stop("empty outcome/family key"); out
}

register_regression_result <- function(
    model, estimates, registry_path="docs/analysis/results.yaml",
    store_path=NULL, outcome, result_family,
    spec, data_build, estimation_data, estimation_data_sha256,
    code_path, change_reason, run_id=NULL,
    role=c("current","experimental"), success=TRUE,
    requested_replacement=TRUE,
    created_at=format(Sys.time(), tz="UTC", usetz=TRUE)) {
  role <- match.arg(role)
  if (is.null(store_path))
    store_path <- sub("\\.ya?ml$", "-archive.rds", registry_path)
  if (identical(normalizePath(registry_path, mustWork=FALSE),
                normalizePath(store_path, mustWork=FALSE)))
    stop("registry_path and store_path must differ")
  if (!isTRUE(success)) stop("run failed; current unchanged")
  if (!is.data.frame(estimates) || !nrow(estimates) ||
      !all(c("term","estimate") %in% names(estimates)) ||
      any(!is.finite(estimates$estimate))) stop("finite term/estimate rows required")
  .rr_required(spec, c("outcome","treatment","formula","sample","window",
    "controls","fixed_effects","weights","clustering","estimator"), "spec")
  .rr_required(data_build, c("id","path","sha256"), "data_build")
  if (!file.exists(data_build$path) ||
      !identical(.rr_sha_file(data_build$path), data_build$sha256))
    stop("dataset build missing or hash mismatch")
  if (!file.exists(code_path)) stop("code_path does not exist")
  if (is.null(estimation_data) ||
      !identical(digest::digest(estimation_data, "sha256"), estimation_data_sha256))
    stop("estimation data missing or identity mismatch")

  code_text <- paste(readLines(code_path, warn=FALSE), collapse="\n")
  code_sha <- digest::digest(code_text, "sha256", serialize=FALSE)
  payload <- list(outcome=outcome, family=result_family, spec=spec,
    data_build=data_build[c("id","sha256")],
    estimation_data_sha256=estimation_data_sha256, code_sha256=code_sha,
    estimates=estimates)
  result_id <- digest::digest(jsonlite::toJSON(payload, auto_unbox=TRUE,
    dataframe="rows", null="null", digits=NA), "sha256", serialize=FALSE)
  if (is.null(run_id)) run_id <- paste0("run-", substr(result_id, 1, 12))

  lock <- paste0(registry_path, ".lock")
  dir.create(dirname(lock), recursive=TRUE, showWarnings=FALSE)
  if (!dir.create(lock, showWarnings=FALSE))
    stop("result registry locked; retry after active writer finishes")
  on.exit(unlink(lock, recursive=TRUE), add=TRUE)
  current <- if (file.exists(registry_path)) yaml::read_yaml(registry_path) else
    list(schema_version=1L, data_builds=list(), outcomes=list())
  store <- if (file.exists(store_path)) readRDS(store_path) else
    list(schema_version=1L, data_builds=list(), estimation_data=list(),
      results=list(), attempted_transitions=list())
  if (is.null(current$data_builds)) current$data_builds <- list()
  if (is.null(current$outcomes)) current$outcomes <- list()
  if (is.null(store$results)) store$results <- list()
  if (is.null(store$data_builds)) store$data_builds <- list()
  if (is.null(store$estimation_data)) store$estimation_data <- list()
  if (is.null(store$attempted_transitions)) store$attempted_transitions <- list()
  okey <- .rr_slug(outcome); fkey <- .rr_slug(result_family)
  onode <- current$outcomes[[okey]]
  if (!is.null(onode) && !identical(onode$label, outcome))
    stop("outcome key collision: ", outcome)
  if (is.null(onode)) onode <- list(label=outcome, families=list())
  family <- onode$families[[fkey]]
  if (!is.null(family) && !identical(family$label, result_family))
    stop("result-family key collision: ", result_family)
  if (is.null(family)) family <- list(label=result_family, current=NULL)
  current_ids <- unlist(lapply(current$outcomes, function(o)
    vapply(o$families, function(f) if (is.null(f$current)) NA_character_
      else f$current$result_id, character(1))))
  current_ids <- current_ids[!is.na(current_ids)]
  bundle_valid <- function(id) {
    b <- store$results[[id]]
    !is.null(b) && !is.null(b$model) && !is.null(b$code$content) &&
      nzchar(b$code$content) &&
      !is.null(store$estimation_data[[b$estimation_data_sha256]])
  }
  missing_current <- current_ids[
    !vapply(current_ids, bundle_valid, logical(1))]
  if (length(missing_current))
    stop("archive is missing an existing current result; current unchanged")
  if (!is.null(family$current) &&
      identical(family$current$result_id, result_id) &&
      bundle_valid(result_id))
    return(invisible(list(action="identical-rerun", result_id=result_id)))
  if (role=="current" && !isTRUE(requested_replacement) &&
      !is.null(family$current))
    stop("unrequested alternative cannot replace current; use experimental")
  old_build <- current$data_builds[[data_build$id]]
  if (!is.null(old_build) &&
      !identical(as.character(old_build$sha256), as.character(data_build$sha256)))
    stop("data build id maps to another hash")
  archived_build <- store$data_builds[[data_build$id]]
  if (!is.null(archived_build) &&
      !identical(as.character(archived_build$sha256),
                 as.character(data_build$sha256)))
    stop("archived data build id maps to another hash")

  predecessor <- if (!is.null(family$current)) family$current$result_id else NULL
  entry <- list(result_id=result_id, run_id=run_id, saved_as=role,
    created_at=created_at, change_reason=change_reason, outcome=outcome,
    result_family=result_family, spec=spec, data_build_id=data_build$id,
    estimation_data_sha256=estimation_data_sha256, code_sha256=code_sha,
    store_path=store_path, predecessor_result_id=predecessor,
    software=list(R=R.version.string,
      fixest=if (requireNamespace("fixest", quietly=TRUE))
        as.character(utils::packageVersion("fixest")) else NA_character_))
  if (is.null(store$results[[result_id]]))
    store$results[[result_id]] <- list(metadata=entry, data_build_id=data_build$id,
      estimation_data_sha256=estimation_data_sha256,
      code=list(path=code_path, sha256=code_sha, content=code_text),
      estimates=estimates, model=model)
  store$data_builds[[data_build$id]] <- data_build
  if (is.null(store$estimation_data[[estimation_data_sha256]]))
    store$estimation_data[[estimation_data_sha256]] <- estimation_data
  if (role=="current" && !is.null(predecessor) && predecessor != result_id)
    store$attempted_transitions[[length(store$attempted_transitions)+1L]] <- list(
      outcome=outcome, result_family=result_family, from=predecessor,
      to=result_id, run_id=run_id, reason=change_reason, created_at=created_at,
      status="proposed; live current pointer is authoritative")
  .rr_atomic(store, store_path, function(x,p) saveRDS(x,p),
    function(p) {
      x <- tryCatch(readRDS(p), error=function(e) NULL)
      !is.null(x) && !is.null(x$results[[result_id]]) &&
        !is.null(x$estimation_data[[estimation_data_sha256]])
    })
  if (role=="experimental")
    return(invisible(list(action="experimental", result_id=result_id,
      registry_path=registry_path, store_path=store_path)))
  if (role=="current") current$data_builds[[data_build$id]] <- data_build
  if (role=="current") family$current <- entry
  if (role=="current") onode$families[[fkey]] <- family
  current$outcomes[[okey]] <- onode
  used_builds <- unique(unlist(lapply(current$outcomes, function(o)
    vapply(o$families, function(f) if (is.null(f$current)) NA_character_
      else f$current$data_build_id, character(1)))))
  used_builds <- used_builds[!is.na(used_builds)]
  current$data_builds <- current$data_builds[intersect(names(current$data_builds),
    used_builds)]
  current$updated_at <- created_at
  .rr_atomic(current, registry_path, function(x,p) yaml::write_yaml(x,p),
    function(p) !is.null(tryCatch(yaml::read_yaml(p),
      error=function(e) NULL)$outcomes))
  invisible(list(action="promoted",
    result_id=result_id, registry_path=registry_path, store_path=store_path))
}

run_fixest_and_register <- function(
    formula, data, cluster, weights=NULL, registry_path="docs/analysis/results.yaml",
    store_path=NULL, outcome, result_family,
    spec, data_build, code_path, change_reason, run_id=NULL,
    role=c("current","experimental"), requested_replacement=TRUE,
    created_at=format(Sys.time(), tz="UTC", usetz=TRUE), ...) {
  role <- match.arg(role)
  model <- tryCatch(fixest::feols(formula, data=data, cluster=cluster,
      weights=weights, ...),
    error=function(e) stop("regression failed; current unchanged: ",
      conditionMessage(e)))
  fitted_formula <- stats::formula(model)
  fitted_outcome <- as.character(fitted_formula[[2]])
  if (!identical(as.character(outcome), fitted_outcome))
    stop("outcome key does not match fitted formula outcome; current unchanged")
  spec$formula <- paste(deparse(fitted_formula), collapse="")
  spec$outcome <- fitted_outcome
  spec$clustering <- paste(deparse(cluster), collapse="")
  spec$weights <- if (is.null(weights)) "none" else
    paste(deparse(weights), collapse="")
  spec$estimator <- "fixest::feols"
  ct <- fixest::coeftable(model)
  estimates <- data.frame(term=rownames(ct), estimate=unname(ct[,"Estimate"]),
    std_error=unname(ct[,"Std. Error"]), stringsAsFactors=FALSE)
  registration <- register_regression_result(model, estimates, registry_path, store_path,
    outcome, result_family, spec, data_build, data,
    digest::digest(data, "sha256"),
    code_path, change_reason, run_id, role, TRUE, requested_replacement,
    created_at)
  invisible(list(model=model, registration=registration))
}
