contrast_vector <- function(
  design,
  numerator,
  denominator
) {
  missing <- setdiff(
    c(numerator, denominator),
    colnames(design)
  )

  if (length(missing)) {
    stop(
      "Design groups are missing: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  vector <- numeric(
    ncol(design)
  )

  names(vector) <- colnames(design)

  vector[numerator] <- 1
  vector[denominator] <- -1

  vector
}


run_edger_analysis <- function(
  count_matrix,
  sample_data,
  feature_column,
  contrasts
) {
  sample_data$group <- factor(
    sample_data$group,
    levels = unique(
      as.character(sample_data$group)
    )
  )

  dge <- edgeR::DGEList(
    counts = count_matrix,
    samples = sample_data,
    group = sample_data$group
  )

  message(
    "Filtering low-expression features..."
  )

  keep <- edgeR::filterByExpr(
    dge,
    group = dge$samples$group
  )

  dge <- dge[
    keep,
    ,
    keep.lib.sizes = FALSE
  ]

  message(
    sum(keep),
    " of ",
    length(keep),
    " features retained."
  )

  dge <- edgeR::normLibSizes(
    dge,
    method = "TMM"
  )

  normalized_expression <- data.table::as.data.table(
    edgeR::cpm(
      dge,
      log = TRUE,
      prior.count = 2
    ),
    keep.rownames = feature_column
  )

  design <- stats::model.matrix(
    ~0 + group,
    data = dge$samples
  )

  colnames(design) <- levels(
    dge$samples$group
  )

  required_groups <- unique(
    c(
      contrasts$numerator,
      contrasts$denominator
    )
  )

  missing_groups <- setdiff(
    required_groups,
    colnames(design)
  )

  if (length(missing_groups)) {
    stop(
      "Contrast groups are missing from the design: ",
      paste(
        missing_groups,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  message(
    "Estimating dispersions and fitting the quasi-likelihood model..."
  )

  dispersion <- edgeR::estimateDisp(
    dge,
    design
  )

  fit <- edgeR::glmQLFit(
    dispersion,
    design
  )

  output_columns <- setdiff(
    names(contrasts),
    c(
      "numerator",
      "denominator"
    )
  )

  outputs <- vector(
    "list",
    nrow(contrasts)
  )

  for (index in seq_len(nrow(contrasts))) {

    definition <- contrasts[
      index,
      ,
      drop = FALSE
    ]

    message(
      "Testing ",
      definition$contrast,
      "..."
    )

    contrast <- contrast_vector(
      design,
      definition$numerator,
      definition$denominator
    )

    test <- edgeR::glmQLFTest(
      fit,
      contrast = contrast
    )

    table <- data.table::as.data.table(
      edgeR::topTags(
        test,
        n = Inf,
        adjust.method = "BH"
      )$table,
      keep.rownames = feature_column
    )

    for (column in output_columns) {
      table[
        ,
        (column) := definition[[column]]
      ]
    }

    outputs[[index]] <- table
  }

  statistics <- data.table::rbindlist(
    outputs,
    use.names = TRUE
  )

  list(
    statistics = statistics,
    normalized_expression = normalized_expression
  )
}


run_edger <- function(
  count_matrix,
  sample_data,
  feature_column,
  contrasts
) {
  run_edger_analysis(
    count_matrix,
    sample_data,
    feature_column,
    contrasts
  )$statistics
}