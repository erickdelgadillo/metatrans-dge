# Data contract and provenance

The workflow reads the established INTERES data snapshot rather than copying
large inputs into this repository.

## Required files

```text
data root/
├── metadata/
│   ├── prokaryotes/INTERES_Prok_samples_tags.csv
│   └── eukaryotes/INTERES_Euk_samples_tags.csv
└── processed/
    ├── prokaryotes/
    │   ├── prok_counts_annotated.parquet
    │   ├── prok_tpms_annotated.parquet
    │   └── prok_differential_expression.parquet
    └── eukaryotes/
        ├── euk_counts_annotated.parquet
        ├── euk_tpms_annotated.parquet
        └── euk_differential_expression.parquet
```

The two `*_differential_expression.parquet` files are used only as references
by `scripts/compare_reference.R`; they are not inputs to the DGE calculation.
The count tables drive edgeR, while the TPM tables provide one curated
taxonomic and functional annotation record per feature.

## Integrity

`config/input_SHA256SUMS` records the verified calculation inputs and
`config/reference_SHA256SUMS` records the comparison outputs. The underlying
raw counts, taxonomy, eggNOG files, and metadata were also checked byte-for-byte
against their counterparts in the archived `INTERES/Calculation` directory.
Run `scripts/validate_inputs.R` before a full analysis.

## Sample design

The source metadata contains 24 prokaryotic samples and 26 eukaryotic samples.
The paper DGE input contains the 18 prokaryotic and 17 eukaryotic WP2 samples.
`WP2_R+P_0h_R3` is absent from the eukaryotic metadata and count table; the
workflow preserves that unbalanced design rather than inventing a replicate.

The annotated count tables contain long-format non-zero observations. The
workflow aggregates any repeated feature/sample entries, reconstructs
zero-filled matrices, and checks that every WP2 metadata sample is present.
`filterByExpr` retains 40,643 prokaryotic ORFs and 224,127 eukaryotic genes in
the verified snapshot.
