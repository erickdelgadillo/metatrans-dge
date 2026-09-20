#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "helpers.R"))

fixture_root <- tempfile("analysis-sheet-")
dir.create(file.path(fixture_root, "raw", "prokaryotes"), recursive = TRUE)
dir.create(file.path(fixture_root, "metadata", "prokaryotes"), recursive = TRUE)
dir.create(file.path(fixture_root, "processed", "prokaryotes"), recursive = TRUE)

legacy <- organism_config("prokaryotes", fixture_root)
paths <- c(
  legacy$counts,
  legacy$metadata,
  legacy$annotations,
  legacy$reference,
  file.path(fixture_root, "contrasts.tsv")
)
stopifnot(all(file.create(paths)))

row <- data.frame(
  analysis_id = "interes_wp2_prok",
  adapter = "interes",
  organism = "prokaryotes",
  workpackage = "WP2",
  counts = file.path("raw", "prokaryotes", "counts.tsv.gz"),
  metadata = file.path(
    "metadata",
    "prokaryotes",
    "INTERES_Prok_samples_tags.csv"
  ),
  annotations = file.path(
    "processed",
    "prokaryotes",
    "prok_tpms_annotated.parquet"
  ),
  contrasts = "contrasts.tsv",
  feature_column = "orf",
  raw_feature_column = "orf",
  output_name = "prok_differential_expression.parquet",
  reference = file.path(
    "processed",
    "prokaryotes",
    "prok_differential_expression.parquet"
  )
)
sheet_path <- file.path(fixture_root, "analyses.csv")
utils::write.csv(row, sheet_path, row.names = FALSE, na = "")

analyses <- read_analysis_sheet(sheet_path)
config <- analysis_config(analyses, "interes_wp2_prok")
shared <- c(
  "organism",
  "feature_column",
  "raw_feature_column",
  "counts",
  "annotations",
  "metadata",
  "reference",
  "output_name"
)
stopifnot(
  identical(config[shared], legacy[shared]),
  identical(config$adapter, "interes"),
  identical(config$workpackage, "WP2"),
  identical(config$contrasts, normalizePath(file.path(fixture_root, "contrasts.tsv")))
)

example <- read_analysis_sheet(
  file.path(repository_root, "config", "analyses.example.csv"),
  check_files = FALSE
)
stopifnot(
  nrow(example) == 4L,
  setequal(example$workpackage, c("WP1", "WP2")),
  setequal(example$organism, c("prokaryotes", "eukaryotes"))
)

expect_error(
  validate_analysis_sheet(row[, setdiff(names(row), "counts")], FALSE),
  "missing required columns: counts"
)
expect_error(
  validate_analysis_sheet(rbind(row, row), FALSE),
  "Analysis IDs must be unique"
)
expect_error(
  validate_analysis_sheet(transform(row, analysis_id = "../outside"), FALSE),
  "Analysis IDs may contain only"
)
expect_error(
  validate_analysis_sheet(transform(row, output_name = "../result.parquet"), FALSE),
  "Output names must be safe filenames"
)
expect_error(
  validate_analysis_sheet(transform(row, output_name = "result;command"), FALSE),
  "Output names must be safe filenames"
)
expect_error(
  validate_analysis_sheet(transform(row, adapter = "unknown"), FALSE),
  "Unsupported adapters: unknown"
)
expect_error(
  validate_analysis_sheet(transform(row, organism = "unknown"), FALSE),
  "must use prokaryotes or eukaryotes"
)
expect_error(
  validate_analysis_sheet(transform(row, workpackage = "WP3"), FALSE),
  "must use WP1 or WP2"
)
expect_error(
  validate_analysis_sheet(transform(row, raw_feature_column = "Geneid"), FALSE),
  "feature-column definitions do not match"
)
expect_error(
  validate_analysis_sheet(transform(analyses, counts = "/missing/counts.tsv.gz")),
  "files do not exist"
)
expect_error(
  analysis_config(analyses, "missing_analysis"),
  "Analysis ID not found"
)

pass("analysis-sheet loading, validation, and configuration")
