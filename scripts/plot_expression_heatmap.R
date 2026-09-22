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
  "output"
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
    "expression_heatmap.R"
  )
)

if (
  !requireNamespace(
    "data.table",
    quietly = TRUE
  )
) {
  stop(
    "Missing required R package: data.table",
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

normalized_expression <- data.table::fread(
  args$input,
  data.table = TRUE
)

metadata <- data.table::fread(
  args$metadata,
  data.table = TRUE
)

plot_expression_heatmap(
  normalized_expression,
  metadata,
  args$output
)
