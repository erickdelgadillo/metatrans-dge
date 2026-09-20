adapt_interes_metadata <- function(metadata, workpackage) {
  workpackage <- match.arg(workpackage, c("WP1", "WP2"))

  required <- c("sample", "group", "Sample")

  missing <- setdiff(required, names(metadata))

  if (length(missing)) {
    stop(
      "INTERES metadata is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  pattern <- paste0("^", workpackage, "_")
  metadata <- metadata[grepl(pattern, metadata$group), , drop = FALSE]

  if (!nrow(metadata)) {
    stop(
      "No INTERES samples found for workpackage: ",
      workpackage,
      call. = FALSE
    )
  }

  metadata$replicate <- sub("^.*?(\\d+)$", "\\1", metadata$Sample)

  metadata$sample_id <- paste(
    sub(pattern, "", metadata$group),
    metadata$replicate,
    sep = "_"
  )

  validate_sample_metadata(metadata)

  metadata
}

adapt_interes_counts <- function(counts, metadata, organism) {
  counts <- as.data.frame(counts, stringsAsFactors = FALSE)
  metadata <- as.data.frame(metadata, stringsAsFactors = FALSE)

  organism <- match.arg(
    organism,
    c("prokaryotes", "eukaryotes")
  )

  if (organism == "prokaryotes") {
    required <- c("orf", "sample", "count")
    metadata_required <- c("sample", "T1", "sample_id")
    feature_column <- "orf"

    missing <- setdiff(required, names(counts))

    if (length(missing)) {
      stop(
        "INTERES prokaryotic counts are missing required columns: ",
        paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
  } else {
    required <- c("Geneid", "sample", "count")
    metadata_required <- c("sample", "sample_id")
    feature_column <- "Geneid"

    missing <- setdiff(required, names(counts))

    if (length(missing)) {
      stop(
        "INTERES eukaryotic counts are missing required columns: ",
        paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
  }

  metadata_missing <- setdiff(metadata_required, names(metadata))

  if (length(metadata_missing)) {
    stop(
      "INTERES metadata is missing required columns for ",
      organism,
      ": ",
      paste(metadata_missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (organism == "prokaryotes") {
    metadata$raw_sample_id <- paste(
      metadata$sample,
      metadata$T1,
      sep = "_"
    )
  } else {
    metadata$raw_sample_id <- as.character(metadata$sample)
  }

  if (
    anyNA(metadata$raw_sample_id) ||
      any(!nzchar(metadata$raw_sample_id))
  ) {
    stop("INTERES raw sample IDs cannot be missing or empty.", call. = FALSE)
  }

  if (anyDuplicated(metadata$raw_sample_id)) {
    stop("INTERES raw sample IDs must be unique.", call. = FALSE)
  }

  counts$sample <- as.character(counts$sample)

  sample_map <- metadata[, c("raw_sample_id", "sample_id"), drop = FALSE]

  columns <- c(feature_column, "sample", "count")

  counts <- merge(
    counts[, columns, drop = FALSE],
    sample_map,
    by.x = "sample",
    by.y = "raw_sample_id",
    sort = FALSE
  )

  if (!nrow(counts)) {
    stop("No INTERES count samples matched the metadata.", call. = FALSE)
  }

  names(counts)[names(counts) == feature_column] <- "feature_id"

  if (organism == "eukaryotes") {
    counts$feature_id <- sub("^cds\\.", "", counts$feature_id)
  }

  counts[, c("feature_id", "sample_id", "count"), drop = FALSE]
}
