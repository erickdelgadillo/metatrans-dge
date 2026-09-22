#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(
  file.path(
    dirname(normalizePath(sub("^--file=", "", file_argument))),
    "helpers.R"
  )
)

counts <- data.frame(
  feature_id = c("feature_1", "feature_1", "feature_2"),
  sample_id = c("sample_1", "sample_2", "sample_1"),
  count = c(3L, 1L, 2L)
)
metadata <- data.frame(
  sample_id = c("sample_2", "sample_1"),
  group = c("group_2", "group_1")
)
original_counts <- counts
original_metadata <- metadata

prepared <- build_count_matrix(counts, metadata)
stopifnot(
  identical(dim(prepared$counts), c(2L, 2L)),
  identical(colnames(prepared$counts), metadata$sample_id),
  identical(rownames(prepared$samples), metadata$sample_id),
  prepared$counts["feature_2", "sample_2"] == 0L,
  prepared$counts["feature_1", "sample_1"] == 3L,
  identical(counts, original_counts),
  identical(metadata, original_metadata)
)

mismatched <- counts
mismatched$sample_id[mismatched$sample_id == "sample_2"] <- "unknown_sample"
expect_error(
  build_count_matrix(mismatched, metadata),
  "Count/metadata sample mismatch"
)

pass("canonical count-matrix construction")
