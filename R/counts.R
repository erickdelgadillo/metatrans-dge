validate_counts <- function(counts) {
  required <- c("feature_id", "sample_id", "count")

  missing <- setdiff(required, names(counts))

  if (length(missing)) {
    stop(
      "Counts are missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!nrow(counts)) {
    stop("Counts contain no observations.", call. = FALSE)
  }

  if (anyNA(counts$feature_id) || any(!nzchar(counts$feature_id))) {
    stop("Feature IDs cannot be missing or empty.", call. = FALSE)
  }

  if (anyNA(counts$sample_id) || any(!nzchar(counts$sample_id))) {
    stop("Sample IDs cannot be missing or empty.", call. = FALSE)
  }

  if (!is.numeric(counts$count)) {
    stop("Counts must be numeric.", call. = FALSE)
  }

  if (any(!is.finite(counts$count))) {
    stop("Counts must be finite.", call. = FALSE)
  }

  if (any(counts$count < 0)) {
    stop("Counts must be non-negative.", call. = FALSE)
  }

  if (any(counts$count %% 1 != 0)) {
    stop("Counts must be integers.", call. = FALSE)
  }

  keys <- counts[, c("feature_id", "sample_id"), drop = FALSE]

  if (anyDuplicated(keys)) {
    stop(
      "Feature/sample combinations must be unique.",
      call. = FALSE
    )
  }

  invisible(counts)
}
