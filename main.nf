nextflow.enable.dsl = 2

include { DGE_WORKFLOW } from './workflows/dge'

params.input = null
params.outdir = 'results'
params.analysis_id = null
params.publish_mode = 'copy'

def requiredValue(row, column) {
    def value = row[column]?.toString()?.trim()
    if (!value) {
        error "Analysis sheet column '${column}' contains an empty value"
    }
    value
}

def validateRow(row) {
    def required = [
        'analysis_id', 'adapter', 'organism', 'workpackage', 'counts',
        'metadata', 'annotations', 'contrasts', 'feature_column',
        'raw_feature_column', 'output_name'
    ]
    required.each { column -> row[column] = requiredValue(row, column) }

    if (!(row.analysis_id ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
        error "Unsafe analysis_id: ${row.analysis_id}"
    }
    if (!(row.output_name ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
        error "Unsafe output_name: ${row.output_name}"
    }
    if (row.adapter != 'interes') {
        error "Unsupported adapter '${row.adapter}' for ${row.analysis_id}"
    }
    if (!(row.organism in ['prokaryotes', 'eukaryotes'])) {
        error "Unsupported organism '${row.organism}' for ${row.analysis_id}"
    }
    if (!(row.workpackage in ['WP1', 'WP2'])) {
        error "Unsupported workpackage '${row.workpackage}' for ${row.analysis_id}"
    }

    def expected = row.organism == 'prokaryotes' ? ['orf', 'orf'] : ['geneid', 'Geneid']
    if ([row.feature_column, row.raw_feature_column] != expected) {
        error "Feature columns do not match ${row.organism} for ${row.analysis_id}"
    }
    row
}

def resolveInputPath(value, baseDir) {
    def candidate = java.nio.file.Paths.get(value.toString())
    def resolved = candidate.isAbsolute() ? candidate : baseDir.resolve(candidate)
    file(resolved.normalize().toString(), checkIfExists: true)
}

workflow {
    if (!params.input) {
        error "Missing required parameter --input (analysis-sheet CSV)"
    }

    def manifest = file(params.input, checkIfExists: true)
    def manifestDir = manifest.parent

    analyses = Channel
        .of(manifest)
        .splitCsv(header: true)
        .map { row -> validateRow(row) }
        .collect()
        .flatMap { rows ->
            def ids = rows.collect { it.analysis_id }
            if (ids.size() != ids.toSet().size()) {
                error 'Analysis IDs must be unique'
            }
            rows
        }
        .filter { row -> !params.analysis_id || row.analysis_id == params.analysis_id }
        .map { row ->
            def meta = [
                analysis_id: row.analysis_id,
                adapter: row.adapter,
                organism: row.organism,
                workpackage: row.workpackage,
                feature_column: row.feature_column,
                raw_feature_column: row.raw_feature_column,
                output_name: row.output_name
            ]
            tuple(
                meta,
                resolveInputPath(row.counts, manifestDir),
                resolveInputPath(row.metadata, manifestDir),
                resolveInputPath(row.annotations, manifestDir),
                resolveInputPath(row.contrasts, manifestDir)
            )
        }
        .ifEmpty {
            error "No analyses selected${params.analysis_id ? ": ${params.analysis_id}" : ''}"
        }

    r_sources = Channel.value(file("${projectDir}/R", checkIfExists: true))
    scripts_dir = Channel.value(file("${projectDir}/scripts", checkIfExists: true))

    DGE_WORKFLOW(analyses, r_sources, scripts_dir)
}
