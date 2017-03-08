class: CommandLineTool
cwlVersion: v1.0
label: "top10"
doc: "Get the 10 rows with the smallest value in the selected column"

hints:
  - class: DockerRequirement
    dockerPull: "cblatti3/py3_slim:0.1"
requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement

inputs:
  - id: infile_array
    label: "Infile Array"
    doc: "array of files with same format to examine"
    type:
      type: array
      items: File
  - id: sort_col
    label: "Sort Column"
    doc: "column to sort the data by"
    type: string
  - id: exclude_pattern
    label: "Exclude Pattern"
    doc: "remove rows with the following pattern"
    type: string

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
        ${ var list = ""; for (var i = 0; i < inputs.infile_array.length; i ++) { list += " cp " + inputs.infile_array[i].path + " " + i + ".txt &&"; } return list; }
        grep -v $(inputs.exclude_pattern) ${ var list = ""; for (var i = 0; i < inputs.infile_array.length; i ++) { list += i + ".txt "; } return list; } | sort -gk$(inputs.sort_col) | head > top10.txt

outputs:
  - id: output_file
    label: "top10 file"
    doc: "file with 10 rows with the smallest value from the selected column"
    outputBinding:
      glob: "top10.txt"
    type: File
