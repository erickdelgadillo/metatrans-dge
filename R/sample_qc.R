compute_sample_similarity <- function(
  normalized_expression
) {
  expression <- data.table::copy(
    data.table::as.data.table(
      normalized_expression
    )
  )

  if (!"feature_id" %in% names(expression)) {
    stop(
      "Normalized expression must contain a feature_id column.",
      call. = FALSE
    )
  }

  sample_columns <- setdiff(
    names(expression),
    "feature_id"
  )

  if (length(sample_columns) < 2L) {
    stop(
      "At least two samples are required.",
      call. = FALSE
    )
  }

  numeric_samples <- vapply(
    expression[, ..sample_columns],
    is.numeric,
    logical(1)
  )

  if (!all(numeric_samples)) {
    stop(
      "All expression columns must be numeric.",
      call. = FALSE
    )
  }

  values <- as.matrix(
    expression[, ..sample_columns]
  )

  if (!all(is.finite(values))) {
    stop(
      "Expression matrix contains non-finite values.",
      call. = FALSE
    )
  }

  correlation <- stats::cor(
    values,
    method = "pearson"
  )

  distance <- stats::as.dist(
    1 - correlation
  )

  list(
    correlation = correlation,
    distance = distance
  )
}


compute_sample_mds <- function(
  distance
) {
  n_samples <- attr(
    distance,
    "Size"
  )

  if (n_samples < 3L) {
    stop(
      "At least three samples are required for 2D MDS.",
      call. = FALSE
    )
  }

  coordinates <- stats::cmdscale(
    distance,
    k = 2,
    eig = TRUE
  )

  data.table::data.table(
    sample_id = rownames(
      coordinates$points
    ),
    MDS1 = coordinates$points[, 1],
    MDS2 = coordinates$points[, 2]
  )
}


plot_sample_mds <- function(
  mds,
  metadata,
  output_path
) {
  mds <- data.table::copy(
    data.table::as.data.table(mds)
  )

  metadata <- data.table::copy(
    data.table::as.data.table(metadata)
  )

  required_metadata <- c(
    "sample_id",
    "group"
  )

  missing <- setdiff(
    required_metadata,
    names(metadata)
  )

  if (length(missing)) {
    stop(
      "Metadata is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (anyDuplicated(metadata$sample_id)) {
    stop(
      "Metadata contains duplicated sample_id values.",
      call. = FALSE
    )
  }

  mds <- merge(
    mds,
    metadata[
      ,
      .(
        sample_id,
        group
      )
    ],
    by = "sample_id",
    all.x = TRUE,
    sort = FALSE
  )

  if (anyNA(mds$group)) {
    stop(
      "Some MDS samples are missing from metadata.",
      call. = FALSE
    )
  }

  plot <- ggplot2::ggplot(
    mds,
    ggplot2::aes(
      x = MDS1,
      y = MDS2,
      colour = group
    )
  ) +
    ggplot2::geom_point(
      size = 4
    ) +
    ggplot2::geom_text(
      ggplot2::aes(
        label = group
      ),
      vjust = -0.8,
      show.legend = FALSE
    ) +
    ggplot2::labs(
      title = "Sample similarity",
      x = "MDS1",
      y = "MDS2",
      colour = "Group"
    ) +
    ggplot2::theme_minimal(
      base_size = 12
    ) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold"
      )
    )

  ggplot2::ggsave(
    filename = output_path,
    plot = plot,
    width = 8,
    height = 6,
    dpi = 180,
    bg = "white"
  )

  message(
    "Wrote sample MDS plot to:\n",
    normalizePath(output_path)
  )

  invisible(output_path)
}


plot_sample_correlation <- function(
  correlation,
  metadata,
  output_path
) {
  metadata <- data.table::copy(
    data.table::as.data.table(metadata)
  )

  required_metadata <- c(
    "sample_id",
    "group"
  )

  missing <- setdiff(
    required_metadata,
    names(metadata)
  )

  if (length(missing)) {
    stop(
      "Metadata is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (anyDuplicated(metadata$sample_id)) {
    stop(
      "Metadata contains duplicated sample_id values.",
      call. = FALSE
    )
  }

  sample_ids <- colnames(
    correlation
  )

  if (!setequal(
    sample_ids,
    metadata$sample_id
  )) {
    stop(
      "Correlation matrix samples do not match metadata.",
      call. = FALSE
    )
  }

  distance <- stats::as.dist(
    1 - correlation
  )

  clustering <- stats::hclust(
    distance,
    method = "average"
  )

  sample_order <- clustering$labels[
    clustering$order
  ]

  group_labels <- metadata$group[
    match(
      sample_order,
      metadata$sample_id
    )
  ]

  names(group_labels) <- sample_order

  correlation_table <- data.table::as.data.table(
    correlation,
    keep.rownames = "sample_x"
  )

  correlation_long <- data.table::melt(
    correlation_table,
    id.vars = "sample_x",
    variable.name = "sample_y",
    value.name = "correlation"
  )

  correlation_long[
    ,
    sample_x := factor(
      sample_x,
      levels = sample_order
    )
  ]

  correlation_long[
    ,
    sample_y := factor(
      sample_y,
      levels = rev(sample_order)
    )
  ]

  plot <- ggplot2::ggplot(
    correlation_long,
    ggplot2::aes(
      x = sample_x,
      y = sample_y,
      fill = correlation
    )
  ) +
    ggplot2::geom_tile() +
    ggplot2::scale_x_discrete(
      labels = function(x) {
        group_labels[x]
      }
    ) +
    ggplot2::scale_y_discrete(
      labels = function(x) {
        group_labels[x]
      }
    ) +
    ggplot2::scale_fill_gradient2(
      midpoint = 0,
      limits = c(-1, 1),
      name = "Pearson\ncorrelation"
    ) +
    ggplot2::labs(
      title = "Sample correlation",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(
      base_size = 11
    ) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(
        angle = 45,
        hjust = 1
      ),
      plot.title = ggplot2::element_text(
        face = "bold"
      )
    )

  ggplot2::ggsave(
    filename = output_path,
    plot = plot,
    width = 8,
    height = 7,
    dpi = 180,
    bg = "white"
  )

  message(
    "Wrote sample correlation plot to:\n",
    normalizePath(output_path)
  )

  invisible(output_path)
}
