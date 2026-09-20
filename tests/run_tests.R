#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
tests_dir <- dirname(normalizePath(sub("^--file=", "", file_argument)))
test_files <- sort(list.files(
  tests_dir,
  pattern = "^test_.*\\.R$",
  full.names = TRUE
))

if (!length(test_files)) {
  stop("No test files found.", call. = FALSE)
}

for (test_file in test_files) {
  message("RUN   ", basename(test_file))
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", shQuote(test_file))
  )

  if (status != 0L) {
    stop("Test failed: ", basename(test_file), call. = FALSE)
  }
}

message("All ", length(test_files), " test files passed.")
