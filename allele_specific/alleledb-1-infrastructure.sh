### alleledb.sh <indiv_category> <pgenome> <basename/fastq.gz> <path pgenome> <path snp.calls.bed for het snps> <path fastq.gz> <asb/ase> <flag>
### e.g. alleledb.sh NA12878_kilpinen-rnaseq alleledb_pg /gpfs/scratch/fas/gerstein/jc2296/personal_genomes/NA12878_pgenome_hg19/hiseq_NA12878_hg19 /gpfs/scratch/fas/gerstein/jc2296/personal_genomes/NA12878_pgenome_hg19/hiseq_NA12878_hg19/snp.calls.bed /scratch/fas/gerstein/jc2296/alleledb/alleleseq-runs/trios/NA12878/NA12878_hiseq/rnaseq/combined_ASE_POLYA_NA12878 kilpinen_NA12878_ERR356372_1.fastq.gz ~/software/AlleleSeq_pipeline_v1.2.rob.new ase 0
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
mkdir allelicbias-$2-$1
cd allelicbias-$2-$1

## 1 alignment
if [[ $FLAG -eq 1 || $FLAG -eq 0 ]] ; then
	echo "#####################################"
	echo "## 1-alignment infrastructure #######"
	echo "#####################################"
	mkdir 1-alignment-$NAME
	cd 1-alignment-$NAME
	mkdir trash
	ln -s $FASTQ_PATH/$FASTQ
	
	cd ..
fi

## 2 map to ref
if [[ $FLAG -eq 2 || $FLAG -eq 0 ]] ; then
	echo "######################################"
        echo "## 2-map to ref infrastructure #######"
        echo "######################################"
	mkdir 2-map.back.ref-$NAME
	cd 2-map.back.ref-$NAME
	mkdir trash
	ln -s $PGENOME_PATH/mat2ref.chain
	ln -s $PGENOME_PATH/pat2ref.chain

	for i in ../1-alignment-$NAME/*.bowtie
	do
	ln -s $i
	done

	cd ..
fi

## 3  intersectBed
if [[ $FLAG -eq 3 || $FLAG -eq 0 ]] ; then
	echo "########################################"
        echo "## 3-intersectBed infrastructure #######"
        echo "########################################"
	mkdir 3-intersectBed-$NAME
	cd 3-intersectBed-$NAME
	mkdir trash
	ln -s $SNPCALLS_PATH

	for i in ../2-map.back.ref-$NAME/*.map2ref.bed
	do
	ln -s $i
	done
	
	cd ..
fi

## 4 flip the reads
if [[ $FLAG -eq 4 || $FLAG -eq 0 ]] ; then
	echo "###########################################"
        echo "## 4-flip the reads infrastructure  #######"
        echo "###########################################"
	mkdir 4-flip-$NAME
	cd 4-flip-$NAME 
	mkdir trash

	for i in ../3-intersectBed-$NAME/intersect.*.snp.calls.txt
	do
	ln -s $i
	done


	cd ..
fi

## 5 alignment2
if [[ $FLAG -eq 5 || $FLAG -eq 0 ]] ; then
	echo "####################################################"
        echo "## 5-alignment2 flipped reads infrastructure #######"
        echo "####################################################"
	mkdir 5-alignment2-$NAME
	cd 5-alignment2-$NAME
	mkdir trash

	for i in ../4-flip-$NAME/*.fastq
	do
	ln -s $i
	done


	cd ..
fi

## 6 unaligned
if [[ $FLAG -eq 6 || $FLAG -eq 0 ]] ; then
	echo "##########################################################"
        echo "## 6-check unaligned flipped reads infrastructure  #######"
        echo "##########################################################"
	mkdir 6-unaligned-$NAME
	cd 6-unaligned-$NAME
	mkdir trash

	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.matflip2pat.flipread.unaligned 
	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.patflip2mat.flipread.unaligned 
	
	### original mat and pat
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.mat.snp.calls.txt
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.pat.snp.calls.txt
	
	
	cd ..
fi

## 7 multi
if [[ $FLAG -eq 7 || $FLAG -eq 0 ]] ; then
	echo "######################################################"
        echo "## 7-check multi flipped reads infrastructure  #######"
        echo "######################################################"
	mkdir 7-multi-$NAME
	cd 7-multi-$NAME
	mkdir trash

	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.matflip2pat.flipread.multi
	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.patflip2mat.flipread.multi

	### original mat and pat
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.mat.snp.calls.txt
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.pat.snp.calls.txt
	
	
	cd ..
fi

## get out of allelicbias folder
cd ..


## 8 fsieve original multi reads from original fastq
## then run alleleseq again on this filtered fastqs
if [[ $FLAG -eq 8 || $FLAG -eq 0 ]] ; then
	echo "##############################################"
	echo " 8 rerun alleleseq on bias filtered reads ####"
	echo "##############################################"
#	mkdir 8-rerun-alleleseq-$NAME
#	cd 8-rerun-alleleseq-$NAME
	mkdir trash

	ln -s ./allelicbias-$2-$1/7-multi-$NAME/originalmatreads.intersect.$FASTQ.matflip2pat.flipread.multi.bed
	ln -s ./allelicbias-$2-$1/7-multi-$NAME/originalpatreads.intersect.$FASTQ.patflip2mat.flipread.multi.bed
	ln -s $FASTQ_PATH/$FASTQ	


#	cd ..
fi
 
