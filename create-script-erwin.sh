### usage: create-script.sh 001 002
### submit-qsub-job.sh requires this script

echo "#!/bin/sh" > script-$1-$2.sh
echo "#PBS -N ibs-job-$1-$2" >> script-$1-$2.sh
echo "#PBS -l ncpus=1" >> script-$1-$2.sh
echo "#PBS -V" >> script-$1-$2.sh
echo "#PBS -o ibs-job-$1-$2.log" >> script-$1-$2.sh
echo "#PBS -e ibs-job-$1-$2.err" >> script-$1-$2.sh

echo cd /home/humgen/jieming/sonia/ukmgc-meningococcal/547samples-620901snps-cases-ukmgc/geno/520samples-544134snps-illumina-hap610quad-ukmgc-cases-top  >> script-$1-$2.sh
echo plink --noweb --bfile ../520samples-547861snps-illumina-hap610quad-ukmgc-cases-top+plink/plink/520samples-547860snps-illumina-hap610quad-v1-ukmgc-cases-top --genome --genome-full --genome-lists tmp.list$1 tmp.list$2 --out data.sub.$1.$2 --read-freq ../520samples-547861snps-illumina-hap610quad-ukmgc-cases-top+plink/plink/520samples-547860snps-illumina-hap610quad-v1-ukmgc-cases-top.frq --allow-no-sex --extract 544134snps-Quad610-v1-db128-ukmgc-top.mk >> script-$1-$2.sh
