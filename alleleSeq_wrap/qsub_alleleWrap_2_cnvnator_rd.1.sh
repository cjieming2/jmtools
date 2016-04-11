#!/bin/sh

#PBS -N jm-job2
#PBS -l ncpus=1
#PBS -V
#PBS -o jm-job2.log
#PBS -e jm-job2.err
date
cd /home/fas/gerstein/jc2296/scratch/personal_genomes/test
./alleleWrap_2_cnvnator_rd.sh NA12878 /scratch/fas/gerstein/jc2296/personal_genomes/decoy_alignments/20110915/CEUTrio.HiSeq.WGS.b37_decoy.NA12878.clean.dedup.recal.bam miseq_pcr_free_131313 /scratch/fas/gerstein/jc2296/G1K_reference_hg19/fasta
date
