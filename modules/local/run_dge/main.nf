process RUN_DGE {
    tag "${meta.analysis_id}"

    publishDir params.outdir, mode: params.publish_mode, overwrite: true

    input:
    tuple val(meta), path(counts), path(metadata), path(annotations), path(contrasts)
    path r_sources
    path scripts_dir

    output:
    tuple val(meta), path("${meta.analysis_id}"), emit: results

    script:
    """
    Rscript --vanilla ${scripts_dir}/run_analysis_paths.R \
        --repository-root=. \
        --analysis-id=${meta.analysis_id} \
        --adapter=${meta.adapter} \
        --organism=${meta.organism} \
        --workpackage=${meta.workpackage} \
        --counts='${counts}' \
        --metadata='${metadata}' \
        --annotations='${annotations}' \
        --contrasts='${contrasts}' \
        --feature-column=${meta.feature_column} \
        --raw-feature-column=${meta.raw_feature_column} \
        --output-name='${meta.output_name}' \
        --output-dir='${meta.analysis_id}'
    """

    stub:
    """
    mkdir -p '${meta.analysis_id}'
    touch '${meta.analysis_id}/${meta.output_name}'
    printf 'analysis_id: %s\nmode: stub\n' '${meta.analysis_id}' > '${meta.analysis_id}/run_metadata.txt'
    """
}
