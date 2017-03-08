class: Workflow
cwlVersion: v1.0
label: "GSC Paired Jobs"
doc: "Serial combination of KnowEnG tools"

inputs:
  - id: pg_edge_type
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
  - id: gg_network_file
    label: "GG Network File"
    doc: "gene-gene network of interactions in edge format"
    type: File

steps:
  pgkn_fetch:
    run: knf_runner.cwl
    in:
      network_type:
        valueFrom: "Property"
      taxon: taxon
      edge_type: pg_edge_type
      output_name:
        valueFrom: "pg_knf_out"
    out:
      - output_file
  gsc_drawr:
    run: gsc_runner.cwl
    in:
      gg_network_file: gg_network_file
      pg_network_file: pgkn_fetch/output_file
      genomic_file: genomic_file
      gsc_method:
        valueFrom: "DRaWR"
    out:
      - enrichment_scores

outputs:
  pgkn_fetch.out:
    outputSource: pgkn_fetch/output_file
    type: File
  gsc_drawr.out:
    outputSource: gsc_drawr/enrichment_scores
    type: File