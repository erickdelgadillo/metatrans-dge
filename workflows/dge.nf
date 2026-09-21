include { RUN_DGE } from '../modules/local/run_dge/main'


def requiredValue(row, column) {
    def value = row[column]?.toString()?.trim()

    if (!value) {
        error "Analysis sheet column '${column}' contains an empty value"
    }

    value
}


def validateRow(row) {
    def required = [
        'analysis_id',
        'adapter',
        'organism',
        'workpackage',
        'counts',
        'metadata',
        'annotations',
        'contrasts',
        'feature_column',
        'raw_feature_column',
        'output_name'
    ]

    required.each { column ->
        row[column] = requiredValue(row, column)
    }

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

    def expected = row.organism == 'prokaryotes' ?
        ['orf', 'orf'] :
        ['geneid', 'Geneid']

    if ([row.feature_column, row.raw_feature_column] != expected) {
        error "Feature columns do not match ${row.organism} for ${row.analysis_id}"
    }

    row
}


def resolveInputPath(value, baseDir) {
    def candidate = java.nio.file.Paths.get(value.toString())

    def resolved = candidate.isAbsolute() ?
        candidate :
        baseDir.resolve(candidate)

    file(
        resolved.normalize().toString(),
        checkIfExists: true
    )
}


workflow DGE_WORKFLOW {

    take:
    manifest
    analysis_id

    main:

    manifest_dir = manifest.parent

    analyses = Channel
        .of(manifest)
        .splitCsv(header: true)
        .map { row ->
            validateRow(row)
        }
        .collect()
        .flatMap { rows ->

            def ids = rows.collect {
                it.analysis_id
            }

            if (ids.size() != ids.toSet().size()) {
                error 'Analysis IDs must be unique'
            }

            rows
        }
        .filter { row ->
            !analysis_id || row.analysis_id == analysis_id
        }
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
                resolveInputPath(row.counts, manifest_dir),
                resolveInputPath(row.metadata, manifest_dir),
                resolveInputPath(row.annotations, manifest_dir),
                resolveInputPath(row.contrasts, manifest_dir)
            )
        }
        .ifEmpty {
            error "No analyses selected${analysis_id ? ": ${analysis_id}" : ''}"
        }

    r_sources = Channel.value(
        file("${projectDir}/R", checkIfExists: true)
    )

    scripts_dir = Channel.value(
        file("${projectDir}/scripts", checkIfExists: true)
    )

    RUN_DGE(
        analyses,
        r_sources,
        scripts_dir
    )

    emit:
    results = RUN_DGE.out.results
}