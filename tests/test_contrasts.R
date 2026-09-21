source("tests/helpers.R")

contrasts <- read_contrasts(
  file.path(
    repository_root,
    "tests",
    "data",
    "canonical",
    "contrasts.tsv"
  )
)

stopifnot(
  identical(
    names(contrasts)[1:3],
    c("contrast", "numerator", "denominator")
  )
)

stopifnot(nrow(contrasts) == 1)

stopifnot(
  contrasts$contrast[[1]] == "treatment_vs_control"
)

stopifnot(
  contrasts$numerator[[1]] == "treatment"
)

stopifnot(
  contrasts$denominator[[1]] == "control"
)

expect_error(
  read_contrasts("does-not-exist.tsv"),
  "Contrast file does not exist"
)

pass("canonical contrast validation")