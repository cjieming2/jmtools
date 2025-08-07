## this wrapper script preps for and runs PIPELINE.mk in AlleleSeq pipeline
## do this in the directory of the personal genome
## in another folder for allele runs, create new folders for each TF then direct the path to the PIPELINE.mk found in the personal genome
## USAGE: alleleWrap_alleleSeq <1> <2> <3> <4>
## <1> = where to find AlleleSeq software and PIPELINE.mk
## <2> = path for VCF file with trio genotypes
## <3> = path for cnv_rd
## <4> = sample
## e.g. ./alleleWrap_3_alleleSeq.sh /home/fas/gerstein/jc2296/software/AlleleSeq_pipeline_v1.1 /scratch/fas/gerstein/jc2296/personal_genomes/trio_variants/trio_pcr_free_from_broad_hg19_130728/CEU.wgs.HaplotypeCaller_bi.20130520.snps_indels.high_coverage_pcr_free.genotypes.pass.vcf /scratch/fas/gerstein/jc2296/personal_genomes/test/cnv_rd_NA12878_miseq_pcr_free_131313/rd.cnvnator.miseq.NA12878.snp.calls.old NA12878

## vcf2snp input
#vcf2snp $3 > snp.calls

## remember to make changes to PIPELINE.mk
#make -f PIPELINE.mk >& OpenChrom_cMyc.log

## print PIPELINE.mk
CURR=$(pwd)
echo  > PIPELINE.mk
echo BASE\=$CURR >> PIPELINE.mk
echo PL\:=$1 >> PIPELINE.mk
echo SNPS\:=\$\(BASE\)\/snp.calls >> PIPELINE.mk
echo CNVS\:=$3 >> PIPELINE.mk
echo BNDS\:=hits.bed >> PIPELINE.mk
echo MAPS\:=\$\(BASE\)/%s_$4.map >> PIPELINE.mk
echo FDR_SIMS\:=6 >> PIPELINE.mk
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
