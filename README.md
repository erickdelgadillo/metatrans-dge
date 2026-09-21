# Metatranscriptome DGE Workflow

![Nextflow](https://img.shields.io/badge/Nextflow-DSL2-23aa62)
![R](https://img.shields.io/badge/R-edgeR-276DC3)
![Metatranscriptomics](https://img.shields.io/badge/metatranscriptomics-differential%20expression-6A5ACD)
![Status](https://img.shields.io/badge/status-active%20development-yellow)
![License](https://img.shields.io/badge/license-MIT-green)

A reusable **Nextflow DSL2 workflow for differential gene expression analysis of metatranscriptomic count data using edgeR**.

The workflow is intentionally dataset-independent. Instead of embedding experiment-specific naming conventions or adapters into the statistical engine, it operates on three small canonical input files:

```text
counts.tsv
metadata.tsv
contrasts.tsv
```

Once a dataset is represented using this contract, the same workflow can be reused without modifying the DGE implementation.

---

## Overview

The workflow separates three concerns:

```text
Input contract
     │
     ▼
Statistical analysis
     │
     ▼
Visualization
```

The current implementation performs:

- canonical input validation
- feature-by-sample count matrix construction
- low-expression filtering
- TMM normalization
- edgeR quasi-likelihood differential-expression analysis
- explicit numerator-versus-denominator contrasts
- Benjamini-Hochberg FDR correction
- compressed tabular output
- volcano plots
- MA plots
- reproducible orchestration with Nextflow DSL2

The statistical core is written in R, while Nextflow handles execution, workflow composition, caching, resource configuration, and output publication.

---

# Input contract

Only three input files are required.

## 1. Counts

Long-format raw integer counts:

```text
feature_id    sample_id    count
gene_001      sample_1     45
gene_001      sample_2     51
gene_002      sample_1     120
gene_002      sample_2     98
```

Required columns:

| Column | Description |
| --- | --- |
| `feature_id` | Unique feature identifier |
| `sample_id` | Sample identifier |
| `count` | Raw integer count |

Requirements:

- counts must be non-negative integers
- `feature_id` and `sample_id` cannot be empty
- each `feature_id` / `sample_id` combination must be unique

The workflow reconstructs the feature-by-sample matrix internally.

---

## 2. Sample metadata

Minimum sample information:

```text
sample_id    group
sample_1     control
sample_2     control
sample_3     treatment
sample_4     treatment
```

Required columns:

| Column | Description |
| --- | --- |
| `sample_id` | Sample identifier matching the counts table |
| `group` | Experimental group used by the DGE model |

Additional metadata columns are allowed.

Every sample present in the counts file must have a matching metadata entry.

---

## 3. Contrasts

Contrasts are defined explicitly:

```text
contrast                numerator    denominator
treatment_vs_control    treatment    control
```

Required columns:

| Column | Description |
| --- | --- |
| `contrast` | Unique name for the comparison |
| `numerator` | Group expected to have positive logFC values |
| `denominator` | Reference group |

Multiple contrasts can be included:

```text
contrast        numerator     denominator
B_vs_A          B             A
C_vs_A          C             A
C_vs_B          C             B
```

Positive `logFC` always means higher expression in the configured **numerator** relative to the **denominator**.

---

# Workflow

The current execution path is:

```text
counts.tsv
metadata.tsv
contrasts.tsv
      │
      ▼
    Nextflow
      │
      ▼
   RUN_DGE
      │
      ▼
Canonical R backend
      │
      ├── input validation
      ├── count matrix construction
      ├── filterByExpr
      ├── TMM normalization
      ├── design matrix
      ├── dispersion estimation
      ├── quasi-likelihood model
      └── configured contrasts
      │
      ▼
   dge.tsv.gz
      │
      ▼
   PLOT_DGE
      │
      ├── volcano.png
      └── ma.png
```

---

# Running the workflow

Run Nextflow with the three required input files:

```bash
nextflow run . \
    --counts counts.tsv \
    --metadata metadata.tsv \
    --contrasts contrasts.tsv
```

Results are written by default to:

```text
results/
```

A different output directory can be specified with:

```bash
nextflow run . \
    --counts counts.tsv \
    --metadata metadata.tsv \
    --contrasts contrasts.tsv \
    --outdir my_results
```

Nextflow caching can be reused with:

```bash
nextflow run . \
    --counts counts.tsv \
    --metadata metadata.tsv \
    --contrasts contrasts.tsv \
    -resume
```

---

# Output

The main statistical output is:

```text
results/dge.tsv.gz
```

The table contains:

```text
feature_id
logFC
logCPM
F
PValue
FDR
contrast
```

Example:

```text
feature_id    logFC    logCPM    F       PValue      FDR         contrast
gene_001      1.54     8.31      24.1    0.00001     0.0004      treatment_vs_control
gene_002     -1.17     7.92      18.4    0.00008     0.0012      treatment_vs_control
```

Visualization outputs are written to:

```text
results/figures/
├── volcano.png
└── ma.png
```

---

# Differential-expression model

The statistical workflow uses edgeR:

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
model.matrix(~0 + group)
    │
    ▼
estimateDisp
    │
    ▼
glmQLFit
    │
    ▼
glmQLFTest
    │
    ▼
Benjamini-Hochberg FDR
```

Differential expression is always calculated from **raw integer counts**.

TPM, FPKM, RPKM, or other normalized abundance estimates should not be supplied as the `count` column.

---

# Visualization

The current plotting layer produces two generic DGE diagnostics.

## Volcano plot

```text
results/figures/volcano.png
```

Displays:

- log2 fold change on the x-axis
- `-log10(FDR)` on the y-axis
- upregulated features
- downregulated features
- non-significant features

Current default significance thresholds are:

```text
FDR <= 0.05
|log2 fold change| >= 1
```

## MA plot

```text
results/figures/ma.png
```

Displays:

- average expression (`logCPM`)
- log2 fold change
- differential-expression direction

For datasets containing several contrasts, plots are automatically faceted by contrast.

---

# Running the R components directly

The R backend can also be executed without Nextflow.

## Differential expression

```bash
Rscript --vanilla scripts/run_dge.R \
    --counts=counts.tsv \
    --metadata=metadata.tsv \
    --contrasts=contrasts.tsv \
    --output=dge.tsv.gz
```

## Plotting

```bash
Rscript --vanilla scripts/plot_dge.R \
    --input=dge.tsv.gz \
    --outdir=figures
```

These command-line interfaces are useful for development, debugging, and independent validation of the R components.

---

# Test profile

The repository contains a synthetic canonical dataset under:

```text
tests/data/canonical/
```

The complete workflow can be tested with:

```bash
nextflow run . -profile test
```

This executes both:

```text
RUN_DGE
PLOT_DGE
```

and produces:

```text
results/
├── dge.tsv.gz
└── figures/
    ├── volcano.png
    └── ma.png
```

The workflow can also be tested in stub mode:

```bash
nextflow run . -profile test -stub-run
```

---

# R tests

The R test suite can be run with:

```bash
Rscript --vanilla tests/run_tests.R
```

The current tests cover:

- canonical count validation
- canonical metadata validation
- contrast validation
- count-matrix construction
- edgeR DGE execution
- command-line execution
- DGE plotting

The tests use synthetic data and do not require an external metatranscriptomic dataset.

---

# Architecture

```text
metatranscriptome-dge-workflow/
│
├── main.nf
├── nextflow.config
│
├── workflows/
│   └── dge.nf
│
├── modules/
│   └── local/
│       ├── run_dge/
│       │   └── main.nf
│       └── plot_dge/
│           └── main.nf
│
├── R/
│   ├── contrasts.R
│   ├── counts.R
│   ├── edgeR_workflow.R
│   ├── io.R
│   ├── metadata.R
│   └── plotting.R
│
├── scripts/
│   ├── run_dge.R
│   └── plot_dge.R
│
├── tests/
│   ├── data/
│   │   └── canonical/
│   └── test_*.R
│
├── results/
│
├── DESCRIPTION
├── LICENSE
└── README.md
```

The design intentionally keeps the main layers separate:

```text
Nextflow
    │
    ├── orchestration
    ├── caching
    ├── resources
    └── process composition

R
    │
    ├── input validation
    ├── statistical analysis
    └── visualization
```

---

# Design principles

## Dataset-independent core

The workflow does not contain assumptions about:

- organism
- experimental project
- sequencing campaign
- sample naming conventions
- feature annotation format
- upstream quantification software

Any dataset can be analyzed once it has been converted to the canonical:

```text
counts + metadata + contrasts
```

contract.

## Explicit contrasts

Comparison direction is never hidden inside hard-coded numerical vectors.

For:

```text
numerator = treatment
denominator = control
```

positive `logFC` means:

```text
treatment > control
```

## Modular workflow

Differential-expression analysis and plotting are separate Nextflow processes:

```text
RUN_DGE
   │
   ▼
PLOT_DGE
```

Additional analysis modules can therefore be added downstream without modifying the statistical core.

---

# Requirements

## Workflow engine

- Nextflow 24.10 or newer
- Java compatible with the installed Nextflow release

Check the installation with:

```bash
nextflow -version
```

## R

Current R dependencies are:

```text
edgeR
data.table
ggplot2
```

The current implementation uses the local R environment.

Containerized execution is planned.

---

# Development status

## Input contract

- [x] Canonical long-format count table
- [x] Canonical sample metadata
- [x] External contrast definitions
- [x] Input validation
- [x] Multiple contrasts

## Differential expression

- [x] Count-matrix construction
- [x] Low-expression filtering
- [x] TMM normalization
- [x] edgeR quasi-likelihood workflow
- [x] Explicit numerator / denominator comparisons
- [x] Benjamini-Hochberg FDR
- [x] Compressed TSV output

## Nextflow

- [x] DSL2 entry point
- [x] Dedicated workflow layer
- [x] `RUN_DGE` module
- [x] `PLOT_DGE` module
- [x] Configurable output directory
- [x] Test profile
- [x] Nextflow caching with `-resume`
- [x] Stub execution

## Visualization

- [x] Volcano plots
- [x] MA plots
- [ ] Differential-expression summary
- [ ] Up/down feature counts by contrast
- [ ] Top differential features
- [ ] P-value distributions
- [ ] Optional publication-oriented plotting outputs

## Reproducibility and portability

- [x] Dataset-independent canonical interface
- [x] Synthetic integration dataset
- [x] R unit/integration tests
- [ ] Containerized process execution
- [ ] `nf-test`
- [ ] Continuous integration
- [ ] Independent real-world dataset validation
- [ ] Large metatranscriptomic dataset validation
- [ ] Upstream workflow interoperability

---

# Roadmap

The next development stages are:

1. **Differential-expression summary**
   - count significant upregulated and downregulated features
   - generate a summary table per contrast
   - add a corresponding visualization

2. **Expand visualization**
   - top differential features
   - P-value distributions
   - configurable plotting thresholds

3. **Containerization**
   - provide reproducible R and edgeR environments
   - remove dependence on locally installed R packages

4. **Workflow testing**
   - introduce `nf-test`
   - test individual Nextflow processes and the complete workflow

5. **Continuous integration**
   - automatically execute tests on repository changes

6. **Independent dataset validation**
   - test the canonical contract with an unrelated metatranscriptomic dataset

7. **Upstream interoperability**
   - evaluate compatibility with count tables produced by established metatranscriptomic workflows

8. **Scalability**
   - evaluate performance with large feature tables and multiple contrasts

The long-term goal is to keep the interface stable:

```text
counts.tsv
metadata.tsv
contrasts.tsv
```

while allowing the internal workflow to grow with additional analysis, visualization, testing, and reproducibility features.

---

# Scope

This workflow begins from an already quantified feature-count table.

It does **not** currently perform:

- read quality control
- trimming
- assembly
- transcript prediction
- taxonomic classification
- functional annotation
- read mapping
- abundance quantification

Those operations belong upstream.

This repository focuses specifically on:

```text
quantified metatranscriptomic features
        │
        ▼
differential-expression analysis
        │
        ▼
statistical results and visualization
```

---

# License

This project is available under the [MIT License](LICENSE).

---

# Author

**Erick Delgadillo-Nuño**

Marine microbial ecology · Metatranscriptomics · Bioinformatics · Nextflow · Reproducible scientific workflows
