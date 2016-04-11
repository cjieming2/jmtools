### usage: create-script-and-qsub.sh 100 110

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

	echo date >> myscript-$1.sh
	echo  >> myscript-$1.sh
	echo cd /home/humgen/jieming/vikrant/cnv/raw-intensites/test/  >> myscript-$1.sh
	echo "for i in tmp.list0$1*" >> myscript-$1.sh
	echo "do" >> myscript-$1.sh
	echo "sort -k2 \$i > \$i-sorted" >> myscript-$1.sh
	echo "mv \$i-sorted \$i" >> myscript-$1.sh
	echo "ftranspose \$i" >> myscript-$1.sh
	echo "intensities-files-format transposed-\$i" >> myscript-$1.sh
	echo "rm transposed-\$i" >> myscript-$1.sh
	echo "mv \$i thrash" >> myscript-$1.sh
	echo "done" >> myscript-$1.sh
	echo  >> myscript-$1.sh
	echo date >> myscript-$1.sh
}

### main 
for (( i=$1; i <= $2; i++ ))
do
	create-myscript $i
	chmod +x myscript-"$i".sh
	qsub myscript-"$i".sh
done
