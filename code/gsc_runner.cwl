class: CommandLineTool
cwlVersion: v1.0
label: Gene Set Characterization
doc: "Network-guided gene set characterization method implementation by KnowEnG that relates public gene sets to user gene sets"

hints:
  - class: DockerRequirement
    dockerPull: "knowengdev/geneset_characterization_pipeline:01_31_2017"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement

inputs:
  - id: pg_network_file
    label: "PG Network File"
    doc: "property-gene network of interactions in edge format"
    type: File
  - id: gg_network_file
    label: "GG Network File"
    doc: "gene-gene network of interactions in edge format"
    type: File
  - id: genomic_file
    label: "Genomic Spreadsheet File"
    doc: "spreadsheet of genomic data with samples as columns and genes as rows"
    type: File
  - id: gsc_method
    label: "GSC Method"
    doc: "which method to use for GSC, i.e. DRaWR, fisher"
    type: string

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
        tail -n+2 $(inputs.genomic_file.path) |  awk '{print \$1\"\\t\"\$1}' > dummy.map &&
        echo "
        spreadsheet_name_full_path: $(inputs.genomic_file.path)
        pg_network_name_full_path: $(inputs.pg_network_file.path)
        gene_names_map: dummy.map
        results_directory: ./
        method: $(inputs.gsc_method)
        gg_network_name_full_path: $(inputs.pg_network_file.path)
        rwr_convergence_tolerence: 0.0001
        rwr_max_iterations: 500
        rwr_restart_probability: 0.5
        " >> run_params.yml &&
        python3 /home/src/geneset_characterization.py -run_directory ./ -run_file run_params.yml

outputs:
  - id: enrichment_scores
    label: "GSC Enrichment Scores"
    doc: "Edge format file with first three columns (user gene set, public gene set, score)"
    outputBinding:
      glob:  "*_sorted_by_property_score_*"
    type: File
  - id: params_yml
    label: "Configuration Parameter File"
    doc: "contains the values used in analysis"
    outputBinding:
      glob: run_params.yml
    type: File
