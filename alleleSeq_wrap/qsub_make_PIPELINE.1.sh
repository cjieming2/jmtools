#!/bin/sh

#PBS -N jm-job-as
#PBS -l ncpus=4
#PBS -V
#PBS -o jm-job-as.log
#PBS -e jm-job-as.err
date
cd /scratch/fas/gerstein/jc2296/personal_genomes/mytest/cmyc_mytest
make -f ../PIPELINE.mk >& OpenChrom_cMyc.log
date
