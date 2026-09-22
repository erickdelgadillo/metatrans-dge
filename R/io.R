assert_packages <- function(packages) {
  missing <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing)) {
    stop(
      "Missing required R packages: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(packages)
}


build_count_matrix <- function(counts, metadata) {
  validate_counts(counts)
  validate_sample_metadata(metadata)

  counts <- data.table::copy(data.table::as.data.table(counts))
  metadata <- as.data.frame(metadata, stringsAsFactors = FALSE)

  counts[, feature_id := as.character(feature_id)]
  counts[, sample_id := as.character(sample_id)]
  metadata$sample_id <- as.character(metadata$sample_id)

  sample_keys <- metadata$sample_id
  observed_samples <- unique(counts$sample_id)

  if (!setequal(sample_keys, observed_samples)) {
    stop(
      "Count/metadata sample mismatch. Missing from counts: ",
      paste(setdiff(sample_keys, observed_samples), collapse = ", "),
      "; missing from metadata: ",
      paste(setdiff(observed_samples, sample_keys), collapse = ", "),
      call. = FALSE
    )
  }

  message("Constructing the zero-filled feature-by-sample matrix...")

  wide <- data.table::dcast(
    counts,
    feature_id ~ sample_id,
    value.var = "count",
    fill = 0L
  )

  rm(counts)
  gc(verbose = FALSE)

  data.table::setcolorder(wide, c("feature_id", sample_keys))

  count_matrix <- as.matrix(
    wide[, ..sample_keys]
  )

  rownames(count_matrix) <- wide$feature_id

  sample_data <- metadata
  rownames(sample_data) <- sample_data$sample_id

  sample_data <- sample_data[
    colnames(count_matrix),
    ,
    drop = FALSE
  ]

  list(
    counts = count_matrix,
    samples = sample_data
  )
}
