include { BCFTOOLS_VIEW } from '../../../modules/nf-core/bcftools/view/main'

workflow GENO_PREP {
  
    take:
    ch_vcf // channel: [ val(meta), path(vcf) ]

    main: 
    BCFTOOLS_VIEW(
        ch_vcf.map { meta, vcf -> [ meta, vcf, [] ] }, // no index needed: we do not query by region
        [], // regions
        [], // targets
        []  // samples
    )

    emit:
    vcf = BCFTOOLS_VIEW.out.vcf // channel: [ val(meta), path(vcf) ]
}
