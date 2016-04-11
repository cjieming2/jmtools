## usage: qsub-create-loop.sh <name>
echo "### usage: create-script-and-qsub.sh 0 8" > create-script-$1-qsub.sh
echo "### 0 to 8" >> create-script-$1-qsub.sh
echo >> create-script-$1-qsub.sh
echo "### function to create scripts" >> create-script-$1-qsub.sh
echo "function create-myscript" >> create-script-$1-qsub.sh
echo "## arg_1 = param 1 passed in to create-script-and-qsub.sh script" >> create-script-$1-qsub.sh
echo "{" >> create-script-$1-qsub.sh
echo "  	echo \"#!/bin/sh\" > myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"#PBS -N myscript-$1-\$1\" >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"#PBS -l ncpus=1\" >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"#PBS -V\" >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"#PBS -o myscript-$1-\$1.log\" >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"#PBS -e myscript-$1-\$1.err\" >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo >> create-script-$1-qsub.sh
echo "  	echo \"date\" >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo  >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"cd $(pwd)\"  >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"zcat file.vcf.gz cmd\"   >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "  	echo \"date\" >> myscript-\$1.sh" >> create-script-$1-qsub.sh
echo "}" >> create-script-$1-qsub.sh
echo >> create-script-$1-qsub.sh
echo "### main " >> create-script-$1-qsub.sh
echo "for (( i=\$1; i <= \$2; i++ ))" >> create-script-$1-qsub.sh
echo "do" >> create-script-$1-qsub.sh
echo "  	create-myscript \$i" >> create-script-$1-qsub.sh
echo "  	chmod +x myscript-\"\$i\".sh" >> create-script-$1-qsub.sh
echo "  	#qsub -q gerstein myscript-\"\$i\".sh" >> create-script-$1-qsub.sh
echo "done" >> create-script-$1-qsub.sh

chmod +x create-script-$1-qsub.sh
