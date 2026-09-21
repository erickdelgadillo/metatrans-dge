source("tests/helpers.R")
source(file.path(repository_root, "R", "summary.R"))

results <- data.table::data.table(
  contrast = c(
    "A_vs_B",
    "A_vs_B",
    "A_vs_B",
    "A_vs_B"
  ),
  logFC = c(
    2,
    -2,
    0.5,
    1.5
  ),
  FDR = c(
    0.01,
    0.01,
    0.01,
    0.2
  )
)

summary <- summarize_dge(
  results,
  fdr_threshold = 0.05,
  logfc_threshold = 1
)

stopifnot(
  nrow(summary) == 1
)

stopifnot(
  summary$contrast == "A_vs_B"
)

stopifnot(
  summary$up == 1
)

stopifnot(
  summary$down == 1
)

stopifnot(
  summary$not_significant == 2
)

stopifnot(
  summary$total == 4
)

pass("canonical DGE summary")