#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(
  file.path(
    dirname(normalizePath(sub("^--file=", "", file_argument))),
    "helpers.R"
  )
)

metadata <- data.frame(
  sample_id = c("sample_1", "sample_2"),
  group = c("group_1", "group_2")
)
stopifnot(identical(validate_sample_metadata(metadata), metadata))

expect_error(
  validate_sample_metadata(metadata[, "group", drop = FALSE]),
  "missing required columns: sample_id"
)
expect_error(validate_sample_metadata(metadata[0, ]), "contains no samples")
expect_error(
  validate_sample_metadata(transform(metadata, sample_id = c("", "sample_2"))),
  "Sample IDs cannot be missing or empty"
)
expect_error(
  validate_sample_metadata(transform(metadata, sample_id = c(NA, "sample_2"))),
  "Sample IDs cannot be missing or empty"
)
expect_error(
  validate_sample_metadata(transform(metadata, group = c("", "group_2"))),
  "Sample groups cannot be missing or empty"
)
expect_error(
  validate_sample_metadata(transform(metadata, sample_id = "sample_1")),
  "Sample IDs must be unique"
)

pass("canonical metadata validation")
