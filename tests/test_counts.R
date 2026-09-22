#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(
  file.path(
    dirname(normalizePath(sub("^--file=", "", file_argument))),
    "helpers.R"
  )
)

counts <- data.frame(
  feature_id = c("feature_1", "feature_2"),
  sample_id = c("sample_1", "sample_1"),
  count = c(3L, 1L)
)
stopifnot(identical(validate_counts(counts), counts))

expect_error(
  validate_counts(counts[, -1, drop = FALSE]),
  "missing required columns: feature_id"
)
expect_error(validate_counts(counts[0, ]), "contain no observations")
expect_error(
  validate_counts(transform(counts, feature_id = c("", "feature_2"))),
  "Feature IDs cannot be missing or empty"
)
expect_error(
  validate_counts(transform(counts, sample_id = c(NA, "sample_1"))),
  "Sample IDs cannot be missing or empty"
)
expect_error(
  validate_counts(transform(counts, count = as.character(count))),
  "Counts must be numeric"
)
expect_error(
  validate_counts(transform(counts, count = c(Inf, 1))),
  "Counts must be finite"
)
expect_error(
  validate_counts(transform(counts, count = c(-1, 1))),
  "Counts must be non-negative"
)
expect_error(
  validate_counts(transform(counts, count = c(0.5, 1))),
  "Counts must be integers"
)
expect_error(
  validate_counts(rbind(counts[1, ], counts[1, ])),
  "Feature/sample combinations must be unique"
)

pass("canonical count validation")
