include { RUN_DGE  } from '../modules/local/run_dge/main'
include { PLOT_DGE } from '../modules/local/plot_dge/main'

workflow DGE_WORKFLOW {

    take:
    counts
    metadata
    contrasts

    main:

    r_sources = Channel.value(
        file("${projectDir}/R", checkIfExists: true)
    )

    scripts_dir = Channel.value(
        file("${projectDir}/scripts", checkIfExists: true)
    )

    RUN_DGE(
        counts,
        metadata,
        contrasts,
        r_sources,
        scripts_dir
    )

    PLOT_DGE(
    RUN_DGE.out.results,
    r_sources,
    scripts_dir
    )

    emit:
    results = RUN_DGE.out.results
    plots = PLOT_DGE.out.plots
}