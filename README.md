# Metatranscriptome DGE Workflow

![Nextflow](https://img.shields.io/badge/Nextflow-DSL2-23aa62)
![R](https://img.shields.io/badge/R-edgeR-276DC3)
![Metatranscriptomics](https://img.shields.io/badge/metatranscriptomics-DGE-6A5ACD)
![Status](https://img.shields.io/badge/status-active%20development-yellow)
![License](https://img.shields.io/badge/license-MIT-green)




A reusable **Nextflow DSL2 workflow for differential gene expression analysis of metatranscriptomic count data**.

Differential-expression statistics are performed with the Bioconductor package **edgeR**. This repository provides the workflow orchestration, canonical input interface, contrast handling, testing, and visualization around edgeR.

## Input

The workflow requires three tab-separated files:

### `counts.tsv`

```text
feature_id    sample_id    count
gene_01       C_1          120
gene_01       T_1          310
```

### `metadata.tsv`

```text
sample_id    group
C_1          control
T_1          treatment
```

### `contrasts.tsv`

```text
contrast                numerator    denominator
treatment_vs_control    treatment    control
```

Positive `logFC` indicates higher expression in the numerator.

## Run

```bash
nextflow run . \
  --counts counts.tsv \
  --metadata metadata.tsv \
  --contrasts contrasts.tsv
```

Test the workflow with:

```bash
nextflow run . -profile test
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
      volcano + MA plots
```

The edgeR analysis uses `filterByExpr`, TMM normalization and the quasi-likelihood framework.

## Output

```text
results/
├── dge.tsv.gz
└── figures/
    ├── volcano.png
    └── ma.png
```

## Roadmap

- [x] Canonical three-file input
- [x] edgeR DGE
- [x] Nextflow DSL2 workflow
- [x] Volcano and MA plots
- [x] Synthetic test profile
- [ ] DGE summary by contrast
- [ ] Additional visualizations
- [ ] Containers
- [ ] `nf-test` and CI
- [ ] Validation with independent datasets

## Requirements

- Nextflow >= 24.10
- R
- edgeR
- data.table
- ggplot2

## License

MIT License.

## Author

Erick Delgadillo-Nuñ


**Erick Delgadillo-Nuño**
