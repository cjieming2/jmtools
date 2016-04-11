#!/bin/sh

#PBS -N jm-job0
#PBS -l ncpus=1
#PBS -V
#PBS -o jm-job0.log
#PBS -e jm-job0.err
date
cd $HOME/testing-erwin/
impute
date
