plot_dge_summary <- function(
  summary,
  output_path
) {
  summary <- data.table::copy(
    data.table::as.data.table(summary)
  )

  required <- c(
    "contrast",
    "up",
    "down"
  )

  missing <- setdiff(
    required,
    names(summary)
  )

  if (length(missing)) {
    stop(
      "DGE summary is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  long <- data.table::melt(
    summary,
    id.vars = "contrast",
    measure.vars = c("up", "down"),
    variable.name = "direction",
    value.name = "features"
  )

  long[, direction := factor(
    direction,
    levels = c("down", "up")
  )]

  plot <- ggplot2::ggplot(
    long,
    ggplot2::aes(
      x = contrast,
      y = features,
      fill = direction
    )
  ) +
    ggplot2::geom_col(
      position = "dodge"
    ) +
    ggplot2::labs(
      title = "Differentially expressed features",
      x = NULL,
      y = "Number of features",
      fill = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      axis.text.x = ggplot2::element_text(
        angle = 35,
        hjust = 1
      )
    )

  ggplot2::ggsave(
    filename = output_path,
    plot = plot,
    width = 10,
    height = 7,
    units = "in",
    dpi = 180,
    bg = "white"
  )

  message(
    "Wrote ",
    output_path
  )

  invisible(output_path)
}
