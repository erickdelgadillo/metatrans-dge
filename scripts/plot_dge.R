#!/usr/bin/env Rscript

arguments <- commandArgs(trailingOnly = TRUE)

parse_arguments <- function(arguments) {
  values <- list()

  for (argument in arguments) {
    if (!startsWith(argument, "--") || !grepl("=", argument, fixed = TRUE)) {
      stop(
        "Arguments must use --name=value syntax: ",
        argument,
        call. = FALSE
      )
    }

    parts <- strsplit(
      sub("^--", "", argument),
      "=",
      fixed = TRUE
    )[[1]]

    name <- parts[[1]]
    value <- paste(parts[-1], collapse = "=")

    values[[name]] <- value
  }

  values
}

args <- parse_arguments(arguments)

parse_threshold <- function(args, name, default) {
  value <- args[[name]]

  if (is.null(value)) {
    return(default)
  }

  numeric_value <- suppressWarnings(as.numeric(value))

  if (length(numeric_value) != 1L || is.na(numeric_value) || !is.finite(numeric_value)) {
    stop(
      "--", name, " must be numeric; received: ", value,
      call. = FALSE
    )
  }

  numeric_value
}

fdr_threshold <- parse_threshold(args, "fdr", 0.05)
logfc_threshold <- parse_threshold(args, "logfc", 1)

if (fdr_threshold <= 0 || fdr_threshold > 1) {
  stop("--fdr must satisfy 0 < fdr <= 1.", call. = FALSE)
}

if (logfc_threshold < 0) {
  stop("--logfc must satisfy logfc >= 0.", call. = FALSE)
}

required <- c(
  "input",
  "outdir"
)

missing <- setdiff(required, names(args))

if (length(missing)) {
  stop(
    "Missing required arguments: ",
    paste(paste0("--", missing), collapse = ", "),
    call. = FALSE
  )
}

script_argument <- grep(
  "^--file=",
  commandArgs(FALSE),
  value = TRUE
)[[1]]

script_path <- normalizePath(
  sub("^--file=", "", script_argument)
)

repository_root <- normalizePath(
  file.path(dirname(script_path), "..")
)

source(
  file.path(
    repository_root,
    "R",
    "plotting.R"
  )
)

required_packages <- c(
  "data.table",
  "ggplot2"
)

missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(missing_packages)) {
  stop(
    "Missing required R packages: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

results <- read_dge_results_for_plots(
  args$input
)

plot_dge_results(
  results,
  args$outdir,
  fdr_threshold = fdr_threshold,
  logfc_threshold = logfc_threshold
)
