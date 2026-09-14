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
      counts = file.path(data_root, "processed", organism, "prok_counts_annotated.parquet"),
      annotations = file.path(data_root, "processed", organism, "prok_tpms_annotated.parquet"),
      metadata = file.path(data_root, "metadata", organism, "INTERES_Prok_samples_tags.csv"),
      reference = file.path(data_root, "processed", organism, "prok_differential_expression.parquet"),
      output_name = "prok_differential_expression.parquet"
    ))
  }

  list(
    organism = organism,
    feature_column = "geneid",
    counts = file.path(data_root, "processed", organism, "euk_counts_annotated.parquet"),
    annotations = file.path(data_root, "processed", organism, "euk_tpms_annotated.parquet"),
    metadata = file.path(data_root, "metadata", organism, "INTERES_Euk_samples_tags.csv"),
    reference = file.path(data_root, "processed", organism, "euk_differential_expression.parquet"),
    output_name = "euk_differential_expression.parquet"
  )
}

wp2_contrasts <- function() {
  data.frame(
    contrast = c("R_vs_C_0h", "RP_vs_C_0h", "RP_vs_R_0h",
                 "R_vs_C_72h", "RP_vs_C_72h", "RP_vs_R_72h"),
    numerator = c("WP2_R_0h", "WP2_R+P_0h", "WP2_R+P_0h",
                  "WP2_R_72h", "WP2_R+P_72h", "WP2_R+P_72h"),
    denominator = c("WP2_C_0h", "WP2_C_0h", "WP2_R_0h",
                    "WP2_C_72h", "WP2_C_72h", "WP2_R_72h"),
    comparison = c("R vs C", "R+P vs C", "R+P vs R",
                   "R vs C", "R+P vs C", "R+P vs R"),
    time = c("0h", "0h", "0h", "72h", "72h", "72h"),
    stringsAsFactors = FALSE
  )
}
