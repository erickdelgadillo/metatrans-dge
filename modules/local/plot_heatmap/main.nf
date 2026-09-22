process PLOT_HEATMAP {

    publishDir "${params.outdir}/figures",
        mode: params.publish_mode,
        overwrite: true

    input:
    path normalized_expression
    path metadata
    path r_sources
    path scripts_dir

    output:
    path "expression_heatmap.png", emit: plot

    script:
    """
    Rscript --vanilla ${scripts_dir}/plot_expression_heatmap.R \
        --input='${normalized_expression}' \
        --metadata='${metadata}' \
        --output='expression_heatmap.png'
    """

    stub:
    """
    touch expression_heatmap.png
    """
}
