source("tests/helpers.R")
source(
  file.path(
    repository_root,
    "R",
    "expression_heatmap.R"
  )
)

normalized_expression <- data.frame(
  feature_id = paste0("feature_", seq_len(8)),
  sample_1 = c(8, 7, 6, 5, 1, 2, 3, 4),
  sample_2 = c(7, 6, 5, 4, 2, 3, 4, 5),
  sample_3 = c(1, 2, 3, 4, 8, 7, 6, 5),
  check.names = FALSE
)

# Deliberately use a different metadata order and duplicate group labels.
metadata <- data.frame(
  sample_id = c("sample_3", "sample_1", "sample_2"),
  group = c("treated", "control", "treated")
)

matched <- match_heatmap_metadata(
  names(normalized_expression)[-1],
  metadata
)

stopifnot(
  identical(
    matched$group_labels,
    c("control", "treated", "treated")
  )
)

expect_error(
  match_heatmap_metadata(
    names(normalized_expression)[-1],
    metadata[metadata$sample_id != "sample_2", ]
  ),
  "Expression/metadata sample mismatch"
)

expect_error(
  match_heatmap_metadata(
    names(normalized_expression)[-1],
    transform(metadata, sample_id = "sample_1")
  ),
  "sample_id values must be unique"
)

expression_file <- tempfile(
  fileext = ".tsv.gz"
)

metadata_file <- tempfile(
  fileext = ".tsv"
)

heatmap_file <- tempfile(
  fileext = ".png"
)

data.table::fwrite(
  normalized_expression,
  expression_file,
  sep = "\t"
)

data.table::fwrite(
  metadata,
  metadata_file,
  sep = "\t"
)

script <- file.path(
  repository_root,
  "scripts",
  "plot_expression_heatmap.R"
)

status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "--vanilla",
    shQuote(script),
    paste0("--input=", shQuote(expression_file)),
    paste0("--metadata=", shQuote(metadata_file)),
    paste0("--output=", shQuote(heatmap_file))
  )
)

if (status != 0L) {
  stop(
    "Expression-heatmap CLI execution failed.",
    call. = FALSE
  )
}

stopifnot(
  file.exists(heatmap_file),
  file.info(heatmap_file)$size > 0
)

pass("expression heatmap metadata matching and generation")
