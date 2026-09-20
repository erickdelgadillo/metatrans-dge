#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
script_file <- normalizePath(sub("^--file=", "", file_argument))
source(file.path(dirname(script_file), "common.R"))
arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))

required_arguments <- c(
  "analysis-id",
  "adapter",
  "organism",
  "workpackage",
  "counts",
  "metadata",
  "annotations",
  "contrasts",
  "feature-column",
  "raw-feature-column",
  "output-name",
  "output-dir"
)
missing_arguments <- required_arguments[
  !vapply(required_arguments, function(name) {
    value <- arguments[[name]]
    !is.null(value) && nzchar(value)
  }, logical(1))
]

if (length(missing_arguments)) {
  stop(
    "Missing required arguments: ",
    paste(paste0("--", missing_arguments), collapse = ", "),
    call. = FALSE
  )
}

repository_root <- if (is.null(arguments$`repository-root`)) {
  script_repository_root()
} else {
  normalizePath(arguments$`repository-root`)
}
load_workflow(repository_root)

analysis <- data.frame(
  analysis_id = arguments$`analysis-id`,
  adapter = arguments$adapter,
  organism = arguments$organism,
  workpackage = arguments$workpackage,
  counts = arguments$counts,
  metadata = arguments$metadata,
  annotations = arguments$annotations,
  contrasts = arguments$contrasts,
  feature_column = arguments$`feature-column`,
  raw_feature_column = arguments$`raw-feature-column`,
  output_name = arguments$`output-name`,
  stringsAsFactors = FALSE
)

validate_analysis_sheet(analysis)
config <- analysis_config(analysis, analysis$analysis_id)

run_dge_analysis(
  config,
  arguments$`output-dir`,
  config$contrasts,
  config$workpackage
)
