### usage: sbatch-make.sh <job-name> "<cmd>"

echo "#!/bin/bash" > sbatch-$1.sh
echo "#SBATCH -J $1" >> sbatch-$1.sh
echo "#SBATCH -o sbatch-$1.log" >> sbatch-$1.sh
echo "#SBATCH -e sbatch-$1.err" >> sbatch-$1.sh
#echo "#SBATCH -W 670:00"	>> sbatch-$1.sh

echo date >> sbatch-$1.sh
echo -e cd "$(pwd)"  >> sbatch-$1.sh
echo $2 >> sbatch-$1.sh
echo date >> sbatch-$1.sh

#sbatch < sbatch-$1.sh
