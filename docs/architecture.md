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

