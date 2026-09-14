# Audit of the archived calculation notebooks

Source directory inspected: `INTERES/Calculation`.

## Selected sources

- `NoRibo_counts_V7.0.1.rmd` is the latest complete general workflow for the
  prokaryotic fraction.
- `PolaA_counts_V7.0.1.rmd` is the latest complete general workflow for the
  eukaryotic fraction.

The new implementation preserves the substantive edgeR choices from these
notebooks: `filterByExpr`, TMM normalisation, a no-intercept group design,
`estimateDisp`, `glmQLFit`, `glmQLFTest`, and Benjamini-Hochberg FDR values from
`topTags`. It starts from the final annotated WP2 count tables, which are the
only inputs that reproduce the retained-feature counts in the final outputs.

## Scripts not promoted to the main workflow

- The V6 notebooks are earlier versions that write Feather outputs.
- `NoRibo_counts_WP1.rmd` duplicates prokaryotic and eukaryotic preparation,
  DGE, and paper-figure code in one 1,613-line notebook.
- `PolaA_counts_WP1_V1.rmd` contains separate taxon-specific WP1 tests for
  Dinoflagellata, Ciliophora, and Chlorophyta. These exploratory analyses are
  outside the paper's general WP2 DGE workflow.
- `PolaA_counts_WP1_V2.Rmd` is an unfinished 123-line draft. Despite its name,
  it reads the NoRibo prokaryotic taxonomy, metadata, annotations, and counts.

No legacy notebook was deleted or modified. Their locations and original
SHA-256 hashes remain part of the audit record outside this repository.

## Corrections made during extraction

- Absolute and parent-directory output paths were replaced with a configurable
  data root and repository-local generated-results directory.
- More than thirty plotting and exploratory dependencies were reduced to four
  runtime packages.
- Contrast directions are named from numerator to denominator. The legacy
  vectors calculate `R - C`, `R+P - C`, and `R+P - R`, while some adjacent text
  labels described the reverse order.
- The six WP2 contrasts are declared once and shared between the prokaryotic
  and eukaryotic runs.
- Running the V7 block literally with all 24 prokaryotic samples retains 66,578
  ORFs. Restricting the raw table to WP2 retains 40,778. The final annotated WP2
  count table retains exactly 40,643, matching the paper-associated result.
  The equivalent eukaryotic input retains exactly 224,127 genes.
- Data validation now checks file identity, unique sample identifiers, sample
  coverage, count validity, required experimental groups, and join cardinality.
- Plot generation and phosphorus-gene summaries remain in the downstream
  paper repository rather than being mixed into DGE modelling.

## Numerical comparison with the paper snapshot

The regenerated prokaryotic and eukaryotic results have exactly the same
feature/contrast keys and `logCPM` values as the curated paper-associated
snapshots. Their `logFC` correlations exceed 0.99999. Quasi-likelihood test
statistics and P-values differ slightly under the currently installed edgeR
and limma versions. No package-version record was found with the archived
notebooks, so the reference snapshots remain authoritative for exact published
values. See `numerical-reproducibility.md` for the validation policy.
