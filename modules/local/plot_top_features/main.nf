process PLOT_TOP_FEATURES {

    publishDir "${params.outdir}/figures",
        mode: params.publish_mode,
        overwrite: true

    input:
    path top_features
    path r_sources
    path scripts_dir

    output:
    path "top_features.png", emit: plot

    script:
    """
    Rscript --vanilla ${scripts_dir}/plot_top_features.R \
        --input='${top_features}' \
        --output='top_features.png'
    """

    stub:
    """
    touch top_features.png
    """
}