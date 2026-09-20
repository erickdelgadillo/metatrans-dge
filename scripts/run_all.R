#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "common.R"))
repository_root <- script_repository_root()
arguments <- parse_arguments(commandArgs(trailingOnly = TRUE))
workpackage <- match.arg(
  toupper(if (is.null(arguments$workpackage)) "WP2" else arguments$workpackage),
  c("WP1", "WP2")
)
data_root <- if (is.null(arguments$`data-root`)) {
  Sys.getenv("INTERES_DATA_ROOT", unset = "/home/erick/Data/ProjectsData/marine-p-deficiency-metat/data")
} else {
  arguments$`data-root`
}
output_root <- if (is.null(arguments$`output-dir`)) {
  root <- file.path(repository_root, "results")
  if (workpackage == "WP1") file.path(root, "wp1") else root
} else {
  arguments$`output-dir`
}

runner <- file.path(repository_root, "scripts", "run_dge.R")
for (organism in c("prokaryotes", "eukaryotes")) {
  contrasts_file <- if (is.null(arguments$contrasts)) {
    default_contrasts_file(repository_root, workpackage, organism)
  } else {
    arguments$contrasts
  }

  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(runner), paste0("--organism=", organism),
      paste0("--data-root=", shQuote(data_root)),
      paste0("--output-dir=", shQuote(file.path(output_root, organism))),
      paste0("--contrasts=", shQuote(contrasts_file)),
      paste0("--workpackage=", workpackage))
  )
  if (status != 0L) stop("DGE workflow failed for ", organism, call. = FALSE)
}
