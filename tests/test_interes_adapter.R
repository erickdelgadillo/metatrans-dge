#!/usr/bin/env Rscript

file_argument <- grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]
source(file.path(dirname(normalizePath(sub("^--file=", "", file_argument))), "helpers.R"))

source_metadata <- data.frame(
  sample = c(44L, 50L),
  T1 = "T1task.sort.bam",
  group = c("WP1_C_0h", "WP2_R_0h"),
  Sample = c("WP1_MESC_C_0h_R1", "WP2_MESC_R_0h_R2")
)

wp1 <- adapt_interes_metadata(source_metadata, "WP1")
wp2 <- adapt_interes_metadata(source_metadata, "WP2")
stopifnot(identical(wp1$sample_id, "C_0h_1"))
stopifnot(identical(wp2$sample_id, "R_0h_2"))
expect_error(adapt_interes_metadata(source_metadata, "WP3"), "should be one of")

prok_counts <- data.frame(
  orf = "PIIMGMLA_00003",
  sample = "44_T1task.sort.bam",
  count = 3L
)
prok_canonical <- adapt_interes_counts(prok_counts, wp1, "prokaryotes")
stopifnot(
  identical(names(prok_canonical), c("feature_id", "sample_id", "count")),
  identical(prok_canonical$feature_id, "PIIMGMLA_00003"),
  identical(prok_canonical$sample_id, "C_0h_1")
)

euk_counts <- data.frame(
  Geneid = "cds.k141_1.p1",
  sample = 13L,
  count = 1L
)
euk_metadata <- data.frame(sample = 13L, sample_id = "C_0h_1")
euk_canonical <- adapt_interes_counts(
  data.table::as.data.table(euk_counts),
  euk_metadata,
  "eukaryotes"
)
stopifnot(
  identical(euk_canonical$feature_id, "k141_1.p1"),
  identical(euk_canonical$sample_id, "C_0h_1")
)

expect_error(
  adapt_interes_counts(prok_counts, wp1[, setdiff(names(wp1), "T1")], "prokaryotes"),
  "missing required columns for prokaryotes: T1"
)
expect_error(
  adapt_interes_counts(prok_counts, rbind(wp1, wp1), "prokaryotes"),
  "raw sample IDs must be unique"
)
expect_error(
  adapt_interes_counts(transform(prok_counts, sample = "unknown"), wp1, "prokaryotes"),
  "No INTERES count samples matched the metadata"
)

pass("INTERES metadata and count adapters")
