script_repository_root <- function() {
  file_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (!length(file_argument)) stop("Run this entry point with Rscript.", call. = FALSE)
  script_file <- normalizePath(sub("^--file=", "", file_argument[[1]]))
  normalizePath(file.path(dirname(script_file), ".."))
}
parse_arguments <- function(arguments) {
  parsed <- list()
  for (argument in arguments) {
    if (!grepl("^--[^=]+=", argument)) {
      stop("Arguments must use --name=value syntax: ", argument, call. = FALSE)
    }
    pieces <- strsplit(sub("^--", "", argument), "=", fixed = TRUE)[[1]]
    parsed[[pieces[[1]]]] <- paste(pieces[-1], collapse = "=")
  }
  parsed
}

default_contrasts_file <- function(repository_root, workpackage, organism) {
  workpackage <- match.arg(workpackage, c("WP1", "WP2"))
  organism <- match.arg(organism, c("prokaryotes", "eukaryotes"))

  filename <- if (workpackage == "WP2") {
    "interes_wp2.tsv"
  } else {
    paste0("interes_wp1_", organism, ".tsv")
  }

  file.path(repository_root, "config", "contrasts", filename)
}

default_output_dir <- function(repository_root, workpackage, organism) {
  workpackage <- match.arg(workpackage, c("WP1", "WP2"))
  organism <- match.arg(organism, c("prokaryotes", "eukaryotes"))

  output_root <- file.path(repository_root, "results")
  if (workpackage == "WP1") {
    output_root <- file.path(output_root, "wp1")
  }

  file.path(output_root, organism)
}

load_workflow <- function(repository_root) {
  source(file.path(repository_root, "R", "config.R"))
  source(file.path(repository_root, "R", "metadata.R"))
  source(file.path(repository_root, "R", "counts.R"))
  source(file.path(repository_root, "R", "adapters", "interes.R"))
  source(file.path(repository_root, "R", "io.R"))
  source(file.path(repository_root, "R", "edgeR_workflow.R"))
}
