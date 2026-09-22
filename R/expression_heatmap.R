match_heatmap_metadata <- function(
  sample_columns,
  metadata
) {
  metadata <- data.table::copy(
    data.table::as.data.table(
      metadata
    )
  )

  required_columns <- c(
    "sample_id",
    "group"
  )

  missing_columns <- setdiff(
    required_columns,
    names(metadata)
  )

  if (length(missing_columns)) {
    stop(
      "Metadata is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  metadata[, sample_id := as.character(sample_id)]
  metadata[, group := as.character(group)]

  if (
    anyNA(metadata$sample_id) ||
    any(!nzchar(metadata$sample_id))
  ) {
    stop(
      "Metadata sample_id values must be non-empty.",
      call. = FALSE
    )
  }

  if (anyDuplicated(metadata$sample_id)) {
    stop(
      "Metadata sample_id values must be unique.",
      call. = FALSE
    )
  }

  if (
    anyNA(metadata$group) ||
    any(!nzchar(metadata$group))
  ) {
    stop(
      "Metadata group values must be non-empty.",
      call. = FALSE
    )
  }

  missing_samples <- setdiff(
    sample_columns,
    metadata$sample_id
  )

  extra_samples <- setdiff(
    metadata$sample_id,
    sample_columns
  )

  if (length(missing_samples) || length(extra_samples)) {
    details <- c(
      if (length(missing_samples)) {
        paste0(
          "missing from metadata: ",
          paste(missing_samples, collapse = ", ")
        )
      },
      if (length(extra_samples)) {
        paste0(
          "missing from expression matrix: ",
          paste(extra_samples, collapse = ", ")
        )
      }
    )

    stop(
      "Expression/metadata sample mismatch (",
      paste(details, collapse = "; "),
      ").",
      call. = FALSE
    )
  }

  metadata_order <- match(
    sample_columns,
    metadata$sample_id
  )

  list(
    sample_ids = sample_columns,
    group_labels = metadata$group[metadata_order]
  )
}

cluster_heatmap_samples <- function(z) {
  # Cluster samples only. Euclidean distance on feature-wise Z-scores
  # gives each retained feature a comparable scale. This is calculated
  # before colour clipping or raster-band compression so every retained
  # feature contributes, while features themselves are never clustered.
  sample_distance <- stats::dist(
    t(z),
    method = "euclidean"
  )

  stats::hclust(
    sample_distance,
    method = "average"
  )
}

plot_expression_heatmap <- function(
  normalized_expression,
  metadata,
  output_path,
  z_limit = 3,
  max_rows = 3000L,
  width = 4000,
  height = 1800,
  res = 200
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
      "Normalized expression must contain at least two samples.",
      call. = FALSE
    )
  }

  if (!nrow(expression)) {
    stop(
      "Normalized expression contains no features.",
      call. = FALSE
    )
  }

  if (
    length(z_limit) != 1L ||
    !is.finite(z_limit) ||
    z_limit <= 0
  ) {
    stop(
      "z_limit must be one positive finite number.",
      call. = FALSE
    )
  }

  if (
    length(max_rows) != 1L ||
    !is.finite(max_rows) ||
    max_rows < 1
  ) {
    stop(
      "max_rows must be a positive number.",
      call. = FALSE
    )
  }

  max_rows <- as.integer(max_rows)

  sample_metadata <- match_heatmap_metadata(
    sample_columns,
    metadata
  )

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

  n_samples <- ncol(values)

  # Row-wise Z-score without apply().
  row_means <- rowMeans(values)

  row_variance <- (
    rowSums(values^2) -
      n_samples * row_means^2
  ) / (n_samples - 1)

  row_variance <- pmax(
    row_variance,
    0
  )

  row_sd <- sqrt(
    row_variance
  )

  constant <- row_sd <= sqrt(
    .Machine$double.eps
  )

  safe_sd <- row_sd
  safe_sd[constant] <- 1

  z <- sweep(
    values,
    1,
    row_means,
    "-"
  )

  z <- sweep(
    z,
    1,
    safe_sd,
    "/"
  )

  # Constant-expression features remain in the heatmap with Z = 0.
  if (any(constant)) {
    z[constant, ] <- 0
  }

  sample_clustering <- cluster_heatmap_samples(z)
  sample_order <- sample_clustering$order

  z <- z[
    ,
    sample_order,
    drop = FALSE
  ]

  group_labels <- sample_metadata$group_labels[
    sample_order
  ]

  # Clip only after clustering so extreme Z-scores do not dominate the
  # colour scale but still contribute fully to sample distances.
  z[z > z_limit] <- z_limit
  z[z < -z_limit] <- -z_limit

  # Deterministic feature ordering by the displayed sample where each
  # feature peaks. This is a sort, not feature clustering.
  peak_sample <- max.col(
    z,
    ties.method = "first"
  )

  peak_strength <- z[
    cbind(
      seq_len(nrow(z)),
      peak_sample
    )
  ]

  feature_order <- order(
    peak_sample,
    -peak_strength
  )

  z <- z[
    feature_order,
    ,
    drop = FALSE
  ]

  # Keep track of the true number of retained features.
  n_features <- nrow(z)

  # Compress very large matrices into raster bands. Every feature
  # contributes to the final image and no feature distance matrix is made.
  if (n_features > max_rows) {
    message(
      "Compressing ",
      format(n_features, big.mark = ","),
      " features into ",
      format(max_rows, big.mark = ","),
      " raster bands..."
    )

    groups <- ceiling(
      seq_len(n_features) *
        max_rows /
        n_features
    )

    group_sizes <- tabulate(
      groups,
      nbins = max_rows
    )

    z <- rowsum(
      z,
      group = groups,
      reorder = FALSE
    )

    z <- z / group_sizes
  }

  output_dir <- dirname(
    output_path
  )

  if (!dir.exists(output_dir)) {
    dir.create(
      output_dir,
      recursive = TRUE
    )
  }

  grDevices::png(
    filename = output_path,
    width = width,
    height = height,
    res = res
  )

  device_id <- grDevices::dev.cur()
  on.exit(
    if (device_id %in% grDevices::dev.list()) {
      grDevices::dev.off(device_id)
    },
    add = TRUE
  )

  graphics::layout(
    matrix(c(1, 2), nrow = 1),
    widths = c(1.3, 6)
  )

  graphics::par(
    mar = c(3, 1, 3, 0),
    xaxs = "i",
    yaxs = "i"
  )

  graphics::plot(
    stats::as.dendrogram(sample_clustering),
    horiz = TRUE,
    leaflab = "none",
    axes = FALSE,
    xlab = "",
    ylab = ""
  )

  graphics::par(
    mar = c(3, 10, 3, 2),
    xaxs = "i",
    yaxs = "i"
  )

  palette <- grDevices::hcl.colors(
    256,
    "Blue-Red 3",
    rev = TRUE
  )

  # Features are horizontal (x) and clustered samples are vertical (y).
  graphics::image(
    x = seq_len(nrow(z)),
    y = seq_len(ncol(z)),
    z = z,
    col = palette,
    zlim = c(-z_limit, z_limit),
    axes = FALSE,
    xlab = "",
    ylab = "",
    useRaster = TRUE
  )

  graphics::axis(
    side = 2,
    at = seq_along(group_labels),
    labels = group_labels,
    las = 2,
    cex.axis = 0.8
  )

  graphics::box()

  graphics::title(
    main = paste0(
      "Global expression profile (",
      format(n_features, big.mark = ","),
      " features)"
    ),
    xlab = "Features"
  )

  grDevices::dev.off(device_id)

  message(
    "Wrote expression heatmap from ",
    format(n_features, big.mark = ","),
    " features across ",
    ncol(z),
    " samples to:\n",
    normalizePath(output_path)
  )

  invisible(output_path)
}
