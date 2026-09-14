# Metatranscriptome differential-expression workflow

Reproducible `edgeR` workflow for the prokaryotic and poly(A)-selected
eukaryotic metatranscriptomes from the INTERES mesocosm experiment. It extracts
the differential-expression calculation formerly embedded in the large
`NoRibo_counts_V7.0.1.rmd` and `PolaA_counts_V7.0.1.rmd` notebooks.

This repository contains code and provenance only. Large count and annotation
tables remain outside Git under `ProjectsData`; generated Parquet results are
ignored and can be rebuilt.

## Analysis design

Both organismal fractions use the final annotated WP2 count tables for
expression filtering, TMM normalisation, dispersion estimation, and
quasi-likelihood model fitting. This is the input state that reproduces the
paper-associated DGE snapshots. The exported results contain six contrasts:

| Contrast ID | Numerator | Denominator |
| --- | --- | --- |
| `R_vs_C_0h` | river, 0 h | control, 0 h |
| `RP_vs_C_0h` | river + P, 0 h | control, 0 h |
| `RP_vs_R_0h` | river + P, 0 h | river, 0 h |
| `R_vs_C_72h` | river, 72 h | control, 72 h |
| `RP_vs_C_72h` | river + P, 72 h | control, 72 h |
| `RP_vs_R_72h` | river + P, 72 h | river, 72 h |

Positive `logFC` therefore means higher expression in the numerator. This
explicit direction removes the ambiguity in the comments and labels of the
legacy notebooks.

## Requirements

- R 4.3 or newer
- Bioconductor package `edgeR`
- CRAN packages `arrow`, `data.table`, `digest`, and `tidyselect`

Install missing dependencies with:

```r
install.packages(c("arrow", "data.table", "digest", "tidyselect"))
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("edgeR")
```

## Data location

On the original workstation, no configuration is required. The default data
root is:

```text
/home/erick/Data/ProjectsData/marine-p-deficiency-metat/data
```

Elsewhere, set `INTERES_DATA_ROOT` to a directory with the layout documented in
[`DATA.md`](DATA.md):

```bash
export INTERES_DATA_ROOT=/path/to/marine-p-deficiency-metat/data
```

## Run

First verify the source snapshot:

```bash
Rscript --vanilla scripts/validate_inputs.R
```

Run one fraction or both:

```bash
Rscript --vanilla scripts/run_dge.R --organism=prokaryotes
Rscript --vanilla scripts/run_dge.R --organism=eukaryotes
Rscript --vanilla scripts/run_all.R
```

Results are written below `results/` unless `--output-dir=/path` is supplied.
Each result contains the edgeR statistics, an unambiguous contrast ID,
comparison and time labels, and the corresponding raw taxonomic and eggNOG
annotations.

To compare a regenerated result with the curated reference snapshot:

```bash
Rscript --vanilla scripts/compare_reference.R --organism=prokaryotes
Rscript --vanilla scripts/compare_reference.R --organism=eukaryotes
```

The default comparison verifies structural and numerical consistency. Use
`--strict=true` only to test byte-level numerical agreement. Exact historical
P-values cannot currently be regenerated because the archived notebooks did
not preserve their edgeR/limma versions; see
[`docs/numerical-reproducibility.md`](docs/numerical-reproducibility.md).

## Repository structure

```text
metatranscriptome-dge-workflow/
├── R/                    # Input, annotation, and edgeR functions
├── config/               # Verified source checksums
├── docs/                 # Audit of the legacy notebooks
├── scripts/              # Command-line entry points
├── tests/                # Fast synthetic smoke test
├── results/              # Rebuilt outputs (ignored by Git)
├── DATA.md
└── README.md
```

The paper-figure repository starts from derived tables and does not depend on
this workflow at run time. This project documents and reproduces how the
upstream DGE tables were generated.
