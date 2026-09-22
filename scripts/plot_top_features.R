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

    values[[parts[[1]]]] <- paste(parts[-1], collapse = "=")
  }

  values
}

args <- parse_arguments(arguments)

required <- c("input", "output")
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
    "top_features_plot.R"
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

if (!file.exists(args$input)) {
  stop(
    "Top-features table does not exist: ",
    args$input,
    call. = FALSE
  )
}

top_features <- data.table::fread(
  args$input,
  data.table = TRUE
)

plot_top_features(
  top_features,
  args$output
)
