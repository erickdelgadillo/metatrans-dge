# Data contract and provenance

The workflow reads the established INTERES data snapshot rather than copying
large inputs into this repository.

## Required files

```text
data root/
├── raw/
│   ├── prokaryotes/counts.tsv.gz
│   └── eukaryotes/polyA_counts.tsv.gz
├── metadata/
│   ├── prokaryotes/INTERES_Prok_samples_tags.csv
│   └── eukaryotes/INTERES_Euk_samples_tags.csv
└── processed/
    ├── prokaryotes/
    │   ├── prok_tpms_annotated.parquet
    │   └── prok_differential_expression.parquet
    └── eukaryotes/
        ├── euk_tpms_annotated.parquet
        └── euk_differential_expression.parquet
```

The two `*_differential_expression.parquet` files are used only as references
by `scripts/compare_reference.R`; they are not inputs to the DGE calculation.
The compressed raw count tables provide the count values. The TPM tables
define the curated feature universe and provide one taxonomic and functional
annotation record per feature.

## Integrity

`config/input_SHA256SUMS` records the raw counts, annotations, and metadata
used by the calculation, and
`config/reference_SHA256SUMS` records the comparison outputs. The underlying
raw counts, taxonomy, eggNOG files, and metadata were also checked byte-for-byte
against their counterparts in the archived `INTERES/Calculation` directory.
Run `scripts/validate_inputs.R` before a full analysis.

## Sample design

The source metadata contains 24 prokaryotic samples and 26 eukaryotic samples.
WP1 contains 6 prokaryotic and 9 eukaryotic samples; WP2 contains 18 and 17,
respectively.
`WP2_R+P_0h_R3` is absent from the eukaryotic metadata and count table; the
workflow preserves that unbalanced design rather than inventing a replicate.

The raw count tables contain long-format non-zero observations. Dataset
adapters map raw sample identifiers to canonical identifiers, after which the
workflow reconstructs zero-filled matrices and checks that every selected
workpackage sample is present. Duplicate feature/sample observations are
rejected rather than silently aggregated.
