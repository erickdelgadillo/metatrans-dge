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

read_dge_results_for_plots <- function(path, feature_column) {
  if (!file.exists(path)) {
    stop("DGE result does not exist: ", path, call. = FALSE)
  }

  results <- data.table::as.data.table(arrow::read_parquet(path))
  required <- c(feature_column, "contrast", "logFC", "logCPM", "PValue", "FDR")
  missing <- setdiff(required, names(results))
  if (length(missing)) {
    stop(
      "DGE result is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  if (!nrow(results)) {
    stop("DGE result contains no rows: ", path, call. = FALSE)
  }
  if (anyNA(results[, ..required])) {
    stop("DGE plotting columns cannot contain missing values.", call. = FALSE)
  }
  if (any(!is.finite(results$logFC)) || any(!is.finite(results$logCPM))) {
    stop("logFC and logCPM must contain finite values.", call. = FALSE)
  }
  if (any(results$PValue < 0 | results$PValue > 1) ||
      any(results$FDR < 0 | results$FDR > 1)) {
    stop("PValue and FDR must be between zero and one.", call. = FALSE)
  }

  keys <- results[, c(feature_column, "contrast"), with = FALSE]
  if (anyDuplicated(keys)) {
    stop("DGE result contains duplicated feature/contrast rows.", call. = FALSE)
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

plot_dge_preview <- function(
  results,
  feature_column,
  organism,
  output_dir,
  fdr_threshold = 0.05,
  logfc_threshold = 1,
  top_n = 10L,
  max_background = 20000L
) {
  results <- data.table::copy(results)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  contrast_levels <- unique(results$contrast)
  results[, direction := data.table::fcase(
    FDR <= fdr_threshold & logFC >= logfc_threshold, "Up",
    FDR <= fdr_threshold & logFC <= -logfc_threshold, "Down",
    default = "Not significant"
  )]
  results[, direction := factor(
    direction,
    levels = c("Down", "Not significant", "Up")
  )]
  results[, contrast := factor(contrast, levels = contrast_levels)]

  colours <- c(
    "Down" = "#2C7BB6",
    "Not significant" = "#BDBDBD",
    "Up" = "#D7191C"
  )
  sampled <- sample_dge_background(results, max_background)
  sampled[, neg_log10_fdr := -log10(pmax(FDR, .Machine$double.xmin))]
  fdr_cap <- max(
    10,
    as.numeric(stats::quantile(sampled$neg_log10_fdr, 0.995, names = FALSE))
  )
  sampled[, displayed_neg_log10_fdr := pmin(neg_log10_fdr, fdr_cap)]

  subtitle <- paste0(
    "Significant: FDR <= ", fdr_threshold,
    " and |log2 fold change| >= ", logfc_threshold,
    ". Positive values indicate higher expression in the numerator."
  )

  volcano <- ggplot2::ggplot(
    sampled,
    ggplot2::aes(x = logFC, y = displayed_neg_log10_fdr, colour = direction)
  ) +
    ggplot2::geom_point(size = 0.45, alpha = 0.45) +
    ggplot2::geom_vline(
      xintercept = c(-logfc_threshold, logfc_threshold),
      linewidth = 0.35,
      linetype = "dashed"
    ) +
    ggplot2::geom_hline(
      yintercept = -log10(fdr_threshold),
      linewidth = 0.35,
      linetype = "dashed"
    ) +
    ggplot2::facet_wrap(~contrast, ncol = 3, scales = "free_x") +
    ggplot2::scale_colour_manual(values = colours, drop = FALSE) +
    ggplot2::labs(
      title = paste("DGE volcano plots —", organism),
      subtitle = subtitle,
      x = "log2 fold change",
      y = expression(-log[10](FDR)),
      colour = NULL,
      caption = paste0(
        "For readability, non-significant points are sampled and FDR values above ",
        signif(fdr_cap, 3), " on the -log10 scale are capped."
      )
    ) +
    dge_plot_theme()

  ma_plot <- ggplot2::ggplot(
    sampled,
    ggplot2::aes(x = logCPM, y = logFC, colour = direction)
  ) +
    ggplot2::geom_point(size = 0.45, alpha = 0.45) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.35) +
    ggplot2::geom_hline(
      yintercept = c(-logfc_threshold, logfc_threshold),
      linewidth = 0.35,
      linetype = "dashed"
    ) +
    ggplot2::facet_wrap(~contrast, ncol = 3, scales = "free") +
    ggplot2::scale_colour_manual(values = colours, drop = FALSE) +
    ggplot2::labs(
      title = paste("DGE MA plots —", organism),
      subtitle = subtitle,
      x = "Average expression (logCPM)",
      y = "log2 fold change",
      colour = NULL,
      caption = "Non-significant points are sampled for readability."
    ) +
    dge_plot_theme()

  directions <- c("Down", "Not significant", "Up")
  summary <- results[, .(features = .N), by = .(contrast, direction)]
  template <- data.table::CJ(
    contrast = contrast_levels,
    direction = directions,
    unique = TRUE
  )
  summary <- merge(template, summary, by = c("contrast", "direction"), all.x = TRUE)
  summary[is.na(features), features := 0L]
  summary[, contrast := factor(contrast, levels = contrast_levels)]
  summary[, direction := factor(direction, levels = directions)]
  data.table::setorder(summary, contrast, direction)

  summary_path <- file.path(output_dir, "dge_significance_summary.tsv")
  data.table::fwrite(summary, summary_path, sep = "\t")
  message("Wrote ", summary_path)

  counts <- ggplot2::ggplot(
    summary,
    ggplot2::aes(x = contrast, y = features, fill = direction)
  ) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = colours, drop = FALSE) +
    ggplot2::scale_y_continuous(labels = function(value) format(value, big.mark = ",")) +
    ggplot2::labs(
      title = paste("Differential-expression calls —", organism),
      subtitle = subtitle,
      x = NULL,
      y = "Number of features",
      fill = NULL
    ) +
    dge_plot_theme() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 35, hjust = 1))

  results[, pvalue_bin := pmin(floor(PValue * 20), 19)]
  pvalue_histogram <- results[, .(features = .N), by = .(contrast, pvalue_bin)]
  pvalue_histogram[, midpoint := (pvalue_bin + 0.5) / 20]
  pvalues <- ggplot2::ggplot(
    pvalue_histogram,
    ggplot2::aes(x = midpoint, y = features)
  ) +
    ggplot2::geom_col(width = 0.05, fill = "#4C78A8") +
    ggplot2::facet_wrap(~contrast, ncol = 3, scales = "free_y") +
    ggplot2::scale_x_continuous(breaks = seq(0, 1, 0.25), limits = c(0, 1)) +
    ggplot2::scale_y_continuous(labels = function(value) format(value, big.mark = ",")) +
    ggplot2::labs(
      title = paste("P-value distributions —", organism),
      subtitle = "A concentration near zero is expected when a contrast contains signal.",
      x = "P-value",
      y = "Number of features"
    ) +
    dge_plot_theme()

  top <- results[direction != "Not significant"]
  top[, absolute_logfc := abs(logFC)]
  data.table::setorderv(
    top,
    c("contrast", "FDR", "absolute_logfc"),
    c(1L, 1L, -1L)
  )
  top <- top[, utils::head(.SD, top_n), by = contrast]

  if (nrow(top)) {
    top[, feature_label := as.character(get(feature_column))]
    if ("Final_Taxonomy" %in% names(top)) {
      annotated <- !is.na(top$Final_Taxonomy) & nzchar(trimws(top$Final_Taxonomy))
      top[annotated, feature_label := paste0(
        feature_label,
        " — ",
        substr(Final_Taxonomy, 1, 55)
      )]
    }
    top[, plot_key := paste(contrast, feature_label, sep = "\u241F")]
    top[, plot_key := factor(plot_key, levels = unique(plot_key[order(logFC)]))]
    label_lookup <- stats::setNames(top$feature_label, as.character(top$plot_key))

    top_features <- ggplot2::ggplot(
      top,
      ggplot2::aes(x = logFC, y = plot_key, colour = direction, size = -log10(FDR))
    ) +
      ggplot2::geom_vline(xintercept = 0, colour = "grey60", linewidth = 0.35) +
      ggplot2::geom_point(alpha = 0.85) +
      ggplot2::facet_wrap(~contrast, ncol = 2, scales = "free_y") +
      ggplot2::scale_y_discrete(labels = function(value) unname(label_lookup[value])) +
      ggplot2::scale_colour_manual(
        values = colours,
        breaks = c("Down", "Up")
      ) +
      ggplot2::labs(
        title = paste("Top differential features —", organism),
        subtitle = paste("Up to", top_n, "features per contrast, ranked by FDR."),
        x = "log2 fold change",
        y = NULL,
        colour = NULL,
        size = expression(-log[10](FDR))
      ) +
      dge_plot_theme()
  } else {
    top_features <- ggplot2::ggplot() +
      ggplot2::annotate(
        "text",
        x = 0,
        y = 0,
        label = "No features pass the selected FDR and fold-change thresholds."
      ) +
      ggplot2::labs(title = paste("Top differential features —", organism)) +
      ggplot2::theme_void()
  }

  paths <- c(
    volcano = save_dge_plot(
      volcano, file.path(output_dir, "volcano_plots.png"), 14, 8
    ),
    ma = save_dge_plot(
      ma_plot, file.path(output_dir, "ma_plots.png"), 14, 8
    ),
    counts = save_dge_plot(
      counts, file.path(output_dir, "dge_counts.png"), 11, 7
    ),
    pvalues = save_dge_plot(
      pvalues, file.path(output_dir, "pvalue_histograms.png"), 14, 8
    ),
    top_features = save_dge_plot(
      top_features, file.path(output_dir, "top_features.png"), 14, 11
    ),
    summary = summary_path
  )
  invisible(paths)
}
