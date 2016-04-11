### usage: bsub-make.sh <job-name>

echo "#!/bin/bash" > bsub-script-rdy-$1.sh
echo "#BSUB -J $1" >> bsub-script-rdy-$1.sh
echo "#BSUB -o bsub-$1.log" >> bsub-script-rdy-$1.sh
echo "#BSUB -e bsub-$1.err" >> bsub-script-rdy-$1.sh
echo "#BSUB -W 670:00"	>> bsub-script-rdy-$1.sh

echo date >> bsub-script-rdy-$1.sh
echo -e cd "$(pwd)"  >> bsub-script-rdy-$1.sh
echo  >> bsub-script-rdy-$1.sh
echo date >> bsub-script-rdy-$1.sh

#bsub < bsub-script-rdy-$1.sh
