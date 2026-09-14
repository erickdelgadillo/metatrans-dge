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

read_sample_metadata <- function(config) {
  metadata <- data.table::fread(config$metadata, encoding = "UTF-8")
  required <- c("sample", "group", "Sample", "date")
  missing <- setdiff(required, names(metadata))
  if (length(missing)) {
    stop("Metadata columns are missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  metadata <- metadata[grepl("^WP2_", group)]
  metadata[, replic := sub("^.*_", "", Sample)]
  metadata[, analysis_sample := paste(sub("^WP2_", "", group), replic, sep = "_")]
  metadata[, group := factor(group, levels = unique(group))]
  if (anyDuplicated(metadata$analysis_sample)) {
    stop("Metadata analysis sample identifiers are not unique.", call. = FALSE)
  }
  metadata
}

build_count_matrix <- function(config, metadata) {
  message("Reading the final annotated WP2 counts for ", config$organism, "...")
  columns <- c(
    config$feature_column, "Workpackage", "treatment", "time", "replic", "count"
  )
  counts <- data.table::as.data.table(
    arrow::read_parquet(config$counts, col_select = tidyselect::all_of(columns))
  )
  counts <- counts[Workpackage == "WP2"]
  counts[, sample := paste(treatment, time, replic, sep = "_")]
  counts <- counts[, .(count = sum(count)), by = c(config$feature_column, "sample")]

  if (!nrow(counts)) stop("The annotated count table has no WP2 rows.", call. = FALSE)
  if (anyNA(counts$count) || any(counts$count < 0) || any(counts$count %% 1 != 0)) {
    stop("Counts must be finite, non-negative integers.", call. = FALSE)
  }

  sample_keys <- metadata$analysis_sample
  observed_samples <- unique(counts$sample)
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
  cast_formula <- stats::as.formula(paste(config$feature_column, "~ sample"))
  wide <- data.table::dcast(counts, cast_formula, value.var = "count", fill = 0L)
  rm(counts)
  gc(verbose = FALSE)

  data.table::setcolorder(wide, c(config$feature_column, sample_keys))
  count_matrix <- as.matrix(wide[, ..sample_keys])
  rownames(count_matrix) <- wide[[config$feature_column]]
  storage.mode(count_matrix) <- "integer"

  sample_data <- as.data.frame(metadata)
  rownames(sample_data) <- sample_data$analysis_sample
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
