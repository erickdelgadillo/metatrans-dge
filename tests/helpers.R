test_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
repository_root <- normalizePath(
  file.path(dirname(sub("^--file=", "", test_file)), "..")
)

source(file.path(repository_root, "scripts", "common.R"))
load_workflow(repository_root)

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
