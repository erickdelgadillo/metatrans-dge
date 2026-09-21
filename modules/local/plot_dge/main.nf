process PLOT_DGE {

    publishDir params.outdir,
        mode: params.publish_mode,
        overwrite: true

    input:
    path dge_results
    path r_sources
    path scripts_dir
    val fdr
    val logfc

    output:
    path "figures/*", emit: plots

    script:
    """
    mkdir -p figures

    Rscript --vanilla ${scripts_dir}/plot_dge.R \
        --input='${dge_results}' \
        --outdir='figures' \
        --fdr='${fdr}' \
        --logfc='${logfc}'
    """

    stub:
    """
    mkdir -p figures
    touch figures/volcano.png
    touch figures/ma.png
    """
}
