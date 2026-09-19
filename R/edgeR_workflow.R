contrast_vector <- function(design, numerator, denominator) {
  missing <- setdiff(c(numerator, denominator), colnames(design))
  if (length(missing)) {
    stop("Design groups are missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  vector <- numeric(ncol(design))
  names(vector) <- colnames(design)
  vector[numerator] <- 1
  vector[denominator] <- -1
  vector
}

run_edger <- function(
  count_matrix,
  sample_data,
  feature_column,
  contrasts
) {
  sample_data$group <- factor(
    sample_data$group,
    levels = unique(as.character(sample_data$group))
  )
  dge <- edgeR::DGEList(
    counts = count_matrix, samples = sample_data, group = sample_data$group
  )
  message("Filtering low-expression features...")
  keep <- edgeR::filterByExpr(dge, group = dge$samples$group)
  dge <- dge[keep, , keep.lib.sizes = FALSE]
  message(sum(keep), " of ", length(keep), " features retained.")
  dge <- edgeR::normLibSizes(dge, method = "TMM")

  design <- stats::model.matrix(~0 + group, data = dge$samples)
  colnames(design) <- levels(dge$samples$group)

  required_groups <- unique(c(contrasts$numerator, contrasts$denominator))
  missing_groups <- setdiff(required_groups, colnames(design))
  if (length(missing_groups)) {
    stop(
      "Contrast groups are missing from the design: ",
      paste(missing_groups, collapse = ", "),
      call. = FALSE
    )
  }

  message("Estimating dispersions and fitting the quasi-likelihood model...")
  dispersion <- edgeR::estimateDisp(dge, design)
  fit <- edgeR::glmQLFit(dispersion, design)

  output_columns <- setdiff(names(contrasts), c("numerator", "denominator"))
  outputs <- vector("list", nrow(contrasts))
  for (index in seq_len(nrow(contrasts))) {
    definition <- contrasts[index, , drop = FALSE]
    message("Testing ", definition$contrast, "...")
    contrast <- contrast_vector(design, definition$numerator, definition$denominator)
    test <- edgeR::glmQLFTest(fit, contrast = contrast)
    table <- data.table::as.data.table(
      edgeR::topTags(test, n = Inf, adjust.method = "BH")$table,
      keep.rownames = feature_column
    )
    for (column in output_columns) {
      table[, (column) := definition[[column]]]
    }
    outputs[[index]] <- table
  }
  data.table::rbindlist(outputs, use.names = TRUE)
}

run_dge_workflow <- function(organism, data_root, output_dir, contrasts_file) {
  assert_packages(c("arrow", "data.table", "edgeR", "tidyselect"))
  config <- organism_config(organism, data_root)
  assert_input_files(config)
  contrasts <- read_contrasts(contrasts_file)
  metadata <- read_sample_metadata(config)
  prepared <- build_count_matrix(config, metadata)
  statistics <- run_edger(
    prepared$counts,
    prepared$samples,
    config$feature_column,
    contrasts
  )
  rm(prepared)
  gc(verbose = FALSE)
  result <- annotate_dge_results(statistics, config)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_file <- file.path(output_dir, config$output_name)
  arrow::write_parquet(result, output_file, compression = "zstd")
  provenance_file <- file.path(output_dir, "run_metadata.txt")
  provenance <- c(
    paste0("organism: ", organism),
    paste0("generated_utc: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    paste0("R: ", R.version.string),
    paste0("edgeR: ", as.character(utils::packageVersion("edgeR"))),
    paste0("limma: ", as.character(utils::packageVersion("limma"))),
    paste0("arrow: ", as.character(utils::packageVersion("arrow"))),
    paste0("data.table: ", as.character(utils::packageVersion("data.table"))),
    paste0("input_counts: ", config$counts),
    paste0("input_annotations: ", config$annotations),
    paste0("input_metadata: ", config$metadata),
    paste0("contrast_definitions: ", normalizePath(contrasts_file)),
    paste0("features_tested: ", length(unique(result[[config$feature_column]]))),
    paste0("contrasts: ", length(unique(result$contrast))),
    paste0("output_rows: ", nrow(result))
  )
  writeLines(provenance, provenance_file)
  message("Wrote ", format(nrow(result), big.mark = ","), " rows to:\n", output_file)
  message("Wrote run metadata to:\n", provenance_file)
  invisible(output_file)
}
