# metatrans-dge — Project Context

## Why this project exists

The project converts a previously dataset-specific differential-expression analysis into a reusable, reproducible workflow.

It is intended to accept generic metatranscriptomic count data plus sample metadata and explicit contrasts, run a canonical edgeR analysis, and produce both machine-readable outputs and interpretable figures.

The architectural separation is intentional:

```text
data contract
    ↓
R statistical core
    ↓
Nextflow orchestration
    ↓
summary / visualization
    ↓
optional biological interpretation
```

## Scientific origin

The workflow grew out of metatranscriptomic differential-expression analyses associated with marine microbial experiments, including phosphorus-related treatments and datasets separated into prokaryotic and eukaryotic components.

The reusable repository should not hard-code those experiments into the statistical core.

Dataset-specific biology belongs in input metadata, contrast definitions, and downstream interpretation.

## Current implementation

### R layer

Reusable functions are organized under `R/`:

- `counts.R`
- `metadata.R`
- `contrasts.R`
- `io.R`
- `edgeR_workflow.R`
- `summary.R`
- `top_features.R`
- `plotting.R`
- `expression_heatmap.R`
- `sample_qc.R`
- plotting helpers

### Script layer

CLI scripts under `scripts/` call reusable R functions for:

- DGE;
- summaries;
- top features;
- volcano / MA plots;
- expression heatmap;
- sample QC.

### Nextflow layer

`main.nf` validates the required top-level parameters and calls `DGE_WORKFLOW`.

`workflows/dge.nf` orchestrates the DGE process and all downstream summaries/plots.

### Tests

The repository includes a canonical synthetic dataset and multiple R tests.

This is an important design feature: changes should be regression-tested instead of validated only by visual inspection.

## Statistical interpretation

The workflow uses a no-intercept group design:

```text
~0 + group
```

Contrast vectors are explicitly constructed as:

```text
numerator - denominator
```

Therefore:

```text
positive logFC = higher in numerator
negative logFC = higher in denominator
```

The current core uses edgeR's quasi-likelihood framework.

Do not change to another framework or modeling strategy merely for novelty.

## Significance thresholds

Default:

```text
FDR = 0.05
|logFC| = 1
```

These are post-model thresholds for summaries, top-feature selection, and plots.

They do not change the underlying QL model.

## Dataset independence

The core should remain able to analyze multiple projects provided they satisfy the input contract.

It should not encode names such as WP1, WP2, prokaryote, eukaryote, control, river treatment, phosphorus treatment, or similar experimental labels directly into workflow logic.

Those belong in metadata and contrast files.

## Relationship with upstream workflows

`metatrans-dge` begins from count tables.

Upstream metatranscriptomic workflows may provide:

- feature counts;
- taxonomic assignments;
- KEGG/functional annotations.

`metatrans-dge` should not duplicate upstream read processing or annotation steps.

Its responsibility is differential expression and immediate QC/visualization.

## Functional enrichment direction

A likely scientifically useful downstream extension is functional enrichment using KEGG annotations.

This should consume DGE outputs plus a feature-to-function mapping rather than altering the edgeR core.

Potential conceptual interface:

```text
dge.tsv.gz
+
feature_id → KEGG mapping
        ↓
functional enrichment
        ↓
pathway/module-level interpretation
```

Keep enrichment statistically and architecturally distinct from DGE.

## Development philosophy

When extending the repository:

1. verify the real scientific need;
2. define inputs/outputs;
3. decide whether the feature belongs in the reusable core;
4. implement reusable R logic;
5. wrap it cleanly in Nextflow if workflow orchestration adds value;
6. add tests;
7. document the change.

Avoid adding features only to make the workflow look larger.

## Source of truth

For implementation details, current GitHub `main` wins over this file.

This document preserves scientific and architectural intent.
