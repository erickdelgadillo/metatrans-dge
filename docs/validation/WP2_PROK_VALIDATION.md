# WP2 Prok — Computational Validation

Date: 2026-11-02

Related issue: #23

## Objective

Evaluate the computational integrity and consistency of
metatrans-dge using a real marine metatranscriptomic dataset.

This validation does not reassess the biological conclusions
of the associated published study.

## Dataset

- Dataset: WP2 prokaryotic metatranscriptomes
- Samples: 18
- Experimental groups: 6
- Contrasts: 6
- Unique input features: 696,895
- Count records: 4,296,757
- Features retained for DGE: 60,696

## Input validation

The following checks passed:

- All sample identifiers matched the metadata.
- No duplicated feature-sample combinations.
- No missing count values.
- No negative counts.
- No non-integer counts.
- Design matrix rank: 6/6.
- Residual degrees of freedom: 12.

Library sizes ranged from 5,294,061 to 8,375,731 counts.

## Normalized expression

The exported normalized-expression matrix contained:

- 60,696 features.
- 18 samples.
- No missing values.
- No non-finite values.
- No duplicated feature identifiers.
- Sample order consistent with metadata.

Within-group mean Pearson correlations ranged
from 0.8854 to 0.9328.

## DGE output consistency

All six contrasts reported 60,696 tested features.

The exported DGE summaries were inspected and their
upregulated, downregulated and non-significant counts
were consistent with their reported totals.

## Experimental design limitations

The experiment used one mesocosm per treatment.

Triplicate RNA samples were obtained from subsamples
of a shared water collection at each sampling time.

These samples do not represent independent
experimental-unit replication of treatment effects.

Consequently, model-derived p-values and FDR values
should not be interpreted as independently replicated
treatment-level inference.

This limitation belongs to the experimental design,
not to the computational implementation of edgeR.

## Validation scope

Completed:

- Input integrity checks.
- Metadata consistency checks.
- Design matrix rank verification.
- Library-size inspection.
- Normalized-expression integrity checks.
- Sample-correlation inspection.
- DGE summary inspection.

Not completed:

- Independent reproduction of edgeR model results.
- Comprehensive feature-level comparison.
- Fresh end-to-end execution of the current workflow
  with the real dataset.
- Formal biological validation.

## Conclusion

The inspected real-data inputs and existing outputs
passed the documented structural and consistency checks.

The computational implementation has not yet been
independently validated against a reference edgeR analysis.

This dataset remains useful as a real-data regression
and integration test, subject to its experimental
design limitations.
