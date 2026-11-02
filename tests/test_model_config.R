source("tests/helpers.R")
source("R/model_config.R")

# Default configuration
defaults <- read_model_config()

stopifnot(
  identical(
    defaults,
    list(
      engine = "edgeR",
      design = "group",
      test = "quasi_likelihood"
    )
  )
)

# Explicit configuration
explicit <- read_model_config(
  "config/model.group.yml"
)

stopifnot(
  identical(defaults, explicit)
)

# Helper for testing temporary YAML configurations
check_invalid_config <- function(content, pattern) {
  path <- tempfile(fileext = ".yml")
  on.exit(unlink(path), add = TRUE)

  writeLines(content, path)

  expect_error(
    read_model_config(path),
    pattern
  )
}

# Missing file
expect_error(
  read_model_config("missing-model-config.yml"),
  "does not exist"
)

# Missing model section
check_invalid_config(
  "settings:\n  engine: edgeR",
  "must contain a 'model' mapping"
)

# Unknown field
check_invalid_config(
  "model:\n  engine: edgeR\n  unknown: value",
  "Unknown model configuration fields"
)

# Empty value
check_invalid_config(
  "model:\n  engine: ''",
  "Invalid value"
)

# Unsupported engine
check_invalid_config(
  "model:\n  engine: DESeq2",
  "Unsupported model configuration"
)

# Unsupported design
check_invalid_config(
  "model:\n  design: factorial",
  "Unsupported model configuration"
)

# Unsupported statistical test
check_invalid_config(
  "model:\n  test: likelihood_ratio",
  "Unsupported model configuration"
)

# Malformed YAML
check_invalid_config(
  "model: [invalid",
  "Parser error"
)

pass("model configuration validation")