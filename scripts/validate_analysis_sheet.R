#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "common.R"))
repository_root <- script_repository_root()
load_workflow(repository_root)
arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))

input <- arguments$input
if (is.null(input)) {
  stop("Required argument: --input=/path/to/analyses.csv", call. = FALSE)
}

analyses <- read_analysis_sheet(input)
for (index in seq_len(nrow(analyses))) {
  message(
    "OK  ",
    analyses$analysis_id[[index]],
    " (",
    analyses$organism[[index]],
    ", ",
    analyses$workpackage[[index]],
    ")"
  )
}
message("Validated ", nrow(analyses), " analyses.")
