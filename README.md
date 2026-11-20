# vsatheesh/plantgwas

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open_In_GitHub_Codespaces-black?labelColor=grey&logo=github)](https://github.com/codespaces/new/vsatheesh/plantgwas)
[![GitHub Actions CI Status](https://github.com/vsatheesh/plantgwas/actions/workflows/nf-test.yml/badge.svg)](https://github.com/vsatheesh/plantgwas/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/vsatheesh/plantgwas/actions/workflows/linting.yml/badge.svg)](https://github.com/vsatheesh/plantgwas/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/vsatheesh/plantgwas)

## Introduction

**plantgwas** is a reproducible [Nextflow](https://www.nextflow.io/) pipeline for genome-wide association studies (GWAS) and genomic prediction in plants. It takes a plant panel from raw genotypes to ranked candidate genes in one command, for any species that has a reference genome and a GFF3 annotation.

It accepts three kinds of input: GBS reads, whole-genome resequencing reads, or an existing VCF. All three meet at one harmonised, filtered, imputed VCF, and everything after that point is shared. Multi-locus models (FarmCPU, BLINK) are the defaults, with MLM and GLM available for comparison. Candidate-gene windows come from the LD decay of the panel itself instead of a fixed distance, and the results are collected in a single HTML report.

> [!WARNING]
> **plantgwas is under active development and is not ready for use.** The samplesheet and its validation are in place, but the analysis steps are still being built, starting with the VCF route. Parameters and outputs will change.

### Planned workflow

1. Read QC and trimming for GBS and WGS reads ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [`fastp`](https://github.com/OpenGene/fastp))
2. Alignment and variant calling (GBS and WGS routes only) ([`BWA-MEM2`](https://github.com/bwa-mem2/bwa-mem2), [`bcftools`](https://samtools.github.io/bcftools/))
3. Harmonise the VCF, then marker and sample quality control ([`bcftools`](https://samtools.github.io/bcftools/), [`PLINK 2`](https://www.cog-genomics.org/plink/2.0/))
4. Imputation without a reference panel ([`Beagle`](https://faculty.washington.edu/browning/beagle/beagle.html))
5. Phenotype processing: BLUPs or BLUEs per line
6. Population structure, kinship and LD decay
7. Association with FarmCPU, BLINK and MLM, one job per trait and model ([`GAPIT`](https://github.com/jiabowang/GAPIT))
8. Significance thresholds, peaks and candidate genes from the LD-decay window
9. HTML report ([`MultiQC`](http://multiqc.info/))

Genomic prediction (GBLUP, BayesB, RKHS and GWAS-assisted GBLUP with in-fold GWAS) is planned for version 1.0.

### Development status

| Step | Status |
| --- | --- |
| nf-core template, CI and linting | Done |
| Samplesheet with `gbs`, `wgs` and `vcf` input types, validated at launch | Done |
| Small test VCF with a known answer key | Done |
| VCF route: harmonise, marker and sample QC | In progress |
| Everything else above | Not started |

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data. The `input_type` column selects the route for each row:

`samplesheet.csv`:

```csv
sample,input_type,fastq_1,fastq_2,vcf,barcode
IR64,wgs,IR64_R1.fq.gz,IR64_R2.fq.gz,,
plate1,gbs,plate1_R1.fq.gz,,,barcodes_plate1.tsv
panel_array,vcf,,,array_panel.vcf.gz,
```

| Column | Used for | Notes |
| --- | --- | --- |
| `sample` | all rows | Name without spaces. For GBS, the plate name |
| `input_type` | all rows | `wgs`, `gbs` or `vcf` |
| `fastq_1`, `fastq_2` | `wgs`, `gbs` | Gzipped FASTQ; `fastq_2` only for paired-end WGS |
| `vcf` | `vcf` | `.vcf` or `.vcf.gz` |
| `barcode` | `gbs` | Barcode file (`.tsv` or `.txt`) for demultiplexing |

Rows of different types can be mixed. A row missing the files its type needs is rejected before anything runs. An example is in [`assets/samplesheet.csv`](assets/samplesheet.csv).

Pick the profile that matches where you run. You do not install any analysis tools yourself; Nextflow downloads them on the first run.

| Where you run | Profile |
| --- | --- |
| HPC cluster | `-profile singularity` or `-profile apptainer` |
| Laptop or workstation | `-profile docker` |
| No container engine | `-profile conda` |

The intended command, once the VCF route is complete:

```bash
nextflow run vsatheesh/plantgwas \
   -profile singularity \
   --input samplesheet.csv \
   --outdir results
```

The reference genome, annotation and phenotype parameters (`--fasta`, `--gff`, `--phenotypes`) are added as those steps are built.

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/running/run-pipelines#using-parameter-files).

## Credits

vsatheesh/plantgwas was originally written by Viswanathan Satheesh.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use vsatheesh/plantgwas for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
