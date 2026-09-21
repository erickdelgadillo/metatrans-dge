test_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
repository_root <- normalizePath(
  file.path(dirname(sub("^--file=", "", test_file)), "..")
)

source(file.path(repository_root, "R", "counts.R"))
source(file.path(repository_root, "R", "metadata.R"))
source(file.path(repository_root, "R", "contrasts.R"))
source(file.path(repository_root, "R", "io.R"))
source(file.path(repository_root, "R", "edgeR_workflow.R"))

expect_error <- function(expression, pattern = NULL) {
  error <- tryCatch(
    {
      force(expression)
      NULL
    },
    error = identity
  )

  if (is.null(error)) {
    stop("Expected an error, but the expression succeeded.", call. = FALSE)
  }

  if (!is.null(pattern) && !grepl(pattern, conditionMessage(error), fixed = TRUE)) {
    stop(
      "Expected error containing '",
      pattern,
      "', got: ",
      conditionMessage(error),
      call. = FALSE
    )
  }

  invisible(error)
}

pass <- function(name) {
  message("PASS  ", name)
}
