#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
repository_root <- normalizePath(file.path(dirname(sub("^--file=", "", file_argument)), ".."))
source(file.path(repository_root, "R", "config.R"))
source(file.path(repository_root, "R", "metadata.R"))
source(file.path(repository_root, "R", "counts.R"))
source(file.path(repository_root, "R", "io.R"))
source(file.path(repository_root, "R", "edgeR_workflow.R"))

contrasts <- read_contrasts(
  file.path(repository_root, "config", "contrasts", "interes_wp2.tsv")
)
stopifnot(nrow(contrasts) == 6L)
stopifnot(
  identical(
    names(contrasts),
    c("contrast", "numerator", "denominator", "comparison", "time")
  )
)
design <- diag(3)
colnames(design) <- c("A", "B", "C")
observed <- contrast_vector(design, "C", "A")
stopifnot(identical(unname(observed), c(-1, 0, 1)))
failure <- try(contrast_vector(design, "D", "A"), silent = TRUE)
stopifnot(inherits(failure, "try-error"))

counts <- data.frame(
  feature_id = c("feature_1", "feature_1", "feature_2"),
  sample_id = c("sample_1", "sample_2", "sample_1"),
  count = c(3L, 1L, 2L)
)
metadata <- data.frame(
  sample_id = c("sample_2", "sample_1"),
  group = c("group_2", "group_1")
)
prepared <- build_count_matrix(counts, metadata)
stopifnot(identical(colnames(prepared$counts), metadata$sample_id))
stopifnot(identical(rownames(prepared$samples), metadata$sample_id))
stopifnot(prepared$counts["feature_2", "sample_2"] == 0L)
stopifnot(prepared$counts["feature_1", "sample_1"] == 3L)

mismatched <- counts
mismatched$sample_id <- "unknown_sample"
failure <- try(build_count_matrix(mismatched, metadata), silent = TRUE)
stopifnot(inherits(failure, "try-error"))

message("Smoke test passed.")
