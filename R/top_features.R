select_top_features <- function(
  results,
  fdr_threshold = 0.05,
  logfc_threshold = 1,
  top_n = 40L
) {
  results <- data.table::copy(
    data.table::as.data.table(results)
  )

  required <- c(
    "feature_id",
    "contrast",
    "logFC",
    "logCPM",
    "PValue",
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

  if (!is.numeric(top_n) || length(top_n) != 1L || top_n < 1) {
    stop(
      "top_n must be a positive integer.",
      call. = FALSE
    )
  }

  top_n <- as.integer(top_n)

  results <- results[
    FDR <= fdr_threshold &
    abs(logFC) >= logfc_threshold
  ]

  if (!nrow(results)) {
    return(
      results[
        ,
        c(
          "contrast",
          "feature_id",
          "logFC",
          "logCPM",
          "PValue",
          "FDR"
        ),
        with = FALSE
      ]
    )
  }

  results[
    ,
    direction := data.table::fifelse(
      logFC > 0,
      "up",
      "down"
    )
  ]

  results[
    ,
    absolute_logfc := abs(logFC)
  ]

  data.table::setorderv(
    results,
    c(
      "contrast",
      "FDR",
      "absolute_logfc"
    ),
    c(
      1L,
      1L,
      -1L
    )
  )

  top <- results[
    ,
    utils::head(.SD, top_n),
    by = contrast
  ]

  top[
    ,
    rank := seq_len(.N),
    by = contrast
  ]

  top[
    ,
    .(
      contrast,
      rank,
      feature_id,
      direction,
      logFC,
      logCPM,
      PValue,
      FDR
    )
  ]
}