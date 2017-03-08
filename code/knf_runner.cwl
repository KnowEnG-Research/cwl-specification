class: CommandLineTool
cwlVersion: v1.0
label: "Knowledge Network Fetcher"
doc: "Retrieve appropriate subnetwork from KnowEnG Knowledge Network from AWS S3 storage"

hints:
  - class: DockerRequirement
    dockerPull: "cblatti3/aws:0.1"
requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: aws_access_key_id
    label: "AWS Access Key ID"
    doc: "the aws access key id"
    type: string
    default: AKIAIVLADKCGCVGHNLIA
  - id: aws_secret_access_key
    label: "AWS Secret Access Key"
    doc: "the aws secrety access key"
    type: string
    default: z1QYuHnp3IT9ajUrMXQo3ON0f4t4Uq58IjE0yLnJ
  - id: bucket
    label: "AWS S3 Bucket Name"
    doc: "the aws s3 bucket"
    type: string
    default: "KnowNets/KN-6rep-1611/userKN-6rep-1611"
  - id: network_type
    label: "Subnetwork Class"
    doc: "the type of subnetwork"
    type: string
    default: Gene
  - id: taxon
    label: "Subnetwork Species ID"
    doc: "the taxonomic id for the species of interest"
    type: string
    default: "9606"
  - id: edge_type
    label: "Subnetwork Edge Type"
    doc: "the edge type keyword for the subnetwork of interest"
    type: string
    default: PPI_physical_association
  - id: output_name
    label: "Output Filename"
    doc: "the output file name to save the contents of the key to"
    type: string
    default: KN.4col.edge

baseCommand:
  - s3cmd
arguments:
  - prefix: "--access_key"
    valueFrom: $(inputs.aws_access_key_id)
  - prefix: "--secret_key"
    valueFrom: $(inputs.aws_secret_access_key)
  - valueFrom: sync
  - valueFrom: "$('s3://' + inputs.bucket + '/' + inputs.network_type + '/' + inputs.taxon + '/' + inputs.edge_type + '/')"
  - valueFrom: "./"

outputs:
  - id: output_file
    label: "Subnetwork Edge File"
    doc: "4 column format for subnetwork for single edge type and species"
    outputBinding:
      glob: "*.edge"
    type: File
