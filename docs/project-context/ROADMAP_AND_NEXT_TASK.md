# metatrans-dge — Roadmap and Next Task

## Current state

The canonical reusable DGE workflow is already functional and comparatively mature.

The current architecture provides:

```text
counts + metadata + contrasts
        ↓
edgeR QL DGE
        ├── DGE results
        ├── normalized expression
        ├── summaries
        ├── top features
        ├── volcano / MA plots
        ├── global heatmap
        ├── MDS
        └── sample correlation
```

## NOW

### 1. Validate on real project datasets

Use representative real datasets rather than expanding the core immediately.

Verify:

- input conversion;
- sample/metadata matching;
- contrasts;
- expected direction of logFC;
- output scalability;
- figure usefulness;
- runtime and memory behavior.

Keep dataset-specific transformations outside the generic core unless they generalize.

### 2. Confirm the next scientific layer

The main candidate is functional enrichment using KEGG annotations.

Before coding, define:

```text
DGE output
+
feature-to-KEGG mapping
→ enrichment input contract
→ enrichment statistics
→ pathway/module outputs
```

Decide whether this becomes:

- an optional downstream module in `metatrans-dge`, or
- a separate downstream repository/tool.

## NEXT

If KEGG enrichment is adopted:

- define background universe correctly;
- support contrast-specific significant/ranked features;
- keep enrichment direction-aware where appropriate;
- produce machine-readable enrichment tables;
- create a small number of scientifically useful plots;
- add synthetic tests.

Potential later extensions:

- GO enrichment;
- taxonomy-aware summaries;
- functional composition summaries;
- ranked enrichment methods.

## NOT A PRIORITY

Do not currently:

- replace edgeR without a scientific reason;
- add raw-read processing;
- duplicate functionality already handled by upstream metatranscriptomic workflows;
- hard-code INTERES/WP1/WP2/prok/euk experimental labels;
- add complex dashboards before scientific outputs are stable;
- merge taxonomic and functional interpretation into the statistical DGE core.

## Definition of a good next feature

A new feature should:

1. answer a real biological question;
2. use the existing canonical outputs cleanly;
3. remain reusable across datasets;
4. have a clear statistical interpretation;
5. be testable;
6. not destabilize the DGE core.
