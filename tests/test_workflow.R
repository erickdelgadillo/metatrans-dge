#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "helpers.R"))

wp2_contrasts <- read_contrasts(
  default_contrasts_file(repository_root, "WP2", "prokaryotes")
)
wp1_prok_contrasts <- read_contrasts(
  default_contrasts_file(repository_root, "WP1", "prokaryotes")
)
wp1_euk_contrasts <- read_contrasts(
  default_contrasts_file(repository_root, "WP1", "eukaryotes")
)
stopifnot(
  nrow(wp2_contrasts) == 6L,
  nrow(wp1_prok_contrasts) == 1L,
  nrow(wp1_euk_contrasts) == 3L,
  identical(
    names(wp2_contrasts),
    c("contrast", "numerator", "denominator", "comparison", "time")
  )
)

design <- diag(3)
colnames(design) <- c("A", "B", "C")
observed <- contrast_vector(design, "C", "A")
stopifnot(identical(unname(observed), c(-1, 0, 1)))
expect_error(contrast_vector(design, "D", "A"), "Design groups are missing: D")

prok_config <- organism_config("prokaryotes", "/data")
euk_config <- organism_config("eukaryotes", "/data")
stopifnot(
  identical(
    names(formals(run_dge_analysis)),
    c("config", "output_dir", "contrasts_file", "workpackage")
  ),
  identical(prok_config$raw_feature_column, "orf"),
  identical(euk_config$raw_feature_column, "Geneid"),
  grepl("/raw/prokaryotes/counts.tsv.gz$", prok_config$counts),
  grepl("/raw/eukaryotes/polyA_counts.tsv.gz$", euk_config$counts),
  grepl(
    "/results/wp1/prokaryotes$",
    default_output_dir(repository_root, "WP1", "prokaryotes")
  ),
  grepl(
    "/results/eukaryotes$",
    default_output_dir(repository_root, "WP2", "eukaryotes")
  )
)

pass("workflow configuration and contrasts")
