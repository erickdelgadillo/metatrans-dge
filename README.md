# Metatranscriptome differential-expression workflow

Reproducible `edgeR` workflow for the prokaryotic and poly(A)-selected
eukaryotic metatranscriptomes from the INTERES mesocosm experiment. It extracts
the differential-expression calculation formerly embedded in the large
`NoRibo_counts_V7.0.1.rmd` and `PolaA_counts_V7.0.1.rmd` notebooks.

This repository contains code and provenance only. Large count and annotation
tables remain outside Git under `ProjectsData`; generated Parquet results are
ignored and can be rebuilt.

## Analysis design

Both organismal fractions use the raw INTERES count tables. Dataset-specific
adapters map their different feature and sample identifiers to the shared
`feature_id`, `sample_id`, and `count` contract before matrix construction and
edgeR analysis. The curated annotation tables define the tested feature
universe, preserving compatibility with the historical annotated inputs. WP2
remains the default workpackage and exports six contrasts:

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

WP1 uses the samples actually present in each fraction. Prokaryotes export the
`C_72h_vs_C_0h` contrast. Eukaryotes additionally export
`CA_72h_vs_C_0h` and `CA_vs_C_72h`; the workflow does not invent the absent
prokaryotic CA samples.

## Requirements

- R 4.3 or newer
- Nextflow 24.10 or newer
- Bioconductor package `edgeR`
- CRAN packages `arrow`, `data.table`, `digest`, `ggplot2`, and `tidyselect`

Install missing dependencies with:

```r
install.packages(c("arrow", "data.table", "digest", "ggplot2", "tidyselect"))
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("edgeR")
```

## Tests

Run the fast synthetic contract tests with:

```bash
Rscript --vanilla tests/run_tests.R
```

Each test file runs in a separate R session. The suite covers canonical
metadata and counts, INTERES adapters, count-matrix construction, contrast
definitions, and workflow configuration without requiring the external data
snapshot.

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

## Analysis manifest

[`config/analyses.example.csv`](config/analyses.example.csv) defines the
portable input contract consumed by Nextflow. Each row represents
one complete analysis rather than one biological sample, because each raw
count table already contains multiple samples.

| Columns | Purpose |
| --- | --- |
| `analysis_id`, `adapter` | Unique analysis name and dataset adapter |
| `organism`, `workpackage` | Biological fraction and selected experiment |
| `counts`, `metadata`, `annotations`, `contrasts` | Explicit input paths |
| `feature_column`, `raw_feature_column` | Raw and output feature conventions |
| `output_name`, `reference` | Result filename and optional reference |

Copy the example to create a workstation-specific manifest:

```bash
cp config/analyses.example.csv config/analyses.local.csv
```

`config/analyses.local.csv` is ignored by Git. Absolute paths are accepted;
relative paths are resolved from the directory containing the manifest. The R
loader validates required fields, unique analysis IDs, INTERES conventions,
and file existence. Validate a local manifest with:

```bash
Rscript --vanilla scripts/validate_analysis_sheet.R \
  --input=config/analyses.local.csv
```

Run one manifest row by its ID with:

```bash
Rscript --vanilla scripts/run_analysis.R \
  --analysis-sheet=config/analyses.local.csv \
  --analysis-id=interes_wp1_prok
```

Manifest-driven results default to `results/<analysis_id>/`. The existing
organism/workpackage CLI remains available as a compatibility wrapper.

## Nextflow workflow

The DSL2 entry point reads the analysis manifest, creates one task per row,
stages every declared input, and publishes one directory per `analysis_id`.
Run one analysis first:

```bash
nextflow run . \
  --input config/analyses.local.csv \
  --analysis_id interes_wp1_prok
```

When that succeeds, omit `--analysis_id` to run every manifest row:

```bash
nextflow run . --input config/analyses.local.csv
```

Use `-resume` after an interrupted or previously completed run so Nextflow can
reuse unchanged tasks:

```bash
nextflow run . --input config/analyses.local.csv -resume
```

Results are copied to `results/<analysis_id>/` by default. Set another
destination with `--outdir /path/to/results`. The initial local configuration
runs one DGE task at a time, with one CPU and 32 GB of memory, to avoid running
the two large organismal analyses concurrently. Executor, memory, and CPU
settings can later be overridden in an environment-specific Nextflow config.

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

WP2 is the default. Select WP1 explicitly with:

```bash
Rscript --vanilla scripts/run_dge.R --organism=prokaryotes --workpackage=WP1
Rscript --vanilla scripts/run_dge.R --organism=eukaryotes --workpackage=WP1
Rscript --vanilla scripts/run_all.R --workpackage=WP1
```

Results are written below `results/` unless `--output-dir=/path` is supplied.
WP2 retains the existing `results/<organism>/` layout; WP1 defaults to
`results/wp1/<organism>/` so the two analyses cannot overwrite each other.
Default contrast definitions are selected by workpackage and organism from
`config/contrasts/`; pass `--contrasts=/path/to/contrasts.tsv` to the run or
input-validation commands to use another validated contrast set.
Each result contains the edgeR statistics, an unambiguous contrast ID,
comparison and time labels, and the corresponding raw taxonomic and eggNOG
annotations.

To compare regenerated WP2 results with the curated reference snapshots:

```bash
Rscript --vanilla scripts/compare_reference.R --organism=prokaryotes
Rscript --vanilla scripts/compare_reference.R --organism=eukaryotes
```

The default comparison verifies structural and numerical consistency. Use
`--strict=true` only to test byte-level numerical agreement. Exact historical
P-values cannot currently be regenerated because the archived notebooks did
not preserve their edgeR/limma versions; see
[`docs/numerical-reproducibility.md`](docs/numerical-reproducibility.md).

## Preview plots

After generating and validating the DGE results, create previews for both
organismal fractions with:

```bash
Rscript --vanilla scripts/plot_dge.R
```

The command writes five figures and a significance-count table below each
`results/<organism>/figures/` directory: true volcano plots, MA plots,
up/down/not-significant counts, P-value distributions, and the top
differential features. Defaults are `FDR <= 0.05` and
`|log2 fold change| >= 1`; they can be changed, for example, with:

```bash
Rscript --vanilla scripts/plot_dge.R --fdr=0.01 --logfc=2 --top=15
```

Use `--organism=prokaryotes` or `--organism=eukaryotes` to plot only one
fraction. Add `--workpackage=WP1` to read results from the default WP1 output
tree. Plotting thresholds affect only the previews, never the DGE tables.

## Repository structure

```text
metatranscriptome-dge-workflow/
├── main.nf               # Top-level Nextflow entry point
├── nextflow.config       # Local defaults and task resources
├── workflows/            # DSL2 workflow composition
├── modules/              # Reusable Nextflow processes
├── R/                    # Input, annotation, and edgeR functions
├── config/               # Verified source checksums
├── docs/                 # Audit of the legacy notebooks
├── scripts/              # Command-line entry points
├── tests/                # Fast synthetic contract tests and runner
├── results/              # Rebuilt outputs (ignored by Git)
├── DATA.md
└── README.md
```

The paper-figure repository starts from derived tables and does not depend on
this workflow at run time. This project documents and reproduces how the
upstream DGE tables were generated.
