# metatrans-dge — Current Project Checkpoint

Last verified: 2026-11-02

Repository:
`erickdelgadillo/metatrans-dge`

Default branch:
`main`

Verified commit:
`b0f0ede887614adf11a4d3f6ddb3bd6571fcc741`

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

## 6. Testing and CI

The repository includes a synthetic canonical dataset and an
R regression test suite.

### Local validation — 2026-11-02

```bash
Rscript --vanilla tests/run_tests.R
```

Result: **13 of 13 test files passed**.

```bash
nextflow run . -profile test,docker -resume
```

Result: **8 of 8 Nextflow processes completed from cache**.

All eight processes reported `cached: 1`. This was not
a fresh execution.

The published synthetic output directory contained 11
nonempty files. Table headers and initial records were
inspected, including DGE statistics, normalized expression,
summary counts, and top-feature rankings.

### Continuous integration

GitHub Actions was introduced in PR #22.

The workflow runs on:

- Pull requests
- Pushes to `main`
- Manual dispatch

CI executes the R regression suite and a synthetic
Nextflow end-to-end test. It also checks expected
output tables.

### Validation limits

Synthetic testing verifies technical behavior and selected
statistical properties. It does not establish biological
validity on real metatranscriptomic datasets.

Detailed evidence:
`docs/project-context/TEST_EVIDENCE.md`.

---

## 7. Reproducibility

The repository includes:

- Nextflow DSL2 (minimum version >=24.10.0)
- Docker execution profile
- Project Dockerfile
- R 4.4.1 base image
- edgeR, data.table, ggplot2 and R.utils
- Canonical synthetic test dataset
- GitHub Actions CI

The locally tested Nextflow version on 2026-11-02
was **26.10.4**.

The Docker image is built locally as:

```text
metatrans-dge:dev
```

The tested source commit was:

```text
b0f0ede887614adf11a4d3f6ddb3bd6571fcc741
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

- R regression suite: 13/13 test files passed on 2026-11-02.
- Nextflow Docker test: 8/8 processes completed from cache.
- GitHub Actions CI implemented through PR #22.
- Synthetic output tables and figures confirmed nonempty.
- Selected table schemas and values manually inspected.

Independent real-data scientific validation remains pending
(issue #23).

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

The canonical DGE core is functionally implemented and
supported by automated synthetic regression tests.

The next development priorities are:

1. **Issue #24:** Record validation evidence and update
   the project checkpoint.
2. **Issue #23:** Validate the workflow using representative
   real metatranscriptomic data and an independent edgeR
   reference analysis.
3. **Issue #25:** Design an optional KEGG functional-enrichment
   layer with an explicit statistical universe.

Biological interpretation components should remain downstream
of the generic DGE core.

Do not treat successful synthetic CI as proof of
biological validity.
