process RUN_DGE {

    publishDir params.outdir,
        mode: params.publish_mode,
        overwrite: true

    input:
    path counts
    path metadata
    path contrasts
    path r_sources
    path scripts_dir

    output:
    path "dge.tsv.gz", emit: results
    path "normalized_expression.tsv.gz", emit: normalized_expression

    script:
    """
    Rscript --vanilla ${scripts_dir}/run_dge.R \
    --counts='${counts}' \
    --metadata='${metadata}' \
    --contrasts='${contrasts}' \
    --output='dge.tsv.gz' \
    --normalized-output='normalized_expression.tsv.gz'
    """

    stub:
    """
    touch dge.tsv.gz
    touch normalized_expression.tsv.gz
    """
}