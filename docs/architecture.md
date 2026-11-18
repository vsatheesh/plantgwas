# Plant GWAS Pipeline — Design & Architecture

Nov 12, 2026 · @Viswanathan Satheesh

## Overview

We will build a Nextflow (DSL2, nf-core template) pipeline that takes any plant panel from raw genotypes to ranked candidate genes in one command. Working name: **plantgwas**.

It accepts three kinds of input: GBS reads (FASTQ), whole-genome resequencing reads (FASTQ), or an existing VCF from a SNP array or earlier calling. All three meet at one harmonised, filtered, imputed VCF. Everything after that point is shared.

**Goals**

- One pipeline for any plant species with a reference genome and a GFF3 annotation.
- Multi-locus models (FarmCPU, BLINK) as defaults, with MLM and GLM available for comparison.
- Candidate genes from LD-decay windows estimated from the panel itself, not a fixed distance.
- Reproducible: every tool in a pinned container; `-resume` after any failure; runs locally, on SLURM, or in the cloud.
- A single HTML report a breeder can read without opening a terminal.

**Not for version 1**

- Calling variants without a reference genome (k-mer GWAS can be a later option).
- Phenotype field-trial design or spatial correction beyond BLUPs/BLUEs from a mixed model.
- Selection decisions: the pipeline ranks lines by GEBV, but crossing plans and selection indices stay with the breeder.

## Landscape and gap

No widely adopted, nf-core-grade plant GWAS pipeline exists today. The existing ones each cover part of the job.

| Workflow | Engine | Covers | Gap for us |
| --- | --- | --- | --- |
| [DivAssociate](https://plant-commons.ipk-gatersleben.de/software/divassociate) | Nextflow | GWAS on crop diversity panels | Small user base, low activity; no GBS or WGS front end |
| [kGWASflow](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10755180/) | Snakemake | Reference-free k-mer GWAS | Different method; no SNP-based multi-locus models |
| [HAPPI GWAS](https://par.nsf.gov/servlets/purl/10226382) | R scripts | Pre-GWAS, GAPIT models, post-GWAS | Not a workflow manager; no containers or HPC scaling |
| [PlantVarFilter](https://www.biorxiv.org/content/10.1101/2025.07.02.662805.full.pdf) | Python | Variant filtering + GWAS | Preprint; early stage |
| [genepi/nf-gwas](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10849172/) | Nextflow | Biobank GWAS with REGENIE | Built for humans; no plant models, imputation or LD-window gene calls |

What we reuse: nf-core modules for read QC, alignment, variant calling and PLINK; the nf-core template for schema, testing and CI. What we add: the GBS front end, imputation without a reference panel, GAPIT/rMVP multi-locus models, LD-decay windows and candidate-gene extraction.

