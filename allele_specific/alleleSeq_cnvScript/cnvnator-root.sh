#!/bin/sh

#PBS -N jm-root-12891
#PBS -l ncpus=4
#PBS -V
#PBS -o jm-root-12891.log
#PBS -e jm-root-12891.err
date
cd /home/fas/gerstein/jc2296/scratch/personal_genomes/na12891_pgenome_hg19/hiseq_na12891_hg19/cnv_rd
cnvnator -root NA12891.hiseq.root -tree CEUTrio.HiSeq.WGS.b37_decoy.NA12891.clean.dedup.recal.bam
date
