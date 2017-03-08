class: Workflow
cwlVersion: v1.0
label: "Complex DAG"
doc: "Non-linear combination of KnowEnG tools"

requirements:
  - class: ScatterFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  - id: gg_edge_type
    label: "Subnetwork Edge Type"
    doc: "the edge type keyword for the subnetwork of interest"
    type: string
  - id: taxon
    label: "Subnetwork Species ID"
    doc: "the taxonomic id for the species of interest"
    type: string
    default: "9606"
  - id: genomic_file
    doc: "spreadsheet of genomic data with samples as columns and genes as rows"
    label: "Genomic Spreadsheet File"
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
  - id: pg_edge_types
    label: "Subnetwork Edge Type"
    doc: "the edge type keyword for the subnetwork of interest"
    type:
      type: array
      items: string
  - id: num_clusters_array
    label: "Number of clusters"
    doc: "number of subtypes to divide the samples into"
    type:
      type: array
      items: int

steps:
  clean_g:
    run: sspp_runner.cwl
    in:
      input_file: genomic_file
      output_name:
        valueFrom: "clean_g_out"
      spreadsheet_format:
        valueFrom: "genes_x_samples_check"
      taxon: taxon
    out:
      - output_matrix
  clean_p:
    run: sspp_runner.cwl
    in:
      input_file: pheno_file
      output_name:
        valueFrom: "clean_p_out"
      spreadsheet_format:
        valueFrom: "samples_x_phenotypes"
      taxon: taxon
    out:
      - output_matrix
  clean_pt:
    run: sspp_runner.cwl
    in:
      input_file: pheno_file
      output_name:
        valueFrom: "clean_pt_out"
      spreadsheet_format:
        valueFrom: "samples_x_phenotypes_transpose"
      taxon: taxon
    out:
      - output_matrix
  ggkn_fetch:
    run: knf_runner.cwl
    in:
      network_type:
        valueFrom: "Gene"
      taxon: taxon
      edge_type: gg_edge_type
      output_name:
        valueFrom: "gg_knf_out"
    out:
      - output_file
  gp_netboot:
    run: gp_runner.cwl
    in:
      network_file: ggkn_fetch/output_file
      genomic_file: clean_g/output_matrix
      pheno_file: clean_pt/output_matrix
      num_bootstraps: num_bootstraps
      correlation_method: correlation_method
    out:
      - top100genes_matrix
  gokn_fetch:
    run: knf_runner.cwl
    in:
      network_type:
        valueFrom: "Property"
      taxon: taxon
      edge_type:
        valueFrom: "gene_ontology"
      output_name:
        valueFrom: "go_knf_out"
    out:
      - output_file
  gsc_go_drawr:
    run: gsc_runner.cwl
    in:
      gg_network_file: ggkn_fetch/output_file
      pg_network_file: gokn_fetch/output_file
      genomic_file: gp_netboot/top100genes_matrix
      gsc_method:
        valueFrom: "DRaWR"
    out:
      - enrichment_scores
  enrichments:
    run: workflow.gsc.cwl
    scatter: pg_edge_type
    in:
      pg_edge_type: pg_edge_types
      gg_network_file: ggkn_fetch/output_file
      taxon: taxon
      genomic_file: gp_netboot/top100genes_matrix
      gsc_method:
        valueFrom: "DRaWR"
    out:
      - gsc_drawr_out
  clustering_wf:
    run: workflow.sc.cwl
    scatter: num_clusters
    in:
      num_bootstraps: num_bootstraps
      network_file: ggkn_fetch/output_file
      num_clusters: num_clusters_array
      genomic_file: clean_g/output_matrix
      pheno_file: clean_p/output_matrix
    out:
      - sc_clus_map_out
      - ce_table_out
  top10_gather:
    run: top10_runner.cwl
    in:
      infile_array: clustering_wf/ce_table_out
      sort_col:
        valueFrom: "6"
      exclude_pattern:
        valueFrom: "_dropna"
    out:
      - output_file

outputs:
  g_c_out:
    outputSource: clean_g/output_matrix
    type: File
  p_c_out:
    outputSource: clean_p/output_matrix
    type: File
  p_t_out:
    outputSource: clean_pt/output_matrix
    type: File
  gg_knf_out:
    outputSource: ggkn_fetch/output_file
    type: File
  gp_out:
    outputSource: gp_netboot/top100genes_matrix
    type: File
  go_knf_out:
    outputSource: gokn_fetch/output_file
    type: File
  go_gsc_out:
    outputSource: gsc_go_drawr/enrichment_scores
    type: File
  other_gsc_out:
    outputSource: enrichments/gsc_drawr_out
    type:
      type: array
      items: File
  sc_ce_out:
    outputSource: clustering_wf/ce_table_out
    type:
      type: array
      items: File
  sc_map_out:
    outputSource: clustering_wf/sc_clus_map_out
    type:
      type: array
      items: File
  sc_ce_top10:
    outputSource: top10_gather/output_file
    type: File
