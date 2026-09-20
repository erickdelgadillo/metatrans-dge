assert_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Missing R packages: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

assert_input_files <- function(config) {
  paths <- unlist(config[c("counts", "annotations", "metadata")])
  missing <- paths[!file.exists(paths)]
  if (length(missing)) {
    stop("Required input files are missing:\n", paste(missing, collapse = "\n"), call. = FALSE)
  }
  invisible(paths)
}

read_sample_metadata <- function(config, workpackage = "WP2") {
  metadata <- data.table::fread(config$metadata, encoding = "UTF-8")
  adapt_interes_metadata(metadata, workpackage)
}

read_feature_counts <- function(config) {
  message("Reading raw INTERES counts for ", config$organism, "...")

  data.table::fread(
    config$counts,
    select = c(config$raw_feature_column, "sample", "count"),
    encoding = "UTF-8"
  )
}

filter_annotated_counts <- function(counts, config) {
  feature_ids <- arrow::read_parquet(
    config$annotations,
    col_select = tidyselect::all_of(config$feature_column),
    as_data_frame = TRUE
  )[[config$feature_column]]
  feature_ids <- unique(as.character(feature_ids))

  keep <- as.character(counts$feature_id) %in% feature_ids
  counts <- counts[keep, , drop = FALSE]

  if (!nrow(counts)) {
    stop("No count features have curated annotations.", call. = FALSE)
  }

  message(
    "Retained ",
    format(length(unique(counts$feature_id)), big.mark = ","),
    " features with curated annotations."
  )

  counts
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
  count_matrix <- as.matrix(wide[, ..sample_keys])
  rownames(count_matrix) <- wide$feature_id

  sample_data <- metadata
  rownames(sample_data) <- sample_data$sample_id
  sample_data <- sample_data[colnames(count_matrix), , drop = FALSE]

  list(counts = count_matrix, samples = sample_data)
}

read_feature_annotations <- function(config, feature_ids) {
  columns <- c(
    config$feature_column, "Domain", "Phylum", "Class", "Order", "Family",
    "Genus", "Species", "Final_Taxonomy", "KEGG_ko", "KEGG_ko2",
    "KEGG_ko3", "KEGG_Module", "PFAMs"
  )
  annotations <- data.table::as.data.table(
    arrow::read_parquet(config$annotations, col_select = tidyselect::all_of(columns))
  )
  annotations <- unique(annotations[get(config$feature_column) %in% feature_ids])
  if (anyDuplicated(annotations[[config$feature_column]])) {
    stop("A feature has multiple distinct annotation records.", call. = FALSE)
  }
  annotations
}

annotate_dge_results <- function(statistics, config) {
  feature_ids <- unique(statistics[[config$feature_column]])
  message("Reading the curated feature annotations...")
  annotations <- read_feature_annotations(config, feature_ids)
  result <- merge(
    statistics, annotations,
    by = config$feature_column, all.x = TRUE, sort = FALSE
  )
  if (nrow(result) != nrow(statistics)) {
    stop("The annotation join changed the number of DGE rows.", call. = FALSE)
  }

  preferred_order <- c(
    config$feature_column, "logFC", "logCPM", "F", "PValue", "FDR",
    "contrast", "Domain", "Phylum", "Class", "Order", "Family", "Genus",
    "Species", "Final_Taxonomy", "KEGG_ko", "KEGG_ko2", "KEGG_ko3",
    "KEGG_Module", "PFAMs", "comparison", "time"
  )
  data.table::setcolorder(result, preferred_order)
  result
}
