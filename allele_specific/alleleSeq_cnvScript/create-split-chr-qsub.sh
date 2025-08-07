### usage: create-script-and-qsub.sh 0 8
### 0 to 8

### function to create scripts
function create-myscript
## arg_1 = param 1 passed in to create-script-and-qsub.sh script
{
	echo "#!/bin/sh" > myscript-$1.sh
	echo "#PBS -N myscript-vik-$1" >> myscript-$1.sh
	echo "#PBS -l ncpus=1" >> myscript-$1.sh
	echo "#PBS -V" >> myscript-$1.sh
	echo "#PBS -o myscript-vik-$1.log" >> myscript-$1.sh
	echo "#PBS -e myscript-vik-$1.err" >> myscript-$1.sh

	echo "date" >> myscript-$1.sh
	echo  >> myscript-$1.sh
	echo "cd /home/fas/gerstein/jc2296/scratch/personal_genomes/na12891_pgenome_hg19/hiseq_na12891_hg19/cnv_rd"  >> myscript-$1.sh
	echo "./addRD split-$1-NA12891.snp.calls >& split-$1-NA12891.snp.calls.log"   >> myscript-$1.sh
	echo "date" >> myscript-$1.sh
}

### main 
for (( i=$1; i <= $2; i++ ))
do
	create-myscript $i
	chmod +x myscript-"$i".sh
	#qsub -l walltime=24:00:00 -q fas_high myscript-"$i".sh
done
