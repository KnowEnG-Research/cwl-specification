class: CommandLineTool
cwlVersion: v1.0
label: NBS
doc: "Network-guided stratification of genomic subtypes."

hints:
  - class: DockerRequirement
    dockerPull: "knowengdev/samples_clustering_pipeline:01_31_2017"
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
  - id: num_clusters
    label: "Number of clusters"
    doc: "number of subtypes to divide the samples into"
    type: int
  - id: num_bootstraps
    label: "Number of bootstraps"
    doc: "number of times to sample the data and repeat the analysis"
    type: int

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
        echo "
        method: cc_net_nmf
        spreadsheet_name_full_path: $(inputs.genomic_file.path)
        gg_network_name_full_path: $(inputs.network_file.path)
        number_of_bootstraps: $(inputs.num_bootstraps)
        number_of_clusters: $(inputs.num_clusters)
        rwr_restart_probability: 0.5
        cols_sampling_fraction: 0.8
        results_directory: ./
        tmp_directory: ./tmp
        top_number_of_genes: 100
        processing_method: parallel
        nmf_conv_check_freq: 50
        nmf_max_invariance: 200
        nmf_max_iterations: 10000
        nmf_penalty_parameter: 1400
        rows_sampling_fraction: 1.0
        rwr_convergence_tolerence: 0.0001
        rwr_max_iterations: 100
        " > run_params.yml && python3 /home/src/samples_clustering.py -run_directory ./ -run_file run_params.yml

outputs:
  - id: samples_label_by_cluster_list
    label: "Cluster Membership"
    doc: "Assignment of samples to clusters"
    outputBinding:
      glob: "*samples_label_by_cluster_*.tsv"
    type: File
  - id: top_genes_by_cluster_matrix
    label: "Cluster top100 Genes"
    doc: "top100 genes by importance per cluster"
    outputBinding:
      glob: "*top_genes_by_cluster_*.tsv"
    type: File
  - id: params_yml
    label: "Configuration Parameter File"
    doc: "contains the values used in analysis"
    outputBinding:
      glob: run_params.yml
    type: File
