default_data_root <- function() {
  Sys.getenv(
    "INTERES_DATA_ROOT",
    unset = "/home/erick/Data/ProjectsData/marine-p-deficiency-metat/data"
  )
}

organism_config <- function(organism, data_root = default_data_root()) {
  organism <- match.arg(organism, c("prokaryotes", "eukaryotes"))
  data_root <- normalizePath(data_root, mustWork = FALSE)

  if (organism == "prokaryotes") {
    return(list(
      organism = organism,
      feature_column = "orf",
      raw_feature_column = "orf",
      counts = file.path(data_root, "raw", organism, "counts.tsv.gz"),
      annotations = file.path(data_root, "processed", organism, "prok_tpms_annotated.parquet"),
      metadata = file.path(data_root, "metadata", organism, "INTERES_Prok_samples_tags.csv"),
      reference = file.path(data_root, "processed", organism, "prok_differential_expression.parquet"),
      output_name = "prok_differential_expression.parquet"
    ))
  }

  list(
    organism = organism,
    feature_column = "geneid",
    raw_feature_column = "Geneid",
    counts = file.path(data_root, "raw", organism, "polyA_counts.tsv.gz"),
    annotations = file.path(data_root, "processed", organism, "euk_tpms_annotated.parquet"),
    metadata = file.path(data_root, "metadata", organism, "INTERES_Euk_samples_tags.csv"),
    reference = file.path(data_root, "processed", organism, "euk_differential_expression.parquet"),
    output_name = "euk_differential_expression.parquet"
  )
}

read_contrasts <- function(path) {
  if (!file.exists(path)) {
    stop("Contrast file does not exist: ", path, call. = FALSE)
  }

  contrasts <- data.table::fread(
    path,
    sep = "\t",
    header = TRUE,
    data.table = FALSE
  )

  required <- c("contrast", "numerator", "denominator")
  missing <- setdiff(required, names(contrasts))

  if (length(missing)) {
    stop(
      "Contrast file is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!nrow(contrasts)) {
    stop("Contrast file contains no contrasts.", call. = FALSE)
  }

  contrasts[required] <- lapply(contrasts[required], function(value) {
    trimws(as.character(value))
  })

  invalid_values <- vapply(
    contrasts[required],
    function(value) anyNA(value) || any(!nzchar(value)),
    logical(1)
  )

  if (any(invalid_values)) {
    stop(
      "Contrast definitions cannot contain missing or empty required values.",
      call. = FALSE
    )
  }

  if (anyDuplicated(contrasts$contrast)) {
    duplicated_names <- unique(
      contrasts$contrast[duplicated(contrasts$contrast)]
    )

    stop(
      "Duplicated contrast names: ",
      paste(duplicated_names, collapse = ", "),
      call. = FALSE
    )
  }

  invalid <- contrasts$numerator == contrasts$denominator

  if (any(invalid)) {
    stop(
      "Contrast numerator and denominator must differ: ",
      paste(contrasts$contrast[invalid], collapse = ", "),
      call. = FALSE
    )
  }

  contrasts
}
