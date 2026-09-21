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
  "counts",
  "metadata",
  "contrasts",
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

source(file.path(repository_root, "R", "counts.R"))
source(file.path(repository_root, "R", "metadata.R"))
source(file.path(repository_root, "R", "contrasts.R"))
source(file.path(repository_root, "R", "io.R"))
source(file.path(repository_root, "R", "edgeR_workflow.R"))

assert_packages(
  c(
    "data.table",
    "edgeR"
  )
)

input_files <- c(
  counts = args$counts,
  metadata = args$metadata,
  contrasts = args$contrasts
)

missing_files <- input_files[
  !file.exists(input_files)
]

if (length(missing_files)) {
  stop(
    "Input files do not exist: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

counts <- data.table::fread(
  args$counts,
  data.table = FALSE
)

metadata <- data.table::fread(
  args$metadata,
  data.table = FALSE
)

contrasts <- read_contrasts(
  args$contrasts
)

prepared <- build_count_matrix(
  counts,
  metadata
)

statistics <- run_edger(
  prepared$counts,
  prepared$samples,
  "feature_id",
  contrasts
)

output_dir <- dirname(args$output)

if (!dir.exists(output_dir)) {
  dir.create(
    output_dir,
    recursive = TRUE
  )
}

data.table::fwrite(
  statistics,
  args$output,
  sep = "\t"
)

message(
  "Wrote ",
  format(nrow(statistics), big.mark = ","),
  " DGE rows to:\n",
  normalizePath(args$output)
)