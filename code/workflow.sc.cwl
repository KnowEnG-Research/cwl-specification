class: Workflow
cwlVersion: v1.0
label: "SC w/ Evaluation"
doc: "Serial combination of KnowEnG tools"

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
  - id: pheno_file
    label: "Phenotypic File"
    doc: "spreadsheet of phenotypic data with samples as rows and phenotypes as columns"
    type: File

steps:
  clustering:
    run: sc_runner.cwl
    in:
      network_file: network_file
      genomic_file: genomic_file
      num_bootstraps: num_bootstraps
      num_clusters: num_clusters
    out:
      - samples_label_by_cluster_list
  clus_eval:
    run: ce_runner.cwl
    in:
      cluster_map: clustering/samples_label_by_cluster_list
      pheno_file: pheno_file
    out:
      - clust_eval_table

outputs:
  sc_clus_map_out:
    outputSource: clustering/samples_label_by_cluster_list
    type: File
  ce_table_out:
    outputSource: clus_eval/clust_eval_table
    type: File
