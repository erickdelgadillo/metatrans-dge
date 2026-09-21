include { RUN_DGE       } from '../modules/local/run_dge/main'
include { SUMMARIZE_DGE } from '../modules/local/summarize_dge/main'
include { PLOT_SUMMARY  } from '../modules/local/plot_summary/main'
include { PLOT_DGE      } from '../modules/local/plot_dge/main'

workflow DGE_WORKFLOW {

    take:
    counts
    metadata
    contrasts
    fdr
    logfc

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

    SUMMARIZE_DGE(
        RUN_DGE.out.results,
        r_sources,
        scripts_dir,
        fdr,
        logfc
    )

    PLOT_DGE(
        RUN_DGE.out.results,
        r_sources,
        scripts_dir,
        fdr,
        logfc
    )

    PLOT_SUMMARY(
        SUMMARIZE_DGE.out.summary,
        r_sources,
        scripts_dir
    )

    emit:
    results = RUN_DGE.out.results
    summary = SUMMARIZE_DGE.out.summary
    plots = PLOT_DGE.out.plots
    summary_plot = PLOT_SUMMARY.out.plot

}
