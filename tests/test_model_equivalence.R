source("tests/helpers.R")

counts <- data.table::fread(
  "tests/data/canonical/counts.tsv",
  data.table = FALSE
)

metadata <- data.table::fread(
  "tests/data/canonical/metadata.tsv",
  data.table = FALSE
)

contrasts <- read_contrasts(
  "tests/data/canonical/contrasts.tsv"
)

prepared <- build_count_matrix(
  counts,
  metadata
)

default_result <- run_edger_analysis(
  prepared$counts,
  prepared$samples,
  "feature_id",
  contrasts
)

explicit_result <- run_edger_analysis(
  prepared$counts,
  prepared$samples,
  "feature_id",
  contrasts,
  model_config = read_model_config("config/model.group.yml")
)

stopifnot(
  identical(
    default_result$statistics,
    explicit_result$statistics
  )
)

stopifnot(
  identical(
    default_result$normalized_expression,
    explicit_result$normalized_expression
  )
)

# Reject unsupported configurations at the analysis boundary.
invalid_config <- default_model_config()
invalid_config$design <- "factorial"

expect_error(
  run_edger_analysis(
    prepared$counts,
    prepared$samples,
    "feature_id",
    contrasts,
    model_config = invalid_config
  ),
  "Unsupported model configuration"
)

pass("default and explicit model equivalence")