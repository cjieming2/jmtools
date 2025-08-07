#!/bin/sh

#PBS -N jm-job0
#PBS -l ncpus=1
#PBS -V
#PBS -o jm-job0.log
#PBS -e jm-job0.err
date
cd /home/fas/gerstein/jc2296/scratch/personal_genomes/test
./alleleWrap_1_vcf2diploid.sh ~/software/vcf2diploid_v0.2.4/vcf2diploid.jar NA12878 /scratch/fas/gerstein/jc2296/G1K_reference_hg19/fasta /scratch/fas/gerstein/jc2296/personal_genomes/trio_variants/trio_pcr_free_from_broad_hg19_130728/CEU.wgs.HaplotypeCaller_bi.20130520.snps_indels.high_coverage_pcr_free.genotypes.pass.vcf miseq_pcr_free_131313
date
