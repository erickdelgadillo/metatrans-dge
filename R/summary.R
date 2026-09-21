summarize_dge <- function(
  results,
  fdr_threshold = 0.05,
  logfc_threshold = 1
) {
  results <- data.table::copy(
    data.table::as.data.table(results)
  )

  required <- c(
    "contrast",
    "logFC",
    "FDR"
  )

  missing <- setdiff(
    required,
    names(results)
  )

  if (length(missing)) {
    stop(
      "DGE results are missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  results[, direction := data.table::fcase(
    FDR <= fdr_threshold & logFC >= logfc_threshold, "up",
    FDR <= fdr_threshold & logFC <= -logfc_threshold, "down",
    default = "not_significant"
  )]

  summary <- results[
    ,
    .(
      up = sum(direction == "up"),
      down = sum(direction == "down"),
      not_significant = sum(direction == "not_significant"),
      total = .N
    ),
    by = contrast
  ]

  summary[]
}