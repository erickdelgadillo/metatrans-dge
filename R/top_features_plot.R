plot_top_features <- function(
  top_features,
  output_path
) {
  top_features <- data.table::copy(
    data.table::as.data.table(top_features)
  )

  required <- c(
    "contrast",
    "feature_id",
    "direction",
    "logFC",
    "FDR"
  )

  missing <- setdiff(required, names(top_features))

  if (length(missing)) {
    stop(
      "Top features are missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!nrow(top_features)) {
    stop(
      "Top features table contains no rows.",
      call. = FALSE
    )
  }

  top_features[
    ,
    neg_log10_fdr := -log10(
      pmax(FDR, .Machine$double.xmin)
    )
  ]

  top_features[
    ,
    feature_key := paste(
      contrast,
      feature_id,
      sep = "__"
    )
  ]

  top_features[
    ,
    feature_key := factor(
      feature_key,
      levels = unique(
        feature_key[order(logFC)]
      )
    )
  ]

  labels <- stats::setNames(
    top_features$feature_id,
    as.character(top_features$feature_key)
  )

  plot <- ggplot2::ggplot(
    top_features,
    ggplot2::aes(
      x = logFC,
      y = feature_key,
      colour = direction,
      size = neg_log10_fdr
    )
  ) +
    ggplot2::geom_vline(
      xintercept = 0,
      linewidth = 0.35
    ) +
    ggplot2::geom_point(
      alpha = 0.8
    ) +
    ggplot2::facet_wrap(
      ~contrast,
      scales = "free_y"
    ) +
    ggplot2::scale_y_discrete(
      labels = function(value) labels[value]
    ) +
    ggplot2::labs(
      title = "Top differential features",
      x = "log2 fold change",
      y = NULL,
      colour = NULL,
      size = expression(-log[10](FDR))
    ) +
    ggplot2::theme_minimal(
      base_size = 11
    ) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      strip.text = ggplot2::element_text(face = "bold")
    )

  ggplot2::ggsave(
    filename = output_path,
    plot = plot,
    width = 14,
    height = 12,
    units = "in",
    dpi = 180,
    bg = "white"
  )

  message("Wrote ", output_path)

  invisible(output_path)
}
