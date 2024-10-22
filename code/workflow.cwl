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
  - id: clean_g
    label: "Genomic Spread Cleaner"
    doc: "Transforms user spreadsheet in preparation for KN analytics by removing noise, mapping gene names, and extracting metadata statistics"
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
  - id: clean_p
    label: "SC Pheno Spread Cleaner"
    doc: "Transforms user spreadsheet in preparation for KN analytics by removing noise, mapping gene names, and extracting metadata statistics"
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
  - id: clean_pt
    label: "GP Pheno Spread Cleaner"
    doc: "Transforms user spreadsheet in preparation for KN analytics by removing noise, mapping gene names, and extracting metadata statistics"
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
  - id: ggkn_fetch
    label: "GG KnowNet Fetcher"
    doc: "Retrieve appropriate subnetwork from KnowEnG Knowledge Network from AWS S3 storage"
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
  - id: gp_netboot
    label: ProGENI
    doc: "Network-guided gene prioritization method implementation by KnowEnG that ranks gene measurements by their correlation to observed phenotypes."
    run: gp_runner.cwl
    in:
      network_file: ggkn_fetch/output_file
      genomic_file: clean_g/output_matrix
      pheno_file: clean_pt/output_matrix
      num_bootstraps: num_bootstraps
      correlation_method: correlation_method
    out:
      - top100genes_matrix
  - id: gokn_fetch
    label: "GO KnowNet Fetcher"
    doc: "Retrieve appropriate subnetwork from KnowEnG Knowledge Network from AWS S3 storage"
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
  - id: gsc_go_drawr
    label: "GO Gene Set Char"
    doc: "Network-guided gene set characterization method implementation by KnowEnG that relates public gene sets to user gene sets"
    run: gsc_runner.cwl
    in:
      gg_network_file: ggkn_fetch/output_file
      pg_network_file: gokn_fetch/output_file
      genomic_file: gp_netboot/top100genes_matrix
      gsc_method:
        valueFrom: "DRaWR"
    out:
      - enrichment_scores
  - id: enrichments
    label: "Scatter Gene Set Char"
    doc: "Network-guided gene set characterization method implementation by KnowEnG that relates public gene sets to user gene sets"
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
  - id: clustering_wf
    label: "Scatter SampClus w/ Eval"
    doc: "Network-guided stratification of genomic subtypes."
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
  - id: top10_gather
    label: "Top10 Results"
    doc: "Get the 10 rows with the smallest value in the selected column"
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
  - id: g_c_out
    outputSource: clean_g/output_matrix
    label: "Cleaned Genomic Spread"
    doc: "Spreadsheet with columns and row headers"  
    type: File
  - id: p_c_out
    outputSource: clean_p/output_matrix
    label: "Cleaned Pheno Spread"
    doc: "Spreadsheet with columns and row headers"  
    type: File
  - id: p_t_out
    label: "Transposed Pheno Spread"
    doc: "Spreadsheet with columns and row headers"  
    outputSource: clean_pt/output_matrix
    type: File
  - id: gg_knf_out
    label: "GG KnowNet Edges"
    doc: "4 column format for subnetwork for single edge type and species"
    outputSource: ggkn_fetch/output_file
    type: File
  - id: gp_out
    label: "GP top100 Genes"
    doc: "Membership spreadsheet with phenotype columns and gene rows"
    outputSource: gp_netboot/top100genes_matrix
    type: File
  - id: go_knf_out
    label: "GO KnowNet Edges"
    doc: "4 column format for subnetwork for single edge type and species"
    outputSource: gokn_fetch/output_file
    type: File
  - id: go_gsc_out
    label: "GO GSC Scores"
    doc: "Edge format file with first three columns (user gene set, public gene set, score)"
    outputSource: gsc_go_drawr/enrichment_scores
    type: File
  - id: other_gsc_out
    label: "GSC Scores"
    doc: "Edge format file with first three columns (user gene set, public gene set, score)"
    outputSource: enrichments/gsc_drawr_out
    type:
      type: array
      items: File
  - id: sc_ce_out
    label: "Cluster Eval Results"
    doc: "Table with results of statistical tests between cluster membership and phenoyptes"  
    outputSource: clustering_wf/ce_table_out
    type:
      type: array
      items: File
  - id: sc_map_out
    label: "Cluster Membership"
    doc: "Assignment of samples to clusters"
    outputSource: clustering_wf/sc_clus_map_out
    type:
      type: array
      items: File
  - id: sc_ce_top10
    label: "top10 clusters~pheno"
    doc: "file with 10 rows with the smallest value from the selected column"
    outputSource: top10_gather/output_file
    type: File
