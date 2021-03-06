#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

hints:
  ResourceRequirement:
    coresMin: 8
  DockerRequirement:
    dockerImageId: graph-genome-component_segmentation
    dockerFile: |
        FROM debian:stable-slim
        RUN apt-get update && apt-get install -y git python3-pip && rm -rf /var/lib/apt/lists/*
        WORKDIR /src
        RUN git clone --depth 1 https://github.com/graph-genome/component_segmentation && rm -Rf component_segmentation/data
        WORKDIR /src/component_segmentation
        RUN pip3 install --no-cache-dir -r requirements.txt
        RUN chmod a+x segmentation.py
        ENV PATH="/src/component_segmentation:${PATH}"

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement:
    listing: |
      ${ return [ { "class": "Directory",
                    "listing": inputs.bins,
                    "basename": "jsons" } ]; }

inputs:
  bins:
    type: File[]
    format: iana:application/json

  cells_per_file:
    type: int?
    label: Number of cells per file
    doc: |
      #number bins per file = #cells / #paths
      Tip: Adjust this number to get chunk files output close to 2MB.
    inputBinding:
      prefix: --cells-per-file=
      separate: false

  pangenome_sequence:
    type: File?
    format: edam:format_1929  # FASTA
    doc: |
      Fasta file containing the pangenome sequence
      generated by odgi for this graph
    inputBinding:
      prefix: --fasta=
      separate: false

arguments:
  - --out-folder=$(runtime.outdir)/results
  - --parallel-cores=$(runtime.cores)
  - --json-file=$(runtime.outdir)/jsons/*

baseCommand: segmentation.py

outputs:
  colinear_components:
    type: Directory
    outputBinding:
      glob: results

$namespaces:
  iana: https://www.iana.org/assignments/media-types/
  edam: http://edamontology.org/
$schemas:
  - http://edamontology.org/EDAM_1.18.owl
