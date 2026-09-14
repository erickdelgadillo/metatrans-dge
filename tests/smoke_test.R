#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
repository_root <- normalizePath(file.path(dirname(sub("^--file=", "", file_argument)), ".."))
source(file.path(repository_root, "R", "config.R"))
source(file.path(repository_root, "R", "edgeR_workflow.R"))

stopifnot(nrow(wp2_contrasts()) == 6L)
design <- diag(3)
colnames(design) <- c("A", "B", "C")
observed <- contrast_vector(design, "C", "A")
stopifnot(identical(unname(observed), c(-1, 0, 1)))
failure <- try(contrast_vector(design, "D", "A"), silent = TRUE)
stopifnot(inherits(failure, "try-error"))
message("Smoke test passed.")
