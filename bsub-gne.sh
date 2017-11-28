### usage: bsub-make.sh <job-name> "<cmd>"

echo "#!/bin/bash" > bsub-$1.sh
echo "#BSUB -J $1" >> bsub-$1.sh
echo "#BSUB -o bsub-$1.log" >> bsub-$1.sh
echo "#BSUB -e bsub-$1.err" >> bsub-$1.sh
#echo "#BSUB -W 670:00"	>> bsub-$1.sh

echo date >> bsub-$1.sh
echo -e cd "$(pwd)"  >> bsub-$1.sh
echo $2 >> bsub-$1.sh
echo date >> bsub-$1.sh

#bsub < bsub-$1.sh
