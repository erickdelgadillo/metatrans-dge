# Metatranscriptome DGE Workflow

![Nextflow](https://img.shields.io/badge/Nextflow-DSL2-23aa62)
![R](https://img.shields.io/badge/R-edgeR-276DC3)
![Metatranscriptomics](https://img.shields.io/badge/metatranscriptomics-DGE-6A5ACD)
![License](https://img.shields.io/badge/license-MIT-green)

A reusable **Nextflow DSL2 workflow for differential gene expression (DGE) analysis of metatranscriptomic count data**.

Differential-expression statistics are performed with **edgeR**. The workflow provides:

- canonical input validation
- TMM normalization
- `filterByExpr` filtering
- quasi-likelihood differential expression testing
- configurable contrasts
- configurable FDR and logFC thresholds
- volcano and MA plots
- DGE summaries
- top differential features
- normalized expression matrix
- global expression heatmap
- sample clustering
- sample correlation heatmap
- sample MDS visualization
- Docker-based reproducibility

---

## Input files

The workflow requires three tab-separated files.

### 1. Counts

`counts.tsv` or `counts.tsv.gz`

```text
feature_id    sample_id    count
gene_01       C_1          120
gene_01       C_2          135
gene_01       T_1          310
gene_01       T_2          287
```

Required columns:

- `feature_id`
- `sample_id`
- `count`

Counts must be non-negative integers.

---

### 2. Metadata

`metadata.tsv`

```text
sample_id    group
C_1          control
C_2          control
T_1          treatment
T_2          treatment
```

Required columns:

- `sample_id`
- `group`

Each `sample_id` must occur exactly once.

---

### 3. Contrasts

`contrasts.tsv`

```text
contrast                numerator    denominator
treatment_vs_control    treatment    control
```

Required columns:

- `contrast`
- `numerator`
- `denominator`

Positive `logFC` values indicate higher expression in the `numerator` group relative to the `denominator`.

---

# Running the workflow

## Basic execution

From the repository root:

```bash
nextflow run . \
  --counts path/to/counts.tsv.gz \
  --metadata path/to/metadata.tsv \
  --contrasts path/to/contrasts.tsv \
  --outdir results/my_analysis
```

For example, using the `wp2_prok` dataset:

```bash
nextflow run . \
  --counts data/wp2_prok/counts.tsv.gz \
  --metadata data/wp2_prok/metadata.tsv \
  --contrasts data/wp2_prok/contrasts.tsv \
  --outdir results/wp2_prok
```

---

## Running with Docker

Build the workflow container once:

```bash
docker build -t metatrans-dge:dev .
```

Then run:

```bash
nextflow run . \
  --counts data/wp2_prok/counts.tsv.gz \
  --metadata data/wp2_prok/metadata.tsv \
  --contrasts data/wp2_prok/contrasts.tsv \
  --outdir results/wp2_prok \
  -profile docker
```

Using Docker is recommended because it provides a reproducible R environment with the required packages.

---

## Significance thresholds

The default thresholds are:

```text
FDR   = 0.05
logFC = 1
```

They can be changed from the command line:

```bash
nextflow run . \
  --counts data/wp2_prok/counts.tsv.gz \
  --metadata data/wp2_prok/metadata.tsv \
  --contrasts data/wp2_prok/contrasts.tsv \
  --outdir results/wp2_prok \
  --fdr 0.01 \
  --logfc 2 \
  -profile docker
```

These thresholds are used for DGE summaries, top-feature selection, and visualization.

They do not change the underlying edgeR statistical model.

---

# Output

A typical run produces:

```text
results/wp2_prok/
├── dge.tsv.gz
├── normalized_expression.tsv.gz
├── dge_summary.tsv
├── top_features.tsv
└── figures/
    ├── volcano.png
    ├── ma.png
    ├── dge_summary.png
    ├── top_features.png
    ├── expression_heatmap.png
    ├── sample_mds.png
    └── sample_correlation.png
```

### `dge.tsv.gz`

Differential-expression results for all requested contrasts.

Typical columns include:

```text
feature_id
contrast
logFC
logCPM
PValue
FDR
```

---

### `normalized_expression.tsv.gz`

TMM-normalized logCPM expression matrix for features retained after expression filtering.

This matrix is also used for downstream sample-level visualizations.

---

### `dge_summary.tsv`

Number of:

- up-regulated features
- down-regulated features
- non-significant features
- total tested features

for each contrast.

---

### `top_features.tsv`

Highest-ranking significant differential features for each contrast.

Features are ranked using:

1. FDR
2. absolute logFC

---

# Visualizations

## Volcano plot

Shows statistical significance versus effect size for each contrast.

## MA plot

Shows logFC relative to average expression.

## DGE summary

Summarizes up-regulated, down-regulated, and non-significant features.

## Top differential features

Displays the strongest differential-expression signals for each contrast.

## Global expression heatmap

Displays the normalized expression profile across all retained features.

Features are not hierarchically clustered, allowing the workflow to scale to large metatranscriptomic datasets.

Samples are clustered according to their global expression profiles.

## Sample MDS

Provides a two-dimensional representation of sample similarity based on normalized expression profiles.

## Sample correlation

Displays pairwise Pearson correlations between samples and hierarchical sample ordering.

---

# Statistical workflow

The core DGE analysis uses edgeR:

```text
raw counts
    │
    ▼
DGEList
    │
    ▼
filterByExpr
    │
    ▼
TMM normalization
    │
    ▼
design matrix
    │
    ▼
dispersion estimation
    │
    ▼
quasi-likelihood model
    │
    ▼
glmQLFTest
    │
    ▼
Benjamini-Hochberg FDR
```

The implementation uses:

- `edgeR::filterByExpr`
- `edgeR::normLibSizes`
- `edgeR::estimateDisp`
- `edgeR::glmQLFit`
- `edgeR::glmQLFTest`
- `edgeR::topTags`

---

# Testing

A synthetic test dataset is included with the repository.

Run:

```bash
nextflow run . -profile test
```

or test the complete Docker execution:

```bash
nextflow run . -profile test,docker
```

The R test suite can also be executed independently:

```bash
Rscript --vanilla tests/run_tests.R
```

---

# Requirements

Without Docker:

- Nextflow >= 24.10
- R
- edgeR
- data.table
- ggplot2
- R.utils

With Docker:

- Nextflow
- Docker

The Docker image contains the required R environment.

---

# Workflow structure

```text
counts + metadata + contrasts
            │
            ▼
          edgeR
       ┌────┴────┐
       │         │
       │         └── normalized expression
       │                 │
       │                 ├── global heatmap
       │                 ├── sample MDS
       │                 └── sample correlation
       │
       └── DGE results
              │
              ├── summary
              ├── volcano plots
              ├── MA plots
              └── top differential features
```

---

# Future development

Future versions may incorporate optional:

- taxonomic annotations
- functional annotations
- KEGG/GO enrichment
- taxonomic summaries
- ranked functional enrichment

These components are intentionally kept separate from the current DGE core.

---

## License

MIT License.

## Author

**Erick Delgadillo-Nuño**
