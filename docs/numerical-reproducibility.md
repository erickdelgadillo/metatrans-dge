# Numerical reproducibility

The curated `*_differential_expression.parquet` files in `ProjectsData` are the
authoritative paper-associated result snapshots. The archived notebooks did
not preserve an R session report, package versions, or an `renv` lockfile, so
the original versions of edgeR and limma cannot be reconstructed with
certainty.

In the validation run with R 4.6.1, edgeR 4.10.3, and limma 3.68.5, this
extracted workflow produced:

- exactly the same feature/contrast keys and row counts;
- `logCPM` values equal to floating-point precision;
- nearly identical `logFC` values (correlation above 0.99999); and
- small version-dependent changes in quasi-likelihood test statistics,
  P-values, and adjusted P-values.

| Fraction | logFC correlation | F correlation | P-value correlation | FDR correlation |
| --- | ---: | ---: | ---: | ---: |
| Prokaryotes | 0.99999845 | 0.99538346 | 0.99921880 | 0.99913849 |
| Eukaryotes | 0.99999788 | 0.98975516 | 0.99883658 | 0.99853652 |

These observations show that the input matrix, filtering, TMM normalisation,
design, and contrast directions have been reconstructed. They do not justify
claiming byte-identical reproduction of the historical statistical output.
For figures or analyses that must match the published paper exactly, use the
curated reference snapshots. For a newly generated analysis, use the outputs
from this workflow together with its `run_metadata.txt` record.

`scripts/compare_reference.R` therefore has two modes:

- the default consistency check requires identical keys and normalised
  expression values plus high correlation of the inferential statistics;
- `--strict=true` requires every compared numeric value to agree within
  `1e-10` and is expected to fail with the currently installed package versions.

The comparison command writes all correlations and absolute differences to
`results/<organism>/reference_comparison.tsv`.
