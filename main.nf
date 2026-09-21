nextflow.enable.dsl = 2

include { DGE_WORKFLOW } from './workflows/dge'

params.input = null
params.outdir = 'results'
params.analysis_id = null
params.publish_mode = 'copy'

workflow {
    if (!params.input) {
        error "Missing required parameter --input (analysis-sheet CSV)"
    }

    DGE_WORKFLOW(
        file(params.input, checkIfExists: true),
        params.analysis_id
    )
}