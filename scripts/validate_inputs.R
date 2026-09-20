#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "common.R"))
repository_root <- script_repository_root()
load_workflow(repository_root)
assert_packages(c("data.table", "digest"))
arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))
workpackage <- match.arg(
  toupper(if (is.null(arguments$workpackage)) "WP2" else arguments$workpackage),
  c("WP1", "WP2")
)
data_root <- if (is.null(arguments$`data-root`)) default_data_root() else arguments$`data-root`

manifest_files <- file.path(
  repository_root, "config", c("input_SHA256SUMS", "reference_SHA256SUMS")
)
manifest_lines <- unlist(lapply(manifest_files, readLines, warn = FALSE))
manifest_lines <- manifest_lines[nzchar(trimws(manifest_lines))]
manifest <- data.table::rbindlist(lapply(strsplit(manifest_lines, "  ", fixed = TRUE), function(x) {
  data.table::data.table(sha256 = x[[1]], path = x[[2]])
}))

failures <- character()
for (index in seq_len(nrow(manifest))) {
  path <- file.path(data_root, manifest$path[[index]])
  if (!file.exists(path)) {
    failures <- c(failures, paste("missing", manifest$path[[index]]))
    next
  }
  observed <- digest::digest(path, file = TRUE, algo = "sha256")
  if (!identical(observed, manifest$sha256[[index]])) {
    failures <- c(failures, paste("checksum mismatch", manifest$path[[index]]))
  } else {
    message("OK  ", manifest$path[[index]])
  }
}
if (length(failures)) {
  stop("Input validation failed:\n", paste(failures, collapse = "\n"), call. = FALSE)
}

for (organism in c("prokaryotes", "eukaryotes")) {
  config <- organism_config(organism, data_root)
  metadata <- read_sample_metadata(config, workpackage)
  expected <- if (workpackage == "WP1") {
    if (organism == "prokaryotes") 6L else 9L
  } else if (organism == "prokaryotes") {
    18L
  } else {
    17L
  }
  if (nrow(metadata) != expected) {
    stop(organism, " metadata has ", nrow(metadata), " rows; expected ", expected, ".", call. = FALSE)
  }
  contrasts_file <- if (is.null(arguments$contrasts)) {
    default_contrasts_file(repository_root, workpackage, organism)
  } else {
    arguments$contrasts
  }
  contrasts <- read_contrasts(contrasts_file)
  required_groups <- unique(c(contrasts$numerator, contrasts$denominator))
  missing_groups <- setdiff(required_groups, as.character(metadata$group))
  if (length(missing_groups)) {
    stop(organism, " metadata lacks groups: ", paste(missing_groups, collapse = ", "), call. = FALSE)
  }
  message(
    "OK  ",
    organism,
    " ",
    workpackage,
    " metadata design (",
    nrow(metadata),
    " samples)"
  )
}
message("All input and design checks passed.")
