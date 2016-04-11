### alleledb-mat.sh <indiv_category> <pgenome> <basename/fastq.gz> <path pgenome> <path snp.calls.bed for het snps> <path fastq.gz> <asb/ase> <flag>
### e.g. alleledb-mat.sh NA12878_kilpinen-rnaseq alleledb_pg /gpfs/scratch/fas/gerstein/jc2296/personal_genomes/NA12878_pgenome_hg19/hiseq_NA12878_hg19 /gpfs/scratch/fas/gerstein/jc2296/personal_genomes/NA12878_pgenome_hg19/hiseq_NA12878_hg19/snp.calls.bed /scratch/fas/gerstein/jc2296/alleledb/alleleseq-runs/trios/NA12878/NA12878_hiseq/rnaseq/combined_ASE_POLYA_NA12878 kilpinen_NA12878_ERR356372_1.fastq.gz ~/software/AlleleSeq_pipeline_v1.2.rob.new ase 0
### note for paths no end '/' pls
## requires the following scripts: intersectBed from bedtools, Bowtie1, ThunderByRob.jar, bsub-make-plus.sh,  map.back.ref.wrapper.sh.ori,  multis-and-unaligneds-wrapper.sh 
## option 8 uses 'small' fastqi for realignment, meaning these are only the reads that had aligned previously.

NAME=$1  ##NA12878_kilpinen-rnaseq
PGENOME=$2  ##name of personal genome newSV
PGENOME_PATH=$3 ##/path/to/pgenome; no '/' at the end
SNPCALLS_PATH=$4 ##/path/to/snp.calls.bed; note this is the explicit file location

FASTQ_PATH=$5 ##/path/to/fastq
FASTQ=$6 ##basename/fastq.gz

PL=$7 ##/path/to/pipeline

AS=$8 ##asb/ase
FLAG=$9 ##see below 

#########################
### FLAG CODE   #########
### 0:run everything
### 1:alignment 
### 2:map back to reference
### 3:intersectBed between reads and hetSNVs
### 4:flip alleles on reads that overlap 1 hetSNV (note right now only 1 hetSNV)
### 5:alignment2 of flipped reads
### 6:unaligned reads in a separate folder for analysis
### 7:multi reads in a separate folder for analysis
### 8:alleleseq run on bias-filtered fastq


## create allelic bias folder
cd allelicbias-$2-$1

## 1 alignment
if [[ $FLAG -eq 1 || $FLAG -eq 0 ]] ; then
	echo "##########################"
	echo "## 1-alignment mat #######"
	echo "##########################"
	cd 1-alignment-$NAME
	
	$PL/alleledb_filter_input.sh $PL $FASTQ | bowtie --best --strata -v 2 -m 1 -f $PGENOME_PATH/AltRefMother/AltRefMother - > $FASTQ.mat.bowtie; echo $FASTQ ; zcat $FASTQ | wc -l ; wc -l $FASTQ.mat.bowtie
	cd ..
fi

## 2 map to ref
if [[ $FLAG -eq 2 || $FLAG -eq 0 ]] ; then
	echo "###########################"
        echo "## 2-map to ref mat #######"
        echo "###########################"
	cd 2-map.back.ref-$NAME

	$PL/alleledb_map.back.ref.wrapper.sh $FASTQ.mat.bowtie maternal MAT mat2ref.chain $PL; awk '{OFS="\t"}{FS="\t"}{print "chr"$0}' $FASTQ.mat.bowtie.maternal.map2ref.bed > $FASTQ.mat.bowtie.maternal.map2ref.bed_ ; mv $FASTQ.mat.bowtie.maternal.map2ref.bed trash ; mv $FASTQ.mat.bowtie.maternal.map2ref.bed_ $FASTQ.mat.bowtie.maternal.map2ref.bed  ;  wc -l *.maternal.*.bed
	cd ..
fi

## 3  intersectBed
if [[ $FLAG -eq 3 || $FLAG -eq 0 ]] ; then
	echo "##############################"
        echo "## 3-intersectBed  mat #######"
        echo "##############################"
	cd 3-intersectBed-$NAME

	
	intersectBed -a $FASTQ.mat.bowtie.maternal.map2ref.bed -b snp.calls.bed -wa -wb > intersect.$FASTQ.mat.snp.calls.txt ; wc -l intersect.$FASTQ.mat.snp.calls.txt
	cd ..
fi

## 4 flip the reads
if [[ $FLAG -eq 4 || $FLAG -eq 0 ]] ; then
	echo "################################"
        echo "## 4-flip the reads  mat #######"
        echo "################################"
	cd 4-flip-$NAME 


	$PL/alleledb_flipread2fastq -s 1 intersect.$FASTQ.mat.snp.calls.txt > intersect.$FASTQ.mat.flipread.fastq;  wc -l intersect.*mat.*

	cd ..
fi

## 5 alignment2
if [[ $FLAG -eq 5 || $FLAG -eq 0 ]] ; then
	echo "#########################################"
        echo "## 5-alignment2 flipped reads mat #######"
        echo "#########################################"
	cd 5-alignment2-$NAME


	bowtie --un intersect.$FASTQ.matflip2mat.flipread.unaligned --max intersect.$FASTQ.matflip2mat.flipread.multi --best --strata -v 2 -m 1 -q $PGENOME_PATH/AltRefMother/AltRefMother intersect.$FASTQ.mat.flipread.fastq > intersect.$FASTQ.matflip2mat.flipread.bowtie;  wc -l intersect.$FASTQ.matflip2mat.flipread.*
	
	bowtie --un intersect.$FASTQ.matflip2pat.flipread.unaligned --max intersect.$FASTQ.matflip2pat.flipread.multi --best --strata -v 2 -m 1 -q $PGENOME_PATH/AltRefFather/AltRefFather intersect.$FASTQ.mat.flipread.fastq > intersect.$FASTQ.matflip2pat.flipread.bowtie;  wc -l intersect.$FASTQ.matflip2pat.flipread.*
	
	bowtie --un intersect.$FASTQ.matflip2ref.flipread.unaligned --max intersect.$FASTQ.matflip2ref.flipread.multi --best --strata -v 2 -m 1 -q /gpfs/scratch/fas/gerstein/jc2296/reference_genomes/fasta/b37_g1k_phase2/Refhs37d5ss intersect.$FASTQ.mat.flipread.fastq > intersect.$FASTQ.matflip2ref.flipread.bowtie; wc -l intersect.$FASTQ.matflip2ref.flipread.*

	cd ..
fi

## 6 unaligned
if [[ $FLAG -eq 6 || $FLAG -eq 0 ]] ; then
	echo "###############################################"
        echo "## 6-check unaligned flipped reads  mat #######"
        echo "###############################################"
	cd 6-unaligned-$NAME

	
	
	$PL/alleledb_multis-and-unaligneds-wrapper.sh intersect.$FASTQ.matflip2pat.flipread.unaligned intersect.$FASTQ.mat.snp.calls.txt mat
	
	cd ..
fi

## 7 multi
if [[ $FLAG -eq 7 || $FLAG -eq 0 ]] ; then
	echo "###########################################"
        echo "## 7-check multi flipped reads mat  #######"
        echo "###########################################"
	cd 7-multi-$NAME


	$PL/alleledb_multis-and-unaligneds-wrapper.sh intersect.$FASTQ.matflip2pat.flipread.multi intersect.$FASTQ.mat.snp.calls.txt mat
	
	cd ..
fi

## get out of allelicbias folder
cd ..

 
