# metatrans-dge — Current Project Checkpoint

Last verified: 2026-09-25

Repository:
`erickdelgadillo/metatrans-dge`

Default branch:
`main`

Verified commit:
`17bee955fce77db79c46ce4b70b92b02d640d697`

The current GitHub default branch is the authoritative source for implementation state.

---

## 1. Current purpose

`metatrans-dge` is a reusable Nextflow DSL2 workflow for differential gene expression analysis of metatranscriptomic count data using edgeR.

The workflow accepts standardized count, metadata, and contrast tables and produces DGE statistics, normalized expression, summaries, ranked features, and sample/feature visualizations.

---

## 2. Current input contract

### Counts

Long-format TSV/TSV.GZ:

```text
feature_id
sample_id
count
```

Counts are expected to be non-negative integers.

### Metadata

TSV with at least:

```text
sample_id
group
```

Each sample ID should occur once.

### Contrasts

TSV with:

```text
contrast
numerator
denominator
```

Positive logFC indicates higher expression in the numerator group relative to the denominator.

---

## 3. Current Nextflow architecture

```text
main.nf
   ↓
DGE_WORKFLOW
   │
   ├── RUN_DGE
   │      ├── dge.tsv.gz
   │      └── normalized_expression.tsv.gz
   │
   ├── PLOT_HEATMAP
   ├── PLOT_SAMPLE_QC
   ├── SUMMARIZE_DGE
   ├── PLOT_SUMMARY
   ├── TOP_FEATURES
   ├── PLOT_TOP_FEATURES
   └── PLOT_DGE
```

The workflow is defined in:

`workflows/dge.nf`

Local Nextflow modules currently include:

- `run_dge`
- `plot_heatmap`
- `plot_sample_qc`
- `summarize_dge`
- `plot_summary`
- `top_features`
- `plot_top_features`
- `plot_dge`

---

## 4. Statistical core

The edgeR implementation currently performs:

```text
raw counts
→ DGEList
→ filterByExpr
→ TMM normalization
→ ~0 + group design
→ estimateDisp
→ glmQLFit
→ glmQLFTest
→ topTags(adjust.method = "BH")
```

Normalized expression is exported as logCPM using:

```text
edgeR::cpm(log = TRUE, prior.count = 2)
```

The implementation supports multiple contrast definitions.

---

## 5. Current outputs

The workflow emits:

- differential-expression table;
- normalized-expression table;
- DGE summary;
- top differential features;
- volcano plots;
- MA plots;
- DGE summary plot;
- top-feature plot;
- global expression heatmap;
- sample MDS;
- sample correlation heatmap.

Default significance thresholds used by downstream summaries/plots:

```text
FDR = 0.05
|logFC| = 1
```

These thresholds do not alter the fitted edgeR model.

---

## 6. Testing already present

The repository contains:

```text
tests/data/canonical/
├── counts.tsv
├── metadata.tsv
└── contrasts.tsv
```

R tests cover areas including:

- CLI behavior;
- counts validation;
- metadata validation;
- contrasts;
- count-matrix construction;
- core DGE;
- normalized expression;
- plotting;
- expression heatmap;
- sample QC;
- summaries;
- top features.

Test runner:

```bash
Rscript --vanilla tests/run_tests.R
```

Nextflow test execution:

```bash
nextflow run . -profile test
```

Docker test execution:

```bash
nextflow run . -profile test,docker
```

Do not assume these tests passed in a new environment without executing them.

---

## 7. Reproducibility

Current repository includes:

- Nextflow version requirement `>=24.10.0`;
- Docker profile;
- project Dockerfile;
- R 4.4.1 base image;
- edgeR;
- data.table;
- ggplot2;
- R.utils;
- canonical synthetic test dataset.

Current Docker image is built locally as:

```text
metatrans-dge:dev
```

---

## 8. Current development status

### IMPLEMENTED

- standardized count input;
- metadata input;
- arbitrary contrasts;
- input checks in R;
- count-matrix construction;
- edgeR quasi-likelihood DGE;
- TMM-normalized expression;
- DGE summaries;
- top-feature extraction;
- volcano and MA plots;
- global expression heatmap;
- sample MDS;
- sample correlation;
- modular Nextflow DSL2 orchestration;
- Docker execution profile;
- synthetic canonical test data;
- R test suite.

### TESTED IN REPOSITORY

Tests are implemented for the statistical core and major plotting/data functions.

Actual pass/fail status should be re-established when working in a new environment.

### DOCUMENTED

README documents:

- input contracts;
- execution;
- Docker;
- thresholds;
- outputs;
- statistical workflow;
- testing;
- future development.

### PLANNED / OPTIONAL FUTURE LAYERS

- taxonomic annotation;
- functional annotation;
- KEGG/GO enrichment;
- taxonomic summaries;
- ranked functional enrichment.

These are intentionally downstream of the canonical DGE core.

---

## 9. Current design principles

- Keep the core DGE generic and dataset-independent.
- Keep biological interpretation layers downstream.
- Preserve explicit contrast direction.
- Preserve statistical transparency.
- Prefer modular R functions rather than monolithic scripts.
- Use Nextflow for orchestration and R for statistics.
- Extend tests whenever behavior changes.
- Do not confuse significance thresholds used for summaries with the fitted statistical model.

---

## 10. Immediate next development direction

The canonical DGE core is already substantially complete.

The next meaningful development should not be another generic DGE feature merely for size.

Priority should be to validate the workflow on real project datasets and then decide which downstream biological interpretation layer provides genuine scientific value.

A strong next extension is a separate functional-enrichment layer using existing functional annotations, especially KEGG-oriented analysis, while keeping `metatrans-dge`'s DGE core reusable.

Before implementing that extension, define its input contract and whether it belongs:

1. inside this repository as an optional downstream module, or
2. in a separate downstream analysis repository/tool.
