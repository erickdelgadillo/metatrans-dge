validate_sample_metadata <- function(metadata) {
  required <- c("sample_id", "group")

  missing <- setdiff(required, names(metadata))

  if (length(missing)) {
    stop(
      "Sample metadata is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!nrow(metadata)) {
    stop("Sample metadata contains no samples.", call. = FALSE)
  }

  if (anyNA(metadata$sample_id) || any(!nzchar(metadata$sample_id))) {
    stop("Sample IDs cannot be missing or empty.", call. = FALSE)
  }

  if (anyNA(metadata$group) || any(!nzchar(metadata$group))) {
    stop("Sample groups cannot be missing or empty.", call. = FALSE)
  }

  if (anyDuplicated(metadata$sample_id)) {
    stop("Sample IDs must be unique.", call. = FALSE)
  }

  invisible(metadata)
}