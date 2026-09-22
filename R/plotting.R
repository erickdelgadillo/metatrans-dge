dge_plot_theme <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(colour = "grey30"),
      legend.position = "bottom"
    )
}

read_dge_results_for_plots <- function(path) {
  if (!file.exists(path)) {
    stop(
      "DGE result does not exist: ",
      path,
      call. = FALSE
    )
  }

  results <- data.table::fread(
    path,
    data.table = TRUE
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
      "DGE result is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!nrow(results)) {
    stop(
      "DGE result contains no rows: ",
      path,
      call. = FALSE
    )
  }

  if (anyNA(results[, ..required])) {
    stop(
      "DGE plotting columns cannot contain missing values.",
      call. = FALSE
    )
  }

  if (
    any(!is.finite(results$logFC)) ||
      any(!is.finite(results$logCPM))
  ) {
    stop(
      "logFC and logCPM must contain finite values.",
      call. = FALSE
    )
  }

  if (
    any(results$PValue < 0 | results$PValue > 1) ||
      any(results$FDR < 0 | results$FDR > 1)
  ) {
    stop(
      "PValue and FDR must be between zero and one.",
      call. = FALSE
    )
  }

  keys <- results[, .(feature_id, contrast)]

  if (anyDuplicated(keys)) {
    stop(
      "DGE result contains duplicated feature/contrast rows.",
      call. = FALSE
    )
  }

  results
}

sample_dge_background <- function(results, max_background) {
  foreground <- results[direction != "Not significant"]
  background <- results[direction == "Not significant"]
  if (nrow(background)) {
    background <- background[, {
      count <- min(.N, max_background)
      positions <- unique(round(seq.int(1, .N, length.out = count)))
      .SD[positions]
    }, by = contrast]
  }
  data.table::rbindlist(list(background, foreground), use.names = TRUE)
}

save_dge_plot <- function(plot, path, width, height) {
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 180,
    bg = "white"
  )
  message("Wrote ", path)
  path
}

plot_dge_results <- function(
  results,
  output_dir,
  fdr_threshold = 0.05,
  logfc_threshold = 1
) {
  results <- data.table::copy(
    data.table::as.data.table(results)
  )

  dir.create(
    output_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )

  results[, direction := data.table::fcase(
    FDR <= fdr_threshold & logFC >= logfc_threshold, "Up",
    FDR <= fdr_threshold & logFC <= -logfc_threshold, "Down",
    default = "Not significant"
  )]

  results[, direction := factor(
    direction,
    levels = c(
      "Down",
      "Not significant",
      "Up"
    )
  )]

  contrast_levels <- unique(results$contrast)

  results[, contrast := factor(
    contrast,
    levels = contrast_levels
  )]

  results[, neg_log10_fdr := -log10(
    pmax(FDR, .Machine$double.xmin)
  )]

  colours <- c(
    "Down" = "#2C7BB6",
    "Not significant" = "#BDBDBD",
    "Up" = "#D7191C"
  )

  subtitle <- paste0(
    "FDR <= ",
    fdr_threshold,
    " and |log2 fold change| >= ",
    logfc_threshold
  )

  volcano <- ggplot2::ggplot(
    results,
    ggplot2::aes(
      x = logFC,
      y = neg_log10_fdr,
      colour = direction
    )
  ) +
    ggplot2::geom_point(
      size = 0.8,
      alpha = 0.6
    ) +
    ggplot2::geom_vline(
      xintercept = c(
        -logfc_threshold,
        logfc_threshold
      ),
      linetype = "dashed",
      linewidth = 0.35
    ) +
    ggplot2::geom_hline(
      yintercept = -log10(fdr_threshold),
      linetype = "dashed",
      linewidth = 0.35
    ) +
    ggplot2::facet_wrap(
      ~contrast,
      scales = "free_x"
    ) +
    ggplot2::scale_colour_manual(
      values = colours,
      drop = FALSE
    ) +
    ggplot2::labs(
      title = "Differential-expression volcano plot",
      subtitle = subtitle,
      x = "log2 fold change",
      y = expression(-log[10](FDR)),
      colour = NULL
    ) +
    dge_plot_theme()

  ma <- ggplot2::ggplot(
    results,
    ggplot2::aes(
      x = logCPM,
      y = logFC,
      colour = direction
    )
  ) +
    ggplot2::geom_point(
      size = 0.8,
      alpha = 0.6
    ) +
    ggplot2::geom_hline(
      yintercept = 0,
      linewidth = 0.35
    ) +
    ggplot2::geom_hline(
      yintercept = c(
        -logfc_threshold,
        logfc_threshold
      ),
      linetype = "dashed",
      linewidth = 0.35
    ) +
    ggplot2::facet_wrap(
      ~contrast,
      scales = "free"
    ) +
    ggplot2::scale_colour_manual(
      values = colours,
      drop = FALSE
    ) +
    ggplot2::labs(
      title = "Differential-expression MA plot",
      subtitle = subtitle,
      x = "Average expression (logCPM)",
      y = "log2 fold change",
      colour = NULL
    ) +
    dge_plot_theme()

  volcano_path <- file.path(
    output_dir,
    "volcano.png"
  )

  ma_path <- file.path(
    output_dir,
    "ma.png"
  )

  save_dge_plot(
    volcano,
    volcano_path,
    10,
    7
  )

  save_dge_plot(
    ma,
    ma_path,
    10,
    7
  )

  invisible(
    c(
      volcano = volcano_path,
      ma = ma_path
    )
  )
}
