source("tests/helpers.R")
source(file.path(repository_root, "R", "plotting.R"))

output_dir <- tempfile("dge_plots_")
dir.create(output_dir)

dge_output <- tempfile(fileext = ".tsv.gz")

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
    paste0("--output=", shQuote(dge_output))
  )
)

if (status != 0L) {
  stop("DGE execution failed.", call. = FALSE)
}

results <- read_dge_results_for_plots(
  dge_output
)

paths <- plot_dge_results(
  results,
  output_dir
)

expected <- c(
  file.path(output_dir, "volcano.png"),
  file.path(output_dir, "ma.png")
)

if (!all(file.exists(expected))) {
  stop(
    "Plotting did not create all expected files.",
    call. = FALSE
  )
}

if (any(file.info(expected)$size == 0)) {
  stop(
    "One or more plot files are empty.",
    call. = FALSE
  )
}

pass("canonical DGE plotting")
