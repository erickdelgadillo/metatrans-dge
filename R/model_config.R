default_model_config <- function() {
  list(
    engine = "edgeR",
    design = "group",
    test = "quasi_likelihood"
  )
}


read_model_config <- function(path = NULL) {
  defaults <- default_model_config()

  if (is.null(path)) {
    return(defaults)
  }

  if (!file.exists(path)) {
    stop(
      "Model configuration file does not exist: ",
      path,
      call. = FALSE
    )
  }

  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "Package 'yaml' is required to read model configurations.",
      call. = FALSE
    )
  }

  config <- yaml::read_yaml(path)

  if (!is.list(config) ||
      is.null(config$model) ||
      !is.list(config$model)) {
    stop(
      "Model configuration must contain a 'model' mapping.",
      call. = FALSE
    )
  }

  model <- config$model

  allowed <- names(defaults)
  unknown <- setdiff(names(model), allowed)

  if (length(unknown)) {
    stop(
      "Unknown model configuration fields: ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  for (name in names(model)) {
    value <- model[[name]]

    if (!is.character(value) ||
        length(value) != 1L ||
        is.na(value) ||
        !nzchar(trimws(value))) {
      stop(
        "Invalid value for model configuration field: ",
        name,
        call. = FALSE
      )
    }

    defaults[[name]] <- value
  }

  supported <- list(
    engine = "edgeR",
    design = "group",
    test = "quasi_likelihood"
  )

  for (name in names(supported)) {
    if (!identical(defaults[[name]], supported[[name]])) {
      stop(
        "Unsupported model configuration: ",
        name, " = ", defaults[[name]],
        call. = FALSE
      )
    }
  }

  defaults
}