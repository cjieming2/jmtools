### usage: create-script-and-qsub.sh 0 8

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
	echo "cd /home/jc2296/1KG/1KG_phase1_hg19/2-nonmono"  >> myscript-$1.sh

	echo "fselect a.+,b.AA from nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq, /home/jc2296/1KG/1KG_phase1_hg19/src/all/ALL.wgs.phase1_release_v3.20101123.36820992snps.auto.sites.vcf.tsv where a.id=b.id > nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq_; awk '{OFS=\"\\t\"}{FS=\"\\t\"}{if(\$6 == \"AA\"){print \$0,\"DAF\"}else if(\$6 == \$10){print \$0,\$9}else{if(\$8 == \$10){print \$0,\$7}else{print \$0,\"FALSE\"}}}' nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq_ > nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq_1; mv nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq_ ../trash/; mv nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq_1 nonmono.ALL.chr$1.phase1_release_v3.20101123.snps.freq.frq" >> myscript-$1.sh 


	echo "date" >> myscript-$1.sh
}

### main 
for (( i=$1; i <= $2; i++ ))
do
	create-myscript $i
	chmod +x myscript-"$i".sh
	#qsub -q gerstein myscript-"$i".sh
done
