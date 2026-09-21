read_contrasts <- function(path) {
  if (!file.exists(path)) {
    stop("Contrast file does not exist: ", path, call. = FALSE)
  }

  contrasts <- data.table::fread(
    path,
    sep = "\t",
    header = TRUE,
    data.table = FALSE
  )

  required <- c("contrast", "numerator", "denominator")
  missing <- setdiff(required, names(contrasts))

  if (length(missing)) {
    stop(
      "Contrast file is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (!nrow(contrasts)) {
    stop("Contrast file contains no contrasts.", call. = FALSE)
  }

  contrasts[required] <- lapply(contrasts[required], function(value) {
    trimws(as.character(value))
  })

  invalid_values <- vapply(
    contrasts[required],
    function(value) anyNA(value) || any(!nzchar(value)),
    logical(1)
  )

  if (any(invalid_values)) {
    stop(
      "Contrast definitions cannot contain missing or empty required values.",
      call. = FALSE
    )
  }

  if (anyDuplicated(contrasts$contrast)) {
    duplicated_names <- unique(
      contrasts$contrast[duplicated(contrasts$contrast)]
    )

    stop(
      "Duplicated contrast names: ",
      paste(duplicated_names, collapse = ", "),
      call. = FALSE
    )
  }

  invalid <- contrasts$numerator == contrasts$denominator

  if (any(invalid)) {
    stop(
      "Contrast numerator and denominator must differ: ",
      paste(contrasts$contrast[invalid], collapse = ", "),
      call. = FALSE
    )
  }

  contrasts
}
