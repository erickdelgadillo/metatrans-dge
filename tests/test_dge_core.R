source("tests/helpers.R")

counts <- data.table::fread(
  file.path(
    repository_root,
    "tests",
    "data",
    "canonical",
    "counts.tsv"
  ),
  data.table = FALSE
)

metadata <- data.table::fread(
  file.path(
    repository_root,
    "tests",
    "data",
    "canonical",
    "metadata.tsv"
  ),
  data.table = FALSE
)

contrasts <- read_contrasts(
  file.path(
    repository_root,
    "tests",
    "data",
    "canonical",
    "contrasts.tsv"
  )
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

required_columns <- c(
  "feature_id",
  "logFC",
  "logCPM",
  "F",
  "PValue",
  "FDR",
  "contrast"
)

missing <- setdiff(
  required_columns,
  names(statistics)
)

if (length(missing)) {
  stop(
    "DGE output is missing columns: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

stopifnot(
  nrow(statistics) > 0
)

stopifnot(
  all(statistics$contrast == "treatment_vs_control")
)

stopifnot(
  all(is.finite(statistics$logFC))
)

stopifnot(
  all(statistics$PValue >= 0 & statistics$PValue <= 1)
)

stopifnot(
  all(statistics$FDR >= 0 & statistics$FDR <= 1)
)

pass("canonical DGE core")
