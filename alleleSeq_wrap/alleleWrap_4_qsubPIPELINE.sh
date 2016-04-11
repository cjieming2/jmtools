### usage: alleleWrap_4_qsubPIPELINE.sh <1> <2>
## <1> the TF/RNA expt folder name
## <2> location of personal genome PIPELINE.mk
## to do multiple folders, do a loop
## e.g alleleWrap_4_qsubPIPELINE.sh Open_Chrom_YY1 /scratch/fas/gerstein/jc2296/personal_genomes/mytest/PIPELINE.mk

echo "#!/bin/sh" > myscript-$1.sh
echo "#PBS -N allele-$1" >> myscript-$1.sh
echo "#PBS -l ncpus=4" >> myscript-$1.sh
echo "#PBS -V" >> myscript-$1.sh
echo "#PBS -o allele-$1.log" >> myscript-$1.sh
echo "#PBS -e allele-$1.err" >> myscript-$1.sh

echo date >> myscript-$1.sh
echo -e cd "$(pwd)"  >> myscript-$1.sh
echo make -f $2 \>\& $1.log >> myscript-$1.sh
echo date >> myscript-$1.sh

#qsub myscript-$1.sh
