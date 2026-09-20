#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "common.R"))
repository_root <- script_repository_root()
load_workflow(repository_root)
arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))

analysis_sheet <- arguments$`analysis-sheet`
analysis_id <- arguments$`analysis-id`

if (is.null(analysis_sheet) || is.null(analysis_id)) {
  stop(
    "Required arguments: --analysis-sheet=/path/to/analyses.csv ",
    "and --analysis-id=ID",
    call. = FALSE
  )
}

analyses <- read_analysis_sheet(analysis_sheet)
config <- analysis_config(analyses, analysis_id)
output_dir <- if (is.null(arguments$`output-dir`)) {
  file.path(repository_root, "results", config$analysis_id)
} else {
  arguments$`output-dir`
}
contrasts_file <- if (is.null(arguments$contrasts)) {
  config$contrasts
} else {
  arguments$contrasts
}

run_dge_analysis(
  config,
  output_dir,
  contrasts_file,
  config$workpackage
)
