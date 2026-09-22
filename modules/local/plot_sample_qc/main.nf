process PLOT_SAMPLE_QC {

    publishDir "${params.outdir}/figures",
        mode: params.publish_mode,
        overwrite: true

    input:
    path normalized_expression
    path metadata
    path r_sources
    path scripts_dir

    output:
    path "sample_mds.png", emit: mds
    path "sample_correlation.png", emit: correlation

    script:
    """
    Rscript --vanilla ${scripts_dir}/plot_sample_qc.R \
        --input='${normalized_expression}' \
        --metadata='${metadata}' \
        --outdir='.'
    """

    stub:
    """
    touch sample_mds.png
    touch sample_correlation.png
    """
}