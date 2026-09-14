#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "common.R"))
repository_root <- script_repository_root()
load_workflow(repository_root)
arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))

organism <- arguments$organism
if (is.null(organism)) {
  stop("Required argument: --organism=prokaryotes or --organism=eukaryotes", call. = FALSE)
}
organism <- match.arg(organism, c("prokaryotes", "eukaryotes"))
data_root <- if (is.null(arguments$`data-root`)) default_data_root() else arguments$`data-root`
output_dir <- if (is.null(arguments$`output-dir`)) {
  file.path(repository_root, "results", organism)
} else {
  arguments$`output-dir`
}
run_dge_workflow(organism, data_root, output_dir)
