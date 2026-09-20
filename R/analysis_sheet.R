analysis_sheet_columns <- function() {
  c(
    "analysis_id",
    "adapter",
    "organism",
    "workpackage",
    "counts",
    "metadata",
    "annotations",
    "contrasts",
    "feature_column",
    "raw_feature_column",
    "output_name"
  )
}

analysis_sheet_path_columns <- function() {
  c("counts", "metadata", "annotations", "contrasts", "reference")
}

normalise_analysis_sheet <- function(analyses) {
  analyses <- as.data.frame(analyses, stringsAsFactors = FALSE)
  analyses[] <- lapply(analyses, function(value) {
    if (is.factor(value)) value <- as.character(value)
    if (is.character(value)) trimws(value) else value
  })
  analyses
}

validate_analysis_sheet <- function(analyses, check_files = TRUE) {
  analyses <- normalise_analysis_sheet(analyses)
  required <- analysis_sheet_columns()
  missing <- setdiff(required, names(analyses))

  if (length(missing)) {
    stop(
      "Analysis sheet is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!nrow(analyses)) {
    stop("Analysis sheet contains no analyses.", call. = FALSE)
  }

  invalid_required <- vapply(
    analyses[required],
    function(value) anyNA(value) || any(!nzchar(as.character(value))),
    logical(1)
  )

  if (any(invalid_required)) {
    stop(
      "Analysis sheet required values cannot be missing or empty: ",
      paste(names(invalid_required)[invalid_required], collapse = ", "),
      call. = FALSE
    )
  }

  if (anyDuplicated(analyses$analysis_id)) {
    stop("Analysis IDs must be unique.", call. = FALSE)
  }

  safe_analysis_ids <- grepl(
    "^[A-Za-z0-9][A-Za-z0-9._-]*$",
    analyses$analysis_id
  )
  if (any(!safe_analysis_ids)) {
    stop(
      "Analysis IDs may contain only letters, numbers, dots, underscores, and hyphens.",
      call. = FALSE
    )
  }

  safe_output_names <- basename(analyses$output_name) == analyses$output_name &
    grepl("^[A-Za-z0-9][A-Za-z0-9._-]*$", analyses$output_name)
  if (any(!safe_output_names)) {
    stop(
      "Output names must be safe filenames containing only letters, numbers, dots, underscores, and hyphens.",
      call. = FALSE
    )
  }

  unsupported_adapters <- setdiff(unique(analyses$adapter), "interes")
  if (length(unsupported_adapters)) {
    stop(
      "Unsupported adapters: ",
      paste(unsupported_adapters, collapse = ", "),
      call. = FALSE
    )
  }

  interes <- analyses$adapter == "interes"
  invalid_organisms <- interes & !analyses$organism %in% c(
    "prokaryotes",
    "eukaryotes"
  )
  if (any(invalid_organisms)) {
    stop(
      "INTERES analyses must use prokaryotes or eukaryotes.",
      call. = FALSE
    )
  }

  invalid_workpackages <- interes & !analyses$workpackage %in% c("WP1", "WP2")
  if (any(invalid_workpackages)) {
    stop("INTERES analyses must use WP1 or WP2.", call. = FALSE)
  }

  expected_feature <- ifelse(
    analyses$organism == "prokaryotes",
    "orf",
    "geneid"
  )
  expected_raw_feature <- ifelse(
    analyses$organism == "prokaryotes",
    "orf",
    "Geneid"
  )
  invalid_features <- interes & (
    analyses$feature_column != expected_feature |
      analyses$raw_feature_column != expected_raw_feature
  )
  if (any(invalid_features)) {
    stop(
      "INTERES feature-column definitions do not match the organism.",
      call. = FALSE
    )
  }

  if (check_files) {
    path_columns <- intersect(analysis_sheet_path_columns(), names(analyses))
    missing_files <- unlist(lapply(path_columns, function(column) {
      values <- analyses[[column]]
      required_path <- column != "reference"
      present <- !is.na(values) & nzchar(values)
      invalid <- (required_path | present) & (!present | !file.exists(values))
      if (!any(invalid)) return(character())
      paste0(analyses$analysis_id[invalid], ":", column, "=", values[invalid])
    }), use.names = FALSE)

    if (length(missing_files)) {
      stop(
        "Analysis sheet files do not exist: ",
        paste(missing_files, collapse = ", "),
        call. = FALSE
      )
    }
  }

  invisible(analyses)
}

resolve_analysis_path <- function(path, base_dir) {
  if (is.na(path) || !nzchar(path)) return("")

  expanded <- path.expand(path)
  absolute <- startsWith(expanded, "/") || grepl("^[A-Za-z]:[/\\\\]", expanded)
  if (!absolute) expanded <- file.path(base_dir, expanded)

  normalizePath(expanded, mustWork = FALSE)
}

read_analysis_sheet <- function(path, check_files = TRUE) {
  if (!file.exists(path)) {
    stop("Analysis sheet does not exist: ", path, call. = FALSE)
  }

  path <- normalizePath(path)
  analyses <- data.table::fread(
    path,
    data.table = FALSE,
    na.strings = NULL
  )
  analyses <- normalise_analysis_sheet(analyses)

  path_columns <- intersect(analysis_sheet_path_columns(), names(analyses))
  base_dir <- dirname(path)
  analyses[path_columns] <- lapply(
    analyses[path_columns],
    function(values) vapply(
      values,
      resolve_analysis_path,
      character(1),
      base_dir = base_dir
    )
  )

  validate_analysis_sheet(analyses, check_files = check_files)
  analyses
}

analysis_config <- function(analyses, analysis_id) {
  analyses <- normalise_analysis_sheet(analyses)
  validate_analysis_sheet(analyses, check_files = FALSE)

  matches <- which(analyses$analysis_id == analysis_id)
  if (!length(matches)) {
    stop("Analysis ID not found: ", analysis_id, call. = FALSE)
  }

  analysis <- analyses[matches, , drop = FALSE]
  reference <- if (
    "reference" %in% names(analysis) &&
      !is.na(analysis$reference) &&
      nzchar(analysis$reference)
  ) {
    analysis$reference
  } else {
    NA_character_
  }

  list(
    analysis_id = analysis$analysis_id,
    adapter = analysis$adapter,
    organism = analysis$organism,
    workpackage = analysis$workpackage,
    feature_column = analysis$feature_column,
    raw_feature_column = analysis$raw_feature_column,
    counts = analysis$counts,
    annotations = analysis$annotations,
    metadata = analysis$metadata,
    contrasts = analysis$contrasts,
    reference = reference,
    output_name = analysis$output_name
  )
}
