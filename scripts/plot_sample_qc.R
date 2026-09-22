#!/usr/bin/env Rscript

arguments <- commandArgs(
  trailingOnly = TRUE
)

parse_arguments <- function(arguments) {
  values <- list()

  for (argument in arguments) {
    if (
      !startsWith(argument, "--") ||
        !grepl("=", argument, fixed = TRUE)
    ) {
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

    value <- paste(
      parts[-1],
      collapse = "="
    )

    values[[name]] <- value
  }

  values
}

args <- parse_arguments(
  arguments
)

required <- c(
  "input",
  "metadata",
  "outdir"
)

missing <- setdiff(
  required,
  names(args)
)

if (length(missing)) {
  stop(
    "Missing required arguments: ",
    paste(
      paste0("--", missing),
      collapse = ", "
    ),
    call. = FALSE
  )
}

script_argument <- grep(
  "^--file=",
  commandArgs(FALSE),
  value = TRUE
)[[1]]

script_path <- normalizePath(
  sub(
    "^--file=",
    "",
    script_argument
  )
)

repository_root <- normalizePath(
  file.path(
    dirname(script_path),
    ".."
  )
)

source(
  file.path(
    repository_root,
    "R",
    "sample_qc.R"
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
    paste(
      missing_packages,
      collapse = ", "
    ),
    call. = FALSE
  )
}

if (!file.exists(args$input)) {
  stop(
    "Normalized-expression file does not exist: ",
    args$input,
    call. = FALSE
  )
}

if (!file.exists(args$metadata)) {
  stop(
    "Metadata file does not exist: ",
    args$metadata,
    call. = FALSE
  )
}

if (!dir.exists(args$outdir)) {
  dir.create(
    args$outdir,
    recursive = TRUE
  )
}

normalized_expression <- data.table::fread(
  args$input,
  data.table = TRUE
)

metadata <- data.table::fread(
  args$metadata,
  data.table = TRUE
)

similarity <- compute_sample_similarity(
  normalized_expression
)

mds <- compute_sample_mds(
  similarity$distance
)

mds_output <- file.path(
  args$outdir,
  "sample_mds.png"
)

correlation_output <- file.path(
  args$outdir,
  "sample_correlation.png"
)

plot_sample_mds(
  mds,
  metadata,
  mds_output
)

plot_sample_correlation(
  similarity$correlation,
  metadata,
  correlation_output
)

message(
  "Sample QC complete."
)
