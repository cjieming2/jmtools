echo  >> PIPELINE.mk
echo BASE=\/scratch\/fas\/gerstein\/jc2296\/personal_genomes\/mytest\/ >> PIPELINE.mk
echo PL\:=\/home\/fas\/gerstein\/jc2296\/software\/AlleleSeq_pipeline_v1.1 >> PIPELINE.mk
echo SNPS\:=\$\(BASE\)\/snp.calls >> PIPELINE.mk
echo CNVS\:=\$\(BASE\)\/personal_genome\/cnv_rd_NA12878_hiseq_9999\/rd_4327183snps_na12878_hg19.txt' ' >> PIPELINE.mk
echo BNDS\:=hits.bed >> PIPELINE.mk
echo MAPS\:=\$\(BASE\)\/personal_genome\/%s_NA12878.map >> PIPELINE.mk
echo FDR_SIMS\:=5 >> PIPELINE.mk
echo FDR_CUTOFF\:=0.1 >> PIPELINE.mk
echo  >> PIPELINE.mk
echo sourcefiles \:= \$\(wildcard *.fastq.gz\) >> PIPELINE.mk
echo countfiles \:= \$\(subst .fastq.gz,.cnt,\$\(sourcefiles\)\) >> PIPELINE.mk
echo  >> PIPELINE.mk
echo %.cnt\:%.fastq.gz >> PIPELINE.mk
echo -e '\t'bash -c \"python \$\(PL\)\/MergeBowtie.py \\ >> PIPELINE.mk
echo -e '           '\<\(\$\(PL\)\/filter_input.sh \$\(PL\) \$\< \| bowtie --best --strata -v 2 -m 1 -f \$\(BASE\)\/personal_genome\/AltRefFather\/AltRefFather - \) \\ >> PIPELINE.mk
echo -e '           '\<\(\$\(PL\)\/filter_input.sh \$\(PL\) \$\< \| bowtie --best --strata -v 2 -m 1 -f \$\(BASE\)\/personal_genome\/AltRefMother\/AltRefMother - \) \\ >> PIPELINE.mk
echo -e '           '\$\(MAPS\) \| python \$\(PL\)\/SnpCounts.py \$\(SNPS\) - \$\(MAPS\) \$@\" >> PIPELINE.mk
echo  >> PIPELINE.mk
echo all\: interestingHets.txt >> PIPELINE.mk
echo  >> PIPELINE.mk
echo check\: >> PIPELINE.mk
echo -e '\t'@echo \$\(sourcefiles\) >> PIPELINE.mk
echo  >> PIPELINE.mk
echo counts.txt\: \$\(countfiles\) >> PIPELINE.mk
echo -e '\t'python \$\(PL\)\/CombineSnpCounts.py 5 \$\(SNPS\) \$\(BNDS\) \$\(CNVS\) counts.txt counts.log \$\(countfiles\) >> PIPELINE.mk
echo  >> PIPELINE.mk
echo \# calculate false discovery rates >> PIPELINE.mk
echo FDR.txt\: counts.txt >> PIPELINE.mk
echo -e '\t'python \$\(PL\)\/FalsePos.py counts.txt \$\(FDR_SIMS\) \$\(FDR_CUTOFF\) \> FDR.txt >> PIPELINE.mk
echo  >> PIPELINE.mk
echo interestingHets.txt\: counts.txt FDR.txt >> PIPELINE.mk
echo -e '\t'awk -f \$\(PL\)\/finalFilter.awk thresh=\$\(shell awk \'END {print \$\$6}\' FDR.txt\) \< counts.txt \> interestingHets.txt >> PIPELINE.mk
echo  >> PIPELINE.mk
echo clean\: >> PIPELINE.mk
echo -e '\t'@rm -f FDR.txt interestingHets.txt counts.txt >> PIPELINE.mk
echo  >> PIPELINE.mk
echo cleanall\: clean >> PIPELINE.mk
echo -e '\t'@rm -f *.cnt >> PIPELINE.mk
echo  >> PIPELINE.mk
echo .DELETE_ON_ERROR\: >> PIPELINE.mk
