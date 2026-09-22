process TOP_FEATURES {

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
    path "top_features.tsv", emit: top_features

    script:
    """
    Rscript --vanilla ${scripts_dir}/top_features.R \
        --input='${dge_results}' \
        --output='top_features.tsv' \
        --fdr='${fdr}' \
        --logfc='${logfc}' \
        --top_n='40'
    """

    stub:
    """
    touch top_features.tsv
    """
}