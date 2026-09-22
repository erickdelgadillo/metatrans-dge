source("tests/helpers.R")

dge_output <- tempfile(
  fileext = ".tsv.gz"
)

normalized_output <- tempfile(
  fileext = ".tsv.gz"
)

script <- file.path(
  repository_root,
  "scripts",
  "run_dge.R"
)

counts <- file.path(
  repository_root,
  "tests",
  "data",
  "canonical",
  "counts.tsv"
)

metadata_file <- file.path(
  repository_root,
  "tests",
  "data",
  "canonical",
  "metadata.tsv"
)

contrasts <- file.path(
  repository_root,
  "tests",
  "data",
  "canonical",
  "contrasts.tsv"
)

status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "--vanilla",
    shQuote(script),
    paste0("--counts=", shQuote(counts)),
    paste0("--metadata=", shQuote(metadata_file)),
    paste0("--contrasts=", shQuote(contrasts)),
    paste0("--output=", shQuote(dge_output)),
    paste0(
      "--normalized-output=",
      shQuote(normalized_output)
    )
  )
)

if (status != 0L) {
  stop(
    "Normalized-expression CLI execution failed.",
    call. = FALSE
  )
}

if (!file.exists(normalized_output)) {
  stop(
    "Normalized-expression output was not created.",
    call. = FALSE
  )
}

normalized <- data.table::fread(
  normalized_output,
  data.table = FALSE
)

dge <- data.table::fread(
  dge_output,
  data.table = FALSE
)

metadata <- data.table::fread(
  metadata_file,
  data.table = FALSE
)

expected_columns <- c(
  "feature_id",
  metadata$sample_id
)

stopifnot(
  identical(
    names(normalized),
    expected_columns
  )
)

stopifnot(
  nrow(normalized) > 0
)

stopifnot(
  !anyDuplicated(normalized$feature_id)
)

stopifnot(
  nrow(normalized) ==
    length(unique(dge$feature_id))
)

expression_columns <- setdiff(
  names(normalized),
  "feature_id"
)

stopifnot(
  all(
    vapply(
      normalized[expression_columns],
      is.numeric,
      logical(1)
    )
  )
)

stopifnot(
  all(
    is.finite(
      as.matrix(
        normalized[expression_columns]
      )
    )
  )
)

pass("normalized expression output")