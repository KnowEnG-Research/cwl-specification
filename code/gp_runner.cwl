class: CommandLineTool
cwlVersion: v1.0
label: ProGENI
doc: "Network-guided gene prioritization method implementation by KnowEnG that ranks gene measurements by their correlation to observed phenotypes."

hints:
  - class: DockerRequirement
    dockerPull: "knowengdev/gene_prioritization_pipeline:01_20_2017"
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement

inputs:
  - id: network_file
    label: "Network File"
    doc: "gene-gene network of interactions in edge format"
    type: File
  - id: genomic_file
    label: "Genomic Spreadsheet File"
    doc: "spreadsheet of genomic data with samples as columns and genes as rows"
    type: File
  - id: pheno_file
    label: "Phenotypic File"
    doc: "spreadsheet of phenotypic data with samples as rows and phenotypes as columns"
    type: File
  - id: correlation_method
    label: "Correlation Method"
    doc: "keyword for correlation metric, i.e. t_test or pearson"
    type: string
  - id: num_bootstraps
    label: "Number of bootstraps"
    doc: "number of types to sample the data and repeat the analysis"
    type: int

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
        echo "
        correlation_measure: $(inputs.correlation_method)
        spreadsheet_name_full_path: $(inputs.genomic_file.path)
        drug_response_full_path: $(inputs.pheno_file.path)
        results_directory: ./
        drop_method: drop_NA
        method: net_correlation
        gg_network_name_full_path: $(inputs.network_file.path)
        number_of_bootstraps: $(inputs.num_bootstraps)
        top_beta_of_sort: 100
        rwr_convergence_tolerence: 0.0001
        rwr_max_iterations: 100
        rwr_restart_probability: 0.5
        " > run_params.yml && python3 /home/src/gene_prioritization.py -run_directory ./ -run_file run_params.yml

outputs:
  - id: top100genes_matrix
    label: "top100 Genes File"
    doc: "Membership spreadsheet with phenotype columns and gene rows"
    outputBinding:
      glob: "*_original.tsv"
    type: File
  - id: params_yml
    label: "Configuration Parameter File"
    doc: "contains the values used in analysis"
    outputBinding:
      glob: run_params.yml
    type: File
