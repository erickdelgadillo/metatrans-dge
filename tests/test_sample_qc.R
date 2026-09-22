source("tests/helpers.R")
source(
  file.path(
    repository_root,
    "R",
    "sample_qc.R"
  )
)

counts <- data.table::fread(
  file.path(
    repository_root,
    "tests",
    "data",
    "canonical",
    "counts.tsv"
  ),
  data.table = FALSE
)

metadata <- data.table::fread(
  file.path(
    repository_root,
    "tests",
    "data",
    "canonical",
    "metadata.tsv"
  ),
  data.table = FALSE
)

contrasts <- read_contrasts(
  file.path(
    repository_root,
    "tests",
    "data",
    "canonical",
    "contrasts.tsv"
  )
)

prepared <- build_count_matrix(
  counts,
  metadata
)

analysis <- run_edger_analysis(
  prepared$counts,
  prepared$samples,
  "feature_id",
  contrasts
)

normalized_expression <- analysis$normalized_expression

similarity <- compute_sample_similarity(
  normalized_expression
)

correlation <- similarity$correlation

stopifnot(
  identical(
    dim(correlation),
    c(
      nrow(metadata),
      nrow(metadata)
    )
  )
)

stopifnot(
  identical(
    colnames(correlation),
    metadata$sample_id
  )
)

stopifnot(
  identical(
    rownames(correlation),
    metadata$sample_id
  )
)

stopifnot(
  all(is.finite(correlation))
)

stopifnot(
  isTRUE(
    all.equal(
      correlation,
      t(correlation),
      tolerance = 1e-12
    )
  )
)

stopifnot(
  all(
    abs(diag(correlation) - 1) < 1e-12
  )
)

mds <- compute_sample_mds(
  similarity$distance
)

stopifnot(
  nrow(mds) == nrow(metadata)
)

stopifnot(
  setequal(
    mds$sample_id,
    metadata$sample_id
  )
)

stopifnot(
  all(
    is.finite(mds$MDS1)
  )
)

stopifnot(
  all(
    is.finite(mds$MDS2)
  )
)

output_dir <- tempfile(
  pattern = "sample_qc_"
)

dir.create(
  output_dir
)

mds_output <- file.path(
  output_dir,
  "sample_mds.png"
)

correlation_output <- file.path(
  output_dir,
  "sample_correlation.png"
)

plot_sample_mds(
  mds,
  metadata,
  mds_output
)

plot_sample_correlation(
  correlation,
  metadata,
  correlation_output
)

stopifnot(
  file.exists(mds_output)
)

stopifnot(
  file.info(mds_output)$size > 0
)

stopifnot(
  file.exists(correlation_output)
)

stopifnot(
  file.info(correlation_output)$size > 0
)

pass("sample QC")