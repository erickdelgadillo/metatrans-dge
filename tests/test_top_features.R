source("tests/helpers.R")
source(file.path(repository_root, "R", "top_features.R"))

results <- data.table::data.table(
  feature_id = c(
    "g1", "g2", "g3", "g4", "g5", "g6"
  ),
  contrast = c(
    "A_vs_B", "A_vs_B", "A_vs_B",
    "C_vs_D", "C_vs_D", "C_vs_D"
  ),
  logFC = c(
    3, -2.5, 0.4,
    2.2, -3.1, 1.5
  ),
  logCPM = c(
    8, 7, 6,
    9, 8, 7
  ),
  PValue = c(
    0.001, 0.002, 0.2,
    0.0005, 0.003, 0.01
  ),
  FDR = c(
    0.005, 0.01, 0.3,
    0.002, 0.02, 0.04
  )
)

top <- select_top_features(
  results,
  fdr_threshold = 0.05,
  logfc_threshold = 1,
  top_n = 40
)

stopifnot(
  nrow(top) == 5
)

stopifnot(
  all(top$FDR <= 0.05)
)

stopifnot(
  all(abs(top$logFC) >= 1)
)

stopifnot(
  all(top$direction %in% c("up", "down"))
)

stopifnot(
  all(
    top[
      ,
      .N,
      by = contrast
    ]$N <= 40
  )
)

pass("top differential features")
