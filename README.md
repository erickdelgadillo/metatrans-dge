# Metatranscriptome DGE Workflow

![Nextflow](https://img.shields.io/badge/Nextflow-DSL2-23aa62)
![R](https://img.shields.io/badge/R-edgeR-276DC3)
![Metatranscriptomics](https://img.shields.io/badge/metatranscriptomics-DGE-6A5ACD)
![Status](https://img.shields.io/badge/status-active%20development-yellow)
![License](https://img.shields.io/badge/license-MIT-green)

A reusable **Nextflow DSL2 workflow for differential gene expression analysis of metatranscriptomic count data using edgeR**.

The workflow is dataset-independent and requires only three input files:

```text
counts.tsv
metadata.tsv
contrasts.tsv
```

## Input

### `counts.tsv`

Long-format raw counts:

```text
feature_id    sample_id    count
gene_01       C_1          120
gene_01       C_2          135
gene_01       T_1          310
```

Required columns:

```text
feature_id
sample_id
count
```

### `metadata.tsv`

Sample information:

```text
sample_id    group
C_1          control
C_2          control
T_1          treatment
```

Required columns:

```text
sample_id
group
```

### `contrasts.tsv`

Comparisons to test:

```text
contrast                numerator    denominator
treatment_vs_control    treatment    control
```

Required columns:

```text
contrast
numerator
denominator
```

Positive `logFC` indicates higher expression in the numerator.

## Run

```bash
nextflow run . \
  --counts counts.tsv \
  --metadata metadata.tsv \
  --contrasts contrasts.tsv
```

For the bundled synthetic test dataset:

```bash
nextflow run . -profile test
```

Reuse cached processes with:

```bash
nextflow run . -profile test -resume
```

## Workflow

```text
counts + metadata + contrasts
            │
            ▼
          edgeR
            │
            ▼
       dge.tsv.gz
            │
            ▼
      volcano + MA
```

The statistical workflow uses:

```text
filterByExpr
→ TMM normalization
→ estimateDisp
→ glmQLFit
→ glmQLFTest
→ Benjamini-Hochberg FDR
```

## Output

```text
results/
├── dge.tsv.gz
└── figures/
    ├── volcano.png
    └── ma.png
```

The DGE table contains:

```text
feature_id
logFC
logCPM
F
PValue
FDR
contrast
```

## Tests

Run the R test suite with:

```bash
Rscript --vanilla tests/run_tests.R
```

The tests cover input validation, matrix construction, contrasts, edgeR execution, the R CLI, and plotting.

## Requirements

- Nextflow >= 24.10
- R
- edgeR
- data.table
- ggplot2

The current version uses the local R environment.

## Roadmap

- [x] Canonical counts, metadata and contrasts interface
- [x] edgeR quasi-likelihood DGE
- [x] Nextflow DSL2 workflow
- [x] Volcano plots
- [x] MA plots
- [x] Synthetic test profile
- [ ] Up/down DGE summary by contrast
- [ ] Top differential features
- [ ] Configurable plotting thresholds
- [ ] Containerized execution
- [ ] `nf-test`
- [ ] Continuous integration
- [ ] Validation with independent metatranscriptomic datasets
- [ ] Interoperability with upstream metatranscriptomic workflows

## Scope

This workflow starts from an already quantified raw count table.

It does not perform read QC, assembly, annotation or quantification.

## License

MIT License.

## Author

**Erick Delgadillo-Nuño**

Marine microbial ecology · Metatranscriptomics · Bioinformatics · Nextflow
