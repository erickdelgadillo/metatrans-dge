# Metatranscriptome DGE Workflow

![Nextflow](https://img.shields.io/badge/Nextflow-DSL2-23aa62)
![R](https://img.shields.io/badge/R-edgeR-276DC3)
![Metatranscriptomics](https://img.shields.io/badge/metatranscriptomics-differential%20expression-6A5ACD)
![Status](https://img.shields.io/badge/status-active%20development-yellow)
![License](https://img.shields.io/badge/license-MIT-green)

A reproducible **Nextflow DSL2 workflow for metatranscriptomic differential gene expression analysis with edgeR**.

The project originated from the INTERES marine metatranscriptomic analyses and is being progressively refactored from paper-specific R notebooks into a modular and reusable workflow.

The current implementation supports prokaryotic and poly(A)-selected eukaryotic count tables, dataset-specific input adaptation, configurable contrasts, reproducible edgeR analysis, and manifest-driven execution through Nextflow.

---

## Overview

The workflow separates three concerns:

- **dataset-specific input handling**
- **statistical differential-expression analysis**
- **workflow orchestration**

Raw count tables and sample metadata are first transformed into a shared internal representation:

```text
feature_id    sample_id    count
```

This canonical contract allows the statistical engine to remain independent of the original feature naming and sample conventions.

The current INTERES implementation supports:

- prokaryotic metatranscriptomes
- poly(A)-selected eukaryotic metatranscriptomes
- WP1 bacterial-suppression experiments
- WP2 phosphorus-manipulation experiments
- configurable contrasts
- raw integer counts as the primary DGE input
- curated taxonomic and functional annotation
- manifest-driven Nextflow execution

---

## Current workflow

The current analysis flow is:

```text
Analysis manifest
       │
       ▼
   Nextflow DSL2
       │
       ▼
 dataset adapter
       │
       ▼
Canonical count contract
feature_id | sample_id | count
       │
       ▼
Count matrix construction
       │
       ▼
      edgeR
       │
       ├── filterByExpr
       ├── TMM normalization
       ├── dispersion estimation
       ├── quasi-likelihood model
       └── configured contrasts
       │
       ▼
Annotated DGE results
       │
       ▼
results/<analysis_id>/
```

Differential expression is calculated from **raw integer counts**, never TPM values.

Positive `logFC` always represents higher expression in the configured numerator relative to the denominator.

---

## Analysis design

### WP1 — bacterial suppression

The available contrasts depend on the organismal fraction represented in the experiment.

#### Prokaryotes

```text
C_72h vs C_0h
```

#### Eukaryotes

```text
C_72h  vs C_0h
CA_72h vs C_0h
CA_72h vs C_72h
```

The workflow uses only biological groups actually present in the corresponding dataset.

### WP2 — phosphorus manipulation

Both organismal fractions use the same six contrasts:

| Contrast | Numerator | Denominator |
| --- | --- | --- |
| `R_vs_C_0h` | River | Control |
| `RP_vs_C_0h` | River + P | Control |
| `RP_vs_R_0h` | River + P | River |
| `R_vs_C_72h` | River | Control |
| `RP_vs_C_72h` | River + P | Control |
| `RP_vs_R_72h` | River + P | River |

Contrast definitions are stored independently from the statistical engine under:

```text
config/contrasts/
```

This allows new experimental comparisons to be introduced without modifying the edgeR implementation.

---

## Architecture

The project currently uses a Nextflow DSL2 entry point, workflow layer, and local process modules.

```text
main.nf
   │
   ▼
workflows/
└── dge.nf
       │
       ▼
modules/local/
└── run_dge/
    └── main.nf
       │
       ▼
R analysis backend
```

The current `RUN_DGE` process executes the complete R differential-expression backend.

Dataset-specific transformations are handled separately through adapters:

```text
R/
├── adapters/
│   └── interes.R
│
├── metadata.R
├── counts.R
├── io.R
├── analysis_sheet.R
├── edgeR_workflow.R
└── plotting.R
```

The longer-term design is to keep the statistical model in R while using Nextflow for orchestration, reproducibility, execution environments, caching, and downstream workflow composition.

---

## Analysis manifest

The primary Nextflow interface is a CSV analysis manifest.

An example is provided at:

```text
config/analyses.example.csv
```

Each row represents one complete DGE analysis.

Current fields include:

| Field | Purpose |
| --- | --- |
| `analysis_id` | Unique identifier for the analysis |
| `adapter` | Dataset-specific input adapter |
| `organism` | Organismal fraction |
| `workpackage` | Experimental design |
| `counts` | Raw count table |
| `metadata` | Sample metadata |
| `annotations` | Curated feature annotations |
| `contrasts` | Contrast definition file |
| `feature_column` | Standard output feature identifier |
| `raw_feature_column` | Feature identifier in the raw table |
| `output_name` | Result filename |
| `reference` | Optional historical reference result |

Create a workstation-specific manifest with:

```bash
cp config/analyses.example.csv config/analyses.local.csv
```

The local manifest is ignored by Git.

Absolute paths are supported, while relative paths are resolved from the manifest location.

---

## Running with Nextflow

Run a single configured analysis:

```bash
nextflow run . \
    --input config/analyses.local.csv \
    --analysis_id interes_wp1_prok
```

Run every analysis defined in the manifest:

```bash
nextflow run . \
    --input config/analyses.local.csv
```

Reuse cached tasks after a previous or interrupted execution:

```bash
nextflow run . \
    --input config/analyses.local.csv \
    -resume
```

Results are written by default to:

```text
results/<analysis_id>/
```

A different output directory can be specified with:

```bash
--outdir /path/to/results
```

---

## R command-line interface

The underlying R workflow can also be executed independently from Nextflow.

Run WP2:

```bash
Rscript --vanilla scripts/run_dge.R \
    --organism=prokaryotes

Rscript --vanilla scripts/run_dge.R \
    --organism=eukaryotes
```

Run WP1:

```bash
Rscript --vanilla scripts/run_dge.R \
    --organism=prokaryotes \
    --workpackage=WP1

Rscript --vanilla scripts/run_dge.R \
    --organism=eukaryotes \
    --workpackage=WP1
```

The R interface is retained both for development and for validating the statistical backend independently from Nextflow.

---

## Input contract

Dataset-specific adapters must eventually produce the canonical long-format representation:

```text
feature_id    sample_id    count
```

Sample metadata must provide at minimum:

```text
sample_id    group
```

Additional metadata columns can be retained without modifying the core edgeR implementation.

The current INTERES adapters normalize the original prokaryotic and eukaryotic sample conventions into this shared representation.

This contract is intended to become the interface for additional metatranscriptomic datasets and upstream workflows.

---

## Differential-expression model

The current edgeR workflow uses:

```text
DGEList
   ↓
filterByExpr
   ↓
TMM normalization
   ↓
model.matrix(~0 + group)
   ↓
estimateDisp
   ↓
glmQLFit
   ↓
glmQLFTest
   ↓
Benjamini-Hochberg FDR
```

Contrasts are defined externally using explicit numerator and denominator groups.

This prevents contrast direction from being hidden inside hard-coded numerical vectors.

---

## Tests

Fast synthetic contract tests can be run with:

```bash
Rscript --vanilla tests/run_tests.R
```

The current test suite covers:

- canonical sample metadata
- canonical count tables
- INTERES input adapters
- count-matrix construction
- contrast definitions
- analysis-manifest validation
- workflow configuration

The tests do not require the full external metatranscriptomic dataset.

Current test files include:

```text
tests/
├── helpers.R
├── run_tests.R
├── test_analysis_sheet.R
├── test_count_matrix.R
├── test_counts.R
├── test_interes_adapter.R
├── test_metadata.R
└── test_workflow.R
```

---

## Result validation

Regenerated WP2 results can be compared with the curated historical reference tables.

```bash
Rscript --vanilla scripts/compare_reference.R \
    --organism=prokaryotes

Rscript --vanilla scripts/compare_reference.R \
    --organism=eukaryotes
```

The comparison checks feature/contrast identity and numerical consistency.

Small differences in inferential statistics can occur because the historical notebooks did not preserve the exact edgeR and limma package versions used during the original analysis.

See:

```text
docs/numerical-reproducibility.md
```

for details.

---

## Preview plots

DGE results can currently be summarized using:

```bash
Rscript --vanilla scripts/plot_dge.R
```

Generated diagnostics include:

- volcano plots
- MA plots
- differential-expression counts
- P-value distributions
- top differential features

Default thresholds are:

```text
FDR <= 0.05
|log2 fold change| >= 1
```

They can be changed without affecting the underlying statistical results.

---

## Repository structure

```text
metatranscriptome-dge-workflow/
├── main.nf                     # Nextflow DSL2 entry point
├── nextflow.config             # Execution configuration
│
├── workflows/
│   └── dge.nf                  # DGE workflow composition
│
├── modules/
│   └── local/
│       └── run_dge/
│           └── main.nf         # Current DGE process
│
├── R/
│   ├── adapters/
│   │   └── interes.R           # INTERES-specific input adaptation
│   ├── analysis_sheet.R
│   ├── config.R
│   ├── counts.R
│   ├── edgeR_workflow.R
│   ├── io.R
│   ├── metadata.R
│   └── plotting.R
│
├── scripts/                    # Command-line R entry points
│
├── config/
│   ├── analyses.example.csv
│   └── contrasts/
│
├── tests/                      # Synthetic contract tests
├── docs/                       # Reproducibility and legacy-analysis notes
├── results/                    # Generated outputs, ignored by Git
│
├── DATA.md
├── DESCRIPTION
├── LICENSE
└── README.md
```

---

## Requirements

### Workflow engine

- Nextflow 24.10 or newer
- Java compatible with the installed Nextflow release

### R

- R 4.3 or newer
- edgeR
- arrow
- data.table
- digest
- ggplot2
- tidyselect

Check Nextflow with:

```bash
nextflow -version
```

Run the R test suite with:

```bash
Rscript --vanilla tests/run_tests.R
```

The current implementation uses the local R environment. Containerized process execution is planned.

---

## Development status

### Statistical backend

- [x] edgeR quasi-likelihood workflow
- [x] Explicit named contrasts
- [x] TMM normalization
- [x] Raw-count input
- [x] Annotation integration
- [x] WP1 support
- [x] WP2 support

### Input model

- [x] Canonical count contract
- [x] Canonical sample metadata
- [x] INTERES prokaryotic adapter
- [x] INTERES eukaryotic adapter
- [x] Manifest-driven analysis configuration
- [ ] Additional dataset adapters

### Nextflow

- [x] DSL2 entry point
- [x] Workflow layer
- [x] Local `RUN_DGE` process
- [x] Manifest-driven analyses
- [x] Nextflow caching with `-resume`
- [ ] Slim top-level `main.nf`
- [ ] Expanded DGE workflow composition
- [ ] Plotting module
- [ ] Reference-comparison module
- [ ] Containerized execution
- [ ] nf-test integration
- [ ] Continuous integration

### Portability

- [x] Dataset-specific input adaptation
- [x] External contrast definitions
- [x] Configurable input paths
- [ ] Second independent metatranscriptomic dataset
- [ ] Upstream `nf-core/metatdenovo` interoperability
- [ ] Generalized adapter interface

---

## Development roadmap

The next development stage focuses on strengthening the Nextflow architecture rather than changing the statistical model.

Planned priorities are:

1. Simplify `main.nf` so it acts primarily as the pipeline entry point.
2. Move workflow composition into `workflows/dge.nf`.
3. Separate plotting and reference comparison into Nextflow processes.
4. Add reproducible process containers.
5. Introduce `nf-test` for process and workflow testing.
6. Add continuous integration.
7. Validate the canonical input contract using an independent metatranscriptomic dataset.
8. Test interoperability with outputs from `nf-core/metatdenovo`.

The statistical edgeR backend should remain independent from dataset-specific adapters.

A central design goal is that supporting a new dataset should require a new input adapter rather than changes to the DGE engine.

---

## Purpose

This repository serves two complementary purposes.

### Scientific reproducibility# Metatranscriptome DGE Workflow

![Nextflow](https://img.shields.io/badge/Nextflow-DSL2-23aa62)
![R](https://img.shields.io/badge/R-edgeR-276DC3)
![Metatranscriptomics](https://img.shields.io/badge/metatranscriptomics-differential%20expression-6A5ACD)
![Status](https://img.shields.io/badge/status-active%20development-yellow)
![License](https://img.shields.io/badge/license-MIT-green)

A reproducible **Nextflow DSL2 workflow for metatranscriptomic differential gene expression analysis with edgeR**.

The project originated from the INTERES marine metatranscriptomic analyses and is being progressively refactored from paper-specific R notebooks into a modular and reusable workflow.

The current implementation supports prokaryotic and poly(A)-selected eukaryotic count tables, dataset-specific input adaptation, configurable contrasts, reproducible edgeR analysis, and manifest-driven execution through Nextflow.

---

## Overview

The workflow separates three concerns:

- **dataset-specific input handling**
- **statistical differential-expression analysis**
- **workflow orchestration**

Raw count tables and sample metadata are first transformed into a shared internal representation:

```text
feature_id    sample_id    count
```

This canonical contract allows the statistical engine to remain independent of the original feature naming and sample conventions.

The current INTERES implementation supports:

- prokaryotic metatranscriptomes
- poly(A)-selected eukaryotic metatranscriptomes
- WP1 bacterial-suppression experiments
- WP2 phosphorus-manipulation experiments
- configurable contrasts
- raw integer counts as the primary DGE input
- curated taxonomic and functional annotation
- manifest-driven Nextflow execution

---

## Current workflow

The current analysis flow is:

```text
Analysis manifest
       │
       ▼
   Nextflow DSL2
       │
       ▼
 dataset adapter
       │
       ▼
Canonical count contract
feature_id | sample_id | count
       │
       ▼
Count matrix construction
       │
       ▼
      edgeR
       │
       ├── filterByExpr
       ├── TMM normalization
       ├── dispersion estimation
       ├── quasi-likelihood model
       └── configured contrasts
       │
       ▼
Annotated DGE results
       │
       ▼
results/<analysis_id>/
```

Differential expression is calculated from **raw integer counts**, never TPM values.

Positive `logFC` always represents higher expression in the configured numerator relative to the denominator.

---

## Analysis design

### WP1 — bacterial suppression

The available contrasts depend on the organismal fraction represented in the experiment.

#### Prokaryotes

```text
C_72h vs C_0h
```

#### Eukaryotes

```text
C_72h  vs C_0h
CA_72h vs C_0h
CA_72h vs C_72h
```

The workflow uses only biological groups actually present in the corresponding dataset.

### WP2 — phosphorus manipulation

Both organismal fractions use the same six contrasts:

| Contrast | Numerator | Denominator |
| --- | --- | --- |
| `R_vs_C_0h` | River | Control |
| `RP_vs_C_0h` | River + P | Control |
| `RP_vs_R_0h` | River + P | River |
| `R_vs_C_72h` | River | Control |
| `RP_vs_C_72h` | River + P | Control |
| `RP_vs_R_72h` | River + P | River |

Contrast definitions are stored independently from the statistical engine under:

```text
config/contrasts/
```

This allows new experimental comparisons to be introduced without modifying the edgeR implementation.

---

## Architecture

The project currently uses a Nextflow DSL2 entry point, workflow layer, and local process modules.

```text
main.nf
   │
   ▼
workflows/
└── dge.nf
       │
       ▼
modules/local/
└── run_dge/
    └── main.nf
       │
       ▼
R analysis backend
```

The current `RUN_DGE` process executes the complete R differential-expression backend.

Dataset-specific transformations are handled separately through adapters:

```text
R/
├── adapters/
│   └── interes.R
│
├── metadata.R
├── counts.R
├── io.R
├── analysis_sheet.R
├── edgeR_workflow.R
└── plotting.R
```

The longer-term design is to keep the statistical model in R while using Nextflow for orchestration, reproducibility, execution environments, caching, and downstream workflow composition.

---

## Analysis manifest

The primary Nextflow interface is a CSV analysis manifest.

An example is provided at:

```text
config/analyses.example.csv
```

Each row represents one complete DGE analysis.

Current fields include:

| Field | Purpose |
| --- | --- |
| `analysis_id` | Unique identifier for the analysis |
| `adapter` | Dataset-specific input adapter |
| `organism` | Organismal fraction |
| `workpackage` | Experimental design |
| `counts` | Raw count table |
| `metadata` | Sample metadata |
| `annotations` | Curated feature annotations |
| `contrasts` | Contrast definition file |
| `feature_column` | Standard output feature identifier |
| `raw_feature_column` | Feature identifier in the raw table |
| `output_name` | Result filename |
| `reference` | Optional historical reference result |

Create a workstation-specific manifest with:

```bash
cp config/analyses.example.csv config/analyses.local.csv
```

The local manifest is ignored by Git.

Absolute paths are supported, while relative paths are resolved from the manifest location.

---

## Running with Nextflow

Run a single configured analysis:

```bash
nextflow run . \
    --input config/analyses.local.csv \
    --analysis_id interes_wp1_prok
```

Run every analysis defined in the manifest:

```bash
nextflow run . \
    --input config/analyses.local.csv
```

Reuse cached tasks after a previous or interrupted execution:

```bash
nextflow run . \
    --input config/analyses.local.csv \
    -resume
```

Results are written by default to:

```text
results/<analysis_id>/
```

A different output directory can be specified with:

```bash
--outdir /path/to/results
```

---

## R command-line interface

The underlying R workflow can also be executed independently from Nextflow.

Run WP2:

```bash
Rscript --vanilla scripts/run_dge.R \
    --organism=prokaryotes

Rscript --vanilla scripts/run_dge.R \
    --organism=eukaryotes
```

Run WP1:

```bash
Rscript --vanilla scripts/run_dge.R \
    --organism=prokaryotes \
    --workpackage=WP1

Rscript --vanilla scripts/run_dge.R \
    --organism=eukaryotes \
    --workpackage=WP1
```

The R interface is retained both for development and for validating the statistical backend independently from Nextflow.

---

## Input contract

Dataset-specific adapters must eventually produce the canonical long-format representation:

```text
feature_id    sample_id    count
```

Sample metadata must provide at minimum:

```text
sample_id    group
```

Additional metadata columns can be retained without modifying the core edgeR implementation.

The current INTERES adapters normalize the original prokaryotic and eukaryotic sample conventions into this shared representation.

This contract is intended to become the interface for additional metatranscriptomic datasets and upstream workflows.

---

## Differential-expression model

The current edgeR workflow uses:

```text
DGEList
   ↓
filterByExpr
   ↓
TMM normalization
   ↓
model.matrix(~0 + group)
   ↓
estimateDisp
   ↓
glmQLFit
   ↓
glmQLFTest
   ↓
Benjamini-Hochberg FDR
```

Contrasts are defined externally using explicit numerator and denominator groups.

This prevents contrast direction from being hidden inside hard-coded numerical vectors.

---

## Tests

Fast synthetic contract tests can be run with:

```bash
Rscript --vanilla tests/run_tests.R
```

The current test suite covers:

- canonical sample metadata
- canonical count tables
- INTERES input adapters
- count-matrix construction
- contrast definitions
- analysis-manifest validation
- workflow configuration

The tests do not require the full external metatranscriptomic dataset.

Current test files include:

```text
tests/
├── helpers.R
├── run_tests.R
├── test_analysis_sheet.R
├── test_count_matrix.R
├── test_counts.R
├── test_interes_adapter.R
├── test_metadata.R
└── test_workflow.R
```

---

## Result validation

Regenerated WP2 results can be compared with the curated historical reference tables.

```bash
Rscript --vanilla scripts/compare_reference.R \
    --organism=prokaryotes

Rscript --vanilla scripts/compare_reference.R \
    --organism=eukaryotes
```

The comparison checks feature/contrast identity and numerical consistency.

Small differences in inferential statistics can occur because the historical notebooks did not preserve the exact edgeR and limma package versions used during the original analysis.

See:

```text
docs/numerical-reproducibility.md
```

for details.

---

## Preview plots

DGE results can currently be summarized using:

```bash
Rscript --vanilla scripts/plot_dge.R
```

Generated diagnostics include:

- volcano plots
- MA plots
- differential-expression counts
- P-value distributions
- top differential features

Default thresholds are:

```text
FDR <= 0.05
|log2 fold change| >= 1
```

They can be changed without affecting the underlying statistical results.

---

## Repository structure

```text
metatranscriptome-dge-workflow/
├── main.nf                     # Nextflow DSL2 entry point
├── nextflow.config             # Execution configuration
│
├── workflows/
│   └── dge.nf                  # DGE workflow composition
│
├── modules/
│   └── local/
│       └── run_dge/
│           └── main.nf         # Current DGE process
│
├── R/
│   ├── adapters/
│   │   └── interes.R           # INTERES-specific input adaptation
│   ├── analysis_sheet.R
│   ├── config.R
│   ├── counts.R
│   ├── edgeR_workflow.R
│   ├── io.R
│   ├── metadata.R
│   └── plotting.R
│
├── scripts/                    # Command-line R entry points
│
├── config/
│   ├── analyses.example.csv
│   └── contrasts/
│
├── tests/                      # Synthetic contract tests
├── docs/                       # Reproducibility and legacy-analysis notes
├── results/                    # Generated outputs, ignored by Git
│
├── DATA.md
├── DESCRIPTION
├── LICENSE
└── README.md
```

---

## Requirements

### Workflow engine

- Nextflow 24.10 or newer
- Java compatible with the installed Nextflow release

### R

- R 4.3 or newer
- edgeR
- arrow
- data.table
- digest
- ggplot2
- tidyselect

Check Nextflow with:

```bash
nextflow -version
```

Run the R test suite with:

```bash
Rscript --vanilla tests/run_tests.R
```

The current implementation uses the local R environment. Containerized process execution is planned.

---

## Development status

### Statistical backend

- [x] edgeR quasi-likelihood workflow
- [x] Explicit named contrasts
- [x] TMM normalization
- [x] Raw-count input
- [x] Annotation integration
- [x] WP1 support
- [x] WP2 support

### Input model

- [x] Canonical count contract
- [x] Canonical sample metadata
- [x] INTERES prokaryotic adapter
- [x] INTERES eukaryotic adapter
- [x] Manifest-driven analysis configuration
- [ ] Additional dataset adapters

### Nextflow

- [x] DSL2 entry point
- [x] Workflow layer
- [x] Local `RUN_DGE` process
- [x] Manifest-driven analyses
- [x] Nextflow caching with `-resume`
- [ ] Slim top-level `main.nf`
- [ ] Expanded DGE workflow composition
- [ ] Plotting module
- [ ] Reference-comparison module
- [ ] Containerized execution
- [ ] nf-test integration
- [ ] Continuous integration

### Portability

- [x] Dataset-specific input adaptation
- [x] External contrast definitions
- [x] Configurable input paths
- [ ] Second independent metatranscriptomic dataset
- [ ] Upstream `nf-core/metatdenovo` interoperability
- [ ] Generalized adapter interface

---

## Development roadmap

The next development stage focuses on strengthening the Nextflow architecture rather than changing the statistical model.

Planned priorities are:

1. Simplify `main.nf` so it acts primarily as the pipeline entry point.
2. Move workflow composition into `workflows/dge.nf`.
3. Separate plotting and reference comparison into Nextflow processes.
4. Add reproducible process containers.
5. Introduce `nf-test` for process and workflow testing.
6. Add continuous integration.
7. Validate the canonical input contract using an independent metatranscriptomic dataset.
8. Test interoperability with outputs from `nf-core/metatdenovo`.

The statistical edgeR backend should remain independent from dataset-specific adapters.

A central design goal is that supporting a new dataset should require a new input adapter rather than changes to the DGE engine.

---

## Purpose

This repository serves two complementary purposes.

### Scientific reproducibility

It reconstructs and documents the differential-expression workflow used for the INTERES marine metatranscriptomic analyses from the original R-based analysis environment.

### Workflow engineering

It is being developed into a reusable bioinformatics workflow demonstrating:

- Nextflow DSL2
- scientific workflow modularization
- canonical data contracts
- dataset adapters
- edgeR differential-expression analysis
- reproducible execution
- automated testing
- workflow portability

The project is intentionally being developed incrementally so that each architectural layer can be understood and validated before additional complexity is introduced.

---

## License

This project is available under the [MIT License](LICENSE).

---

## Author

**Erick Delgadillo-Nuño**

Marine microbial ecology · Metatranscriptomics · Bioinformatics · Nextflow · Reproducible scientific workflows

It reconstructs and documents the differential-expression workflow used for the INTERES marine metatranscriptomic analyses from the original R-based analysis environment.

### Workflow engineering

It is being developed into a reusable bioinformatics workflow demonstrating:

- Nextflow DSL2
- scientific workflow modularization
- canonical data contracts
- dataset adapters
- edgeR differential-expression analysis
- reproducible execution
- automated testing
- workflow portability

The project is intentionally being developed incrementally so that each architectural layer can be understood and validated before additional complexity is introduced.

---

## License

This project is available under the [MIT License](LICENSE).

---

## Author

**Erick Delgadillo-Nuño**

Marine microbial ecology · Metatranscriptomics · Bioinformatics · Nextflow · Reproducible scientific workflows
