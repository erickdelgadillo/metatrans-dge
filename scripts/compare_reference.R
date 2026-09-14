#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "common.R"))
repository_root <- script_repository_root()
load_workflow(repository_root)
assert_packages(c("arrow", "data.table"))
arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))
organism <- match.arg(if (is.null(arguments$organism)) "prokaryotes" else arguments$organism,
                      c("prokaryotes", "eukaryotes"))
strict <- if (is.null(arguments$strict)) FALSE else {
  value <- tolower(arguments$strict)
  if (!value %in% c("true", "false")) {
    stop("--strict must be true or false.", call. = FALSE)
  }
  identical(value, "true")
}
data_root <- if (is.null(arguments$`data-root`)) default_data_root() else arguments$`data-root`
config <- organism_config(organism, data_root)
generated_file <- if (is.null(arguments$generated)) {
  file.path(repository_root, "results", organism, config$output_name)
} else {
  arguments$generated
}
if (!file.exists(generated_file)) stop("Generated result not found: ", generated_file, call. = FALSE)
if (!file.exists(config$reference)) stop("Reference result not found: ", config$reference, call. = FALSE)

columns <- c(config$feature_column, "contrast", "logFC", "logCPM", "F", "PValue", "FDR")
generated <- data.table::as.data.table(arrow::read_parquet(generated_file))[, ..columns]
reference <- data.table::as.data.table(arrow::read_parquet(config$reference))[, ..columns]
key <- c(config$feature_column, "contrast")
data.table::setkeyv(generated, key)
data.table::setkeyv(reference, key)
if (!identical(generated[, ..key], reference[, ..key])) {
  stop("Generated and reference feature/contrast keys differ.", call. = FALSE)
}
metrics <- c("logFC", "logCPM", "F", "PValue", "FDR")
comparison <- data.frame(
  metric = metrics,
  correlation = vapply(metrics, function(metric) {
    stats::cor(generated[[metric]], reference[[metric]], use = "complete.obs")
  }, numeric(1)),
  mean_absolute_difference = vapply(metrics, function(metric) {
    mean(abs(generated[[metric]] - reference[[metric]]), na.rm = TRUE)
  }, numeric(1)),
  maximum_absolute_difference = vapply(metrics, function(metric) {
    max(abs(generated[[metric]] - reference[[metric]]), na.rm = TRUE)
  }, numeric(1))
)
print(comparison, row.names = FALSE, digits = 8)

report_dir <- dirname(generated_file)
report_file <- file.path(report_dir, "reference_comparison.tsv")
data.table::fwrite(comparison, report_file, sep = "\t")

if (strict) {
  if (any(comparison$maximum_absolute_difference > 1e-10)) {
    stop("Strict comparison failed: the regenerated statistics are not byte-equivalent.",
         call. = FALSE)
  }
  message("Strict comparison passed: regenerated statistics match the reference snapshot.")
} else {
  thresholds <- c(logFC = 0.999, logCPM = 0.999999999, F = 0.98,
                  PValue = 0.98, FDR = 0.98)
  correlations <- stats::setNames(comparison$correlation, comparison$metric)
  if (comparison$maximum_absolute_difference[comparison$metric == "logCPM"] > 1e-10 ||
      any(correlations[names(thresholds)] < thresholds)) {
    stop("Generated statistics are not consistent with the curated reference snapshot.",
         call. = FALSE)
  }
  message(
    "Consistency comparison passed. Keys and logCPM agree; inferential statistics ",
    "show the small version-dependent drift documented in docs/numerical-reproducibility.md."
  )
}
message("Wrote comparison report to:\n", report_file)
