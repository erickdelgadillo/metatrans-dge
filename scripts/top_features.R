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
  "output"
)

missing <- setdiff(required, names(args))

if (length(missing)) {
  stop(
    "Missing required arguments: ",
    paste(paste0("--", missing), collapse = ", "),
    call. = FALSE
  )
}

parse_numeric <- function(args, name, default) {
  value <- args[[name]]

  if (is.null(value)) {
    return(default)
  }

  numeric_value <- suppressWarnings(as.numeric(value))

  if (
    length(numeric_value) != 1L ||
      is.na(numeric_value) ||
      !is.finite(numeric_value)
  ) {
    stop(
      "--", name, " must be numeric; received: ", value,
      call. = FALSE
    )
  }

  numeric_value
}

fdr_threshold <- parse_numeric(
  args,
  "fdr",
  0.05
)

logfc_threshold <- parse_numeric(
  args,
  "logfc",
  1
)

top_n <- parse_numeric(
  args,
  "top_n",
  40
)

if (fdr_threshold <= 0 || fdr_threshold > 1) {
  stop(
    "--fdr must satisfy 0 < fdr <= 1.",
    call. = FALSE
  )
}

if (logfc_threshold < 0) {
  stop(
    "--logfc must satisfy logfc >= 0.",
    call. = FALSE
  )
}

if (top_n < 1 || top_n %% 1 != 0) {
  stop(
    "--top_n must be a positive integer.",
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
    "top_features.R"
  )
)

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop(
    "Missing required R package: data.table",
    call. = FALSE
  )
}

if (!file.exists(args$input)) {
  stop(
    "DGE result does not exist: ",
    args$input,
    call. = FALSE
  )
}

results <- data.table::fread(
  args$input,
  data.table = TRUE
)

top <- select_top_features(
  results,
  fdr_threshold = fdr_threshold,
  logfc_threshold = logfc_threshold,
  top_n = as.integer(top_n)
)

output_dir <- dirname(args$output)

if (!dir.exists(output_dir)) {
  dir.create(
    output_dir,
    recursive = TRUE
  )
}

data.table::fwrite(
  top,
  args$output,
  sep = "\t"
)

message(
  "Wrote ",
  nrow(top),
  " top differential features to:\n",
  normalizePath(args$output)
)
