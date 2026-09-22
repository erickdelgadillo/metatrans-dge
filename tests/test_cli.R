source("tests/helpers.R")

output_file <- tempfile(fileext = ".tsv.gz")

script <- file.path(
  repository_root,
  "scripts",
  "run_dge.R"
)

counts <- file.path(
  repository_root,
  "tests",
  "data",
  "canonical",
  "counts.tsv"
)

metadata <- file.path(
  repository_root,
  "tests",
  "data",
  "canonical",
  "metadata.tsv"
)

contrasts <- file.path(
  repository_root,
  "tests",
  "data",
  "canonical",
  "contrasts.tsv"
)

status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "--vanilla",
    shQuote(script),
    paste0("--counts=", shQuote(counts)),
    paste0("--metadata=", shQuote(metadata)),
    paste0("--contrasts=", shQuote(contrasts)),
    paste0("--output=", shQuote(output_file))
  )
)

if (status != 0L) {
  stop("Canonical CLI execution failed.", call. = FALSE)
}

if (!file.exists(output_file)) {
  stop("Canonical CLI did not create the output file.", call. = FALSE)
}

result <- data.table::fread(
  output_file,
  data.table = FALSE
)

required_columns <- c(
  "feature_id",
  "logFC",
  "logCPM",
  "F",
  "PValue",
  "FDR",
  "contrast"
)

missing <- setdiff(
  required_columns,
  names(result)
)

if (length(missing)) {
  stop(
    "CLI output is missing columns: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

stopifnot(nrow(result) > 0)

stopifnot(
  all(result$contrast == "treatment_vs_control")
)

pass("canonical CLI")
