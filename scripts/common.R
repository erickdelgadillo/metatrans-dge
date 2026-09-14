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

load_workflow <- function(repository_root) {
  source(file.path(repository_root, "R", "config.R"))
  source(file.path(repository_root, "R", "io.R"))
  source(file.path(repository_root, "R", "edgeR_workflow.R"))
}
