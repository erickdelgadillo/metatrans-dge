# Test Evidence

## Validation — 2026-11-02

### Environment

- Operating system: Ubuntu
- Git branch: docs/issue-24-validation-evidence
- Verified base commit: b0f0ede
- Nextflow version: 26.10.4
- Execution profile: test,docker

### R regression tests

Command:

```bash
Rscript --vanilla tests/run_tests.R
```

Results:

- 13 of 13 test files passed.
- Canonical input validation passed.
- Contrast direction and missing-group tests passed.
- edgeR core and normalized-expression tests passed.
- Plotting, sample QC, summary and top-feature tests passed.

### Nextflow synthetic workflow

Command:

```bash
nextflow run . -profile test,docker -resume
```

Results:

- 8 of 8 processes completed successfully using cached results.
- All eight processes reported `cached: 1`.
- This confirms cache reuse, not a fresh execution.

A previous uncached Docker execution was reported successful
on 2026-10-28 at commit 1db14c7.

### Published outputs

The synthetic output directory contained 11 nonempty files:

- dge.tsv.gz
- normalized_expression.tsv.gz
- dge_summary.tsv
- top_features.tsv
- figures/volcano.png
- figures/ma.png
- figures/dge_summary.png
- figures/top_features.png
- figures/expression_heatmap.png
- figures/sample_mds.png
- figures/sample_correlation.png

### Output inspection

The headers and initial records were inspected for:

- dge.tsv.gz
- normalized_expression.tsv.gz
- dge_summary.tsv
- top_features.tsv

Observed DGE columns:

`feature_id`, `logFC`, `logCPM`, `F`, `PValue`, `FDR`, `contrast`.

The normalized-expression table contained six sample columns:
`C_1`, `C_2`, `C_3`, `T_1`, `T_2`, `T_3`.

Synthetic contrast: `treatment_vs_control`.

DGE summary:

| Category | Features |
|---|---:|
| Upregulated | 10 |
| Downregulated | 2 |
| Not significant | 23 |
| Total tested | 35 |

The categories sum to 35.

The inspected top-feature records had positive logFC and
were labeled `up`, consistently with the contrast direction.

### Limitations

- Nextflow processes were restored from cache on 2026-11-02.
- Only table headers and initial records were manually inspected.
- Figure files were confirmed nonempty but not visually reviewed.
- Synthetic testing does not establish biological validity.
- Existing results under `results/wp2_prok` were not independently
  validated as part of this record.

Real-data scientific validation is tracked in issue #23.
