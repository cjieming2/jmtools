### usage: qsub-make.sh <job-name>

echo "#!/bin/sh" > qsub-script-rdy-$1.sh
echo "#PBS -N $1" >> qsub-script-rdy-$1.sh
echo "#PBS -o qsub-$1.log" >> qsub-script-rdy-$1.sh
echo "#PBS -e qsub-$1.err" >> qsub-script-rdy-$1.sh
echo "#PBS -l ncpus=1"	>> qsub-script-rdy-$1.sh

echo date >> qsub-script-rdy-$1.sh
echo -e cd "$(pwd)"  >> qsub-script-rdy-$1.sh
echo "R CMD BATCH allele_readdepth_table_beta\&binomial_distribution_gradient.R"  >> qsub-script-rdy-$1.sh
echo date >> qsub-script-rdy-$1.sh

#qsub qsub-script-rdy-$1.sh
