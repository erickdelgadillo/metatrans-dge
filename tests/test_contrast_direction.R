#!/usr/bin/env Rscript
# Check orientation of the numerator-versus-denominator statistical contrast.
file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "helpers.R"))

design <- matrix(0, nrow = 4, ncol = 2,
                 dimnames = list(NULL, c("control", "treatment")))
positive <- contrast_vector(design, "treatment", "control")
stopifnot(identical(unname(positive), c(-1, 1)))
stopifnot(identical(names(positive), c("control", "treatment")))

negative <- contrast_vector(design, "control", "treatment")
stopifnot(identical(unname(negative), c(1, -1)))
expect_error(contrast_vector(design, "unknown", "control"), "Design groups are missing")
pass("contrast direction and missing groups")
