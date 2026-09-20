#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "common.R"))
repository_root <- script_repository_root()
source(file.path(repository_root, "R", "config.R"))
source(file.path(repository_root, "R", "io.R"))
source(file.path(repository_root, "R", "plotting.R"))
assert_packages(c("arrow", "data.table", "ggplot2"))

arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))
workpackage <- match.arg(
  toupper(if (is.null(arguments$workpackage)) "WP2" else arguments$workpackage),
  c("WP1", "WP2")
)

parse_number <- function(name, default, lower, upper, integer = FALSE) {
  raw_value <- arguments[[name]]
  value <- if (is.null(raw_value)) default else suppressWarnings(as.numeric(raw_value))
  if (length(value) != 1L || !is.finite(value) || value < lower || value > upper ||
      (integer && value != as.integer(value))) {
    stop(
      "--", name, " must be ",
      if (integer) "an integer" else "a number",
      " between ", lower, " and ", upper, ".",
      call. = FALSE
    )
  }
  if (integer) as.integer(value) else value
}

organism_argument <- if (is.null(arguments$organism)) "all" else arguments$organism
organism_argument <- match.arg(
  organism_argument,
  c("all", "prokaryotes", "eukaryotes")
)
organisms <- if (organism_argument == "all") {
  c("prokaryotes", "eukaryotes")
} else {
  organism_argument
}

if (!is.null(arguments$input) && length(organisms) != 1L) {
  stop("--input can only be used with one organism.", call. = FALSE)
}

results_dir <- if (is.null(arguments$`results-dir`)) {
  root <- file.path(repository_root, "results")
  if (workpackage == "WP1") file.path(root, "wp1") else root
} else {
  arguments$`results-dir`
}
fdr_threshold <- parse_number("fdr", 0.05, 0, 1)
logfc_threshold <- parse_number("logfc", 1, 0, Inf)
top_n <- parse_number("top", 10, 1, 100, integer = TRUE)
max_background <- parse_number(
  "max-background", 20000, 100, 100000, integer = TRUE
)

for (organism in organisms) {
  config <- organism_config(organism)
  input_file <- if (is.null(arguments$input)) {
    file.path(results_dir, organism, config$output_name)
  } else {
    arguments$input
  }
  output_dir <- if (is.null(arguments$`output-dir`)) {
    file.path(dirname(input_file), "figures")
  } else if (length(organisms) == 1L) {
    arguments$`output-dir`
  } else {
    file.path(arguments$`output-dir`, organism)
  }

  message("Reading DGE results for ", organism, "...")
  results <- read_dge_results_for_plots(input_file, config$feature_column)
  plot_dge_preview(
    results = results,
    feature_column = config$feature_column,
    organism = organism,
    output_dir = output_dir,
    fdr_threshold = fdr_threshold,
    logfc_threshold = logfc_threshold,
    top_n = top_n,
    max_background = max_background
  )
  rm(results)
  gc(verbose = FALSE)
}

message(workpackage, " DGE preview figures completed.")
