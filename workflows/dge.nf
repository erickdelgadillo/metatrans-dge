include { RUN_DGE            } from '../modules/local/run_dge/main'
include { SUMMARIZE_DGE      } from '../modules/local/summarize_dge/main'
include { PLOT_SUMMARY       } from '../modules/local/plot_summary/main'
include { TOP_FEATURES       } from '../modules/local/top_features/main'
include { PLOT_TOP_FEATURES  } from '../modules/local/plot_top_features/main'
include { PLOT_DGE           } from '../modules/local/plot_dge/main'

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

    PLOT_SUMMARY(
        SUMMARIZE_DGE.out.summary,
        r_sources,
        scripts_dir
    )

    TOP_FEATURES(
        RUN_DGE.out.results,
        r_sources,
        scripts_dir,
        fdr,
        logfc
    )

    PLOT_TOP_FEATURES(
        TOP_FEATURES.out.top_features,
        r_sources,
        scripts_dir
    )

    PLOT_DGE(
        RUN_DGE.out.results,
        r_sources,
        scripts_dir,
        fdr,
        logfc
    )

    emit:
    results = RUN_DGE.out.results
    normalized_expression = RUN_DGE.out.normalized_expression
    summary = SUMMARIZE_DGE.out.summary
    summary_plot = PLOT_SUMMARY.out.plot
    top_features = TOP_FEATURES.out.top_features
    top_features_plot = PLOT_TOP_FEATURES.out.plot
    plots = PLOT_DGE.out.plots
    }