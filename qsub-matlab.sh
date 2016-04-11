#!/bin/sh

#PBS -N jm-job0
#PBS -l ncpus=1
#PBS -V
#PBS -o jm-job0.log
#PBS -e jm-job0.err
date
cd $HOME/workspace/lynne_ppi/combined/1-3dcomplex-qs100-piQsi-pdbbind/structures
matlab -nodisplay < main_pdb.m > main_pdb.log
date
