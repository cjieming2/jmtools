### usage: alleleWrap_4_qsubPIPELINE.sh <1> <2>
## <1> the TF/RNA expt folder name
## <2> location of personal genome PIPELINE.mk
## to do multiple folders, do a loop
## e.g alleleWrap_4_qsubPIPELINE.sh Open_Chrom_YY1 /scratch/fas/gerstein/jc2296/personal_genomes/mytest/PIPELINE.mk

echo "#!/bin/sh" > bsub-myscript-$1.sh
echo "#BSUB -J $1" >> bsub-myscript-$1.sh
echo "#BSUB -o bsub-$1.log" >> bsub-myscript-$1.sh
echo "#BSUB -e bsub-$1.err" >> bsub-myscript-$1.sh
echo "#BSUB -W 1400:00" >> bsub-myscript-$1.sh

echo date >> bsub-myscript-$1.sh
echo -e cd "$(pwd)"  >> bsub-myscript-$1.sh
echo make -f $2 \>\& $1.log >> bsub-myscript-$1.sh
echo date >> bsub-myscript-$1.sh

