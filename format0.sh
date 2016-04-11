#!/bin/sh
#PBS -N jm-vik0
#PBS -l nodes=compute-0-9.local
#PBS -l ncpus=1
#PBS -V
#PBS -o job0.log
#PBS -e job0.err
date
cd /home/humgen/jieming/vikrant/cnv/raw-intensites/jm/
for (( j=0;j<10;j++ )) 
do
for i in tmp.list02$j*
do
sort -k2 $i > $i-sorted
mv $i-sorted $i
ftranspose $i
intensities-files-format transposed-$i
rm transposed-$i
mv $i thrash
done
done
date

