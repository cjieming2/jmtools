#!/bin/sh
#PBS -N jm-struct0
#PBS -l nodes=compute-0-0.local
#PBS -l ncpus=2
#PBS -V
#PBS -o job0.log
#PBS -e job0.err
date
cd /home/chenjm/jmtools
structure -K 0 -o output0 > struct-out-new.0
date
