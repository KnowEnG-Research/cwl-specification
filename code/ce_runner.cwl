class: CommandLineTool
cwlVersion: v1.0
label: ClusteringEvaluation
doc: "Statistical tests to compare clustering results to phenotypes."

hints:
  - class: DockerRequirement
    dockerPull: "knowengdev/clustering_evaluation:02_15_2017"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement

inputs:
  - id: cluster_map
    label: "Cluster Mapping"
    doc: "sample names followed by their cluster assignment"
    type: File
  - id: pheno_file
    label: "Phenotypic File"
    doc: "spreadsheet of phenotypic data with samples as rows and phenotypes as columns"
    type: File

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
        echo "
        cluster_mapping_full_path: $(inputs.cluster_map.path)
        phenotype_data_full_path: $(inputs.pheno_file.path)
        results_directory: ./
        threshold: 10
        " > run_params.yml && python3 /home/src/clustering_eval.py -run_directory ./ -run_file run_params.yml

outputs:
  - id: clust_eval_table
    label: "Cluster Eval Results"
    doc: "Table with results of statistical tests between cluster membership and phenoyptes"
    outputBinding:
      glob: "clustering_evaluation_result*.tsv"
    type: File
  - id: params_yml
    label: "Configuration Parameter File"
    doc: "contains the values used in analysis"
    outputBinding:
      glob: run_params.yml
    type: File
