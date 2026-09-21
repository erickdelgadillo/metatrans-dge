process SUMMARIZE_DGE {

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
    path "dge_summary.tsv", emit: summary

    script:
    """
    Rscript --vanilla ${scripts_dir}/summarize_dge.R \
    --input='${dge_results}' \
    --output='dge_summary.tsv' \
    --fdr='${fdr}' \
    --logfc='${logfc}'
    """

    stub:
    """
    touch dge_summary.tsv
    """
}