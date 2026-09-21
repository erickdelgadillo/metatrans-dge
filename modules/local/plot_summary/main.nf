process PLOT_SUMMARY {

    publishDir "${params.outdir}/figures",
        mode: params.publish_mode,
        overwrite: true

    input:
    path dge_summary
    path r_sources
    path scripts_dir

    output:
    path "dge_summary.png", emit: plot

    script:
    """
    Rscript --vanilla ${scripts_dir}/plot_summary.R \
        --input='${dge_summary}' \
        --output='dge_summary.png'
    """

    stub:
    """
    touch dge_summary.png
    """
}