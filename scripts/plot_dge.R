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
  args$outdir
)