class: CommandLineTool
cwlVersion: v1.0
label: "KN Spreadsheet Preprocessor"
doc: "Transforms user spreadsheet in preparation for KN analytics by removing noise, mapping gene names, and extracting metadata statistics"

hints:
  - class: DockerRequirement
    dockerPull: "mepsteindr/spreadsheet_preprocess:20170216"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement

inputs:
  - id: input_file
    label: "Original Spreadsheet"
    doc: "spreadsheet with row and column names"
    type: File
  - id: taxon
    label: "Species Taxon ID"
    doc: "the taxonomic id for the species of interest"
    type: string
  - id: spreadsheet_format
    label: "Spreadsheet Format Type"
    doc: "the keyword for different types of preprocessing, i.e genes_x_samples, genes_x_samples_check, or samples_x_phenotypes"
    type: string
  - id: output_name
    label: "Output Filename Prefix"
    doc: "the output file name of the processed data frame"
    type: string

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
        echo "
        spreadsheet_file_full_path: $(inputs.input_file.path)
        spreadsheet_format: $(inputs.spreadsheet_format)
        taxon: '$(inputs.taxon)'
        output_file_dataframe: $(inputs.output_name).df
        output_file_gene_map: $(inputs.output_name).name_map
        output_file_metadata: $(inputs.output_name).metadata
        redis_host: knowcluster06.knowhub.org
        redis_pass: KnowEnG
        redis_port: 6380
        input_delimiter: sniff
        source_hint: ''
        results_directory: ./
        output_delimiter: \\\"\\\\\t\\\"
        check_data: numeric_drop
        gene_map_two_columns: false
        gene_map_first_column_orig: true
        " > run_params.yml && python3 /home/src/preprocess/spreadsheet_preprocess.py -run_directory ./ -run_file run_params.yml

outputs:
  - id: output_matrix
    label: "Spreadsheet File"
    doc: "Spreadsheet with columns and row headers"
    outputBinding:
      glob: "$(inputs.output_name + '.df')"
    type: File
  - id: params_yml
    label: "Configuration Parameter File"
    doc: "contains the values used in analysis"
    outputBinding:
      glob: run_params.yml
    type: File
