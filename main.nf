nextflow.enable.dsl = 2

include { DGE_WORKFLOW } from './workflows/dge'

params.counts = null
params.metadata = null
params.contrasts = null

params.fdr = 0.05
params.logfc = 1

params.outdir = 'results'
params.publish_mode = 'copy'

workflow {
    if (!params.counts) {
        error "Missing required parameter --counts"
    }

    if (!params.metadata) {
        error "Missing required parameter --metadata"
    }

    if (!params.contrasts) {
        error "Missing required parameter --contrasts"
    }

    DGE_WORKFLOW(
    file(params.counts, checkIfExists: true),
    file(params.metadata, checkIfExists: true),
    file(params.contrasts, checkIfExists: true),
    params.fdr,
    params.logfc
    )
}