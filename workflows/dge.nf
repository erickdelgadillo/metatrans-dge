include { RUN_DGE } from '../modules/local/run_dge/main'

workflow DGE_WORKFLOW {
    take:
    analyses
    r_sources
    scripts_dir

    main:
    RUN_DGE(analyses, r_sources, scripts_dir)

    emit:
    results = RUN_DGE.out.results
}
