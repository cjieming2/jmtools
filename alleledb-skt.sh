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
	echo "######################"
	echo "## 1-alignment #######"
	echo "######################"
	mkdir 1-alignment-$NAME
	cd 1-alignment-$NAME
	mkdir trash
	ln -s $FASTQ_PATH/$FASTQ
	
	$PL/alleledb_filter_input.sh $PL $FASTQ | bowtie --best --strata -v 2 -m 1 -f $PGENOME_PATH/AltRefMother/AltRefMother - > $FASTQ.mat.bowtie; echo $FASTQ ; zcat $FASTQ | wc -l ; wc -l $FASTQ.mat.bowtie
	$PL/alleledb_filter_input.sh $PL $FASTQ | bowtie --best --strata -v 2 -m 1 -f $PGENOME_PATH/AltRefFather/AltRefFather - > $FASTQ.pat.bowtie; wc -l $FASTQ.pat.bowtie
	cd ..
fi

## 2 map to ref
if [[ $FLAG -eq 2 || $FLAG -eq 0 ]] ; then
	echo "#######################"
        echo "## 2-map to ref #######"
        echo "#######################"
	mkdir 2-map.back.ref-$NAME
	cd 2-map.back.ref-$NAME
	mkdir trash
	ln -s $PGENOME_PATH/mat2ref.chain
	ln -s $PGENOME_PATH/pat2ref.chain

	for i in ../1-alignment-$NAME/*.bowtie
	do
	ln -s $i
	done

	$PL/alleledb_map.back.ref.wrapper.sh $FASTQ.mat.bowtie maternal MAT mat2ref.chain; awk '{OFS="\t"}{FS="\t"}{print "chr"$0}' $FASTQ.mat.bowtie.maternal.map2ref.bed > $FASTQ.mat.bowtie.maternal.map2ref.bed_ ; mv $FASTQ.mat.bowtie.maternal.map2ref.bed trash ; mv $FASTQ.mat.bowtie.maternal.map2ref.bed_ $FASTQ.mat.bowtie.maternal.map2ref.bed  ;  wc -l *.maternal.*.bed
	$PL/alleledb_map.back.ref.wrapper.sh $FASTQ.pat.bowtie paternal PAT pat2ref.chain; awk '{OFS="\t"}{FS="\t"}{print "chr"$0}' $FASTQ.pat.bowtie.paternal.map2ref.bed > $FASTQ.pat.bowtie.paternal.map2ref.bed_ ; mv $FASTQ.pat.bowtie.paternal.map2ref.bed trash ; mv $FASTQ.pat.bowtie.paternal.map2ref.bed_ $FASTQ.pat.bowtie.paternal.map2ref.bed  ;  wc -l *.paternal.*.bed
	cd ..
fi

## 3  intersectBed
if [[ $FLAG -eq 3 || $FLAG -eq 0 ]] ; then
	echo "##########################"
        echo "## 3-intersectBed  #######"
        echo "##########################"
	mkdir 3-intersectBed-$NAME
	cd 3-intersectBed-$NAME
	mkdir trash
	ln -s $SNPCALLS_PATH

	for i in ../2-map.back.ref-$NAME/*.map2ref.bed
	do
	ln -s $i
	done
	
	intersectBed -a $FASTQ.mat.bowtie.maternal.map2ref.bed -b snp.calls.bed -wa -wb > intersect.$FASTQ.mat.snp.calls.txt ; wc -l intersect.$FASTQ.mat.snp.calls.txt
	intersectBed -a $FASTQ.pat.bowtie.paternal.map2ref.bed -b snp.calls.bed -wa -wb > intersect.$FASTQ.pat.snp.calls.txt ; wc -l intersect.$FASTQ.pat.snp.calls.txt
	cd ..
fi

## 4 flip the reads
if [[ $FLAG -eq 4 || $FLAG -eq 0 ]] ; then
	echo "############################"
        echo "## 4-flip the reads  #######"
        echo "############################"
	mkdir 4-flip-$NAME
	cd 4-flip-$NAME 
	mkdir trash

	for i in ../3-intersectBed-$NAME/intersect.*.snp.calls.txt
	do
	ln -s $i
	done

	$PL/alleledb_flipread2fastq -s 1 intersect.$FASTQ.mat.snp.calls.txt > intersect.$FASTQ.mat.flipread.fastq;  wc -l intersect.*mat.*
	$PL/alleledb_flipread2fastq -s 1 intersect.$FASTQ.pat.snp.calls.txt > intersect.$FASTQ.pat.flipread.fastq;  wc -l intersect.*pat.*

	cd ..
fi

## 5 alignment2
if [[ $FLAG -eq 5 || $FLAG -eq 0 ]] ; then
	echo "#####################################"
        echo "## 5-alignment2 flipped reads #######"
        echo "#####################################"
	mkdir 5-alignment2-$NAME
	cd 5-alignment2-$NAME
	mkdir trash

	for i in ../4-flip-$NAME/*.fastq
	do
	ln -s $i
	done

	bowtie --un intersect.$FASTQ.matflip2mat.flipread.unaligned --max intersect.$FASTQ.matflip2mat.flipread.multi --best --strata -v 2 -m 1 -q $PGENOME_PATH/AltRefMother/AltRefMother intersect.$FASTQ.mat.flipread.fastq > intersect.$FASTQ.matflip2mat.flipread.bowtie;  wc -l intersect.$FASTQ.matflip2mat.flipread.*
	bowtie --un intersect.$FASTQ.matflip2pat.flipread.unaligned --max intersect.$FASTQ.matflip2pat.flipread.multi --best --strata -v 2 -m 1 -q $PGENOME_PATH/AltRefFather/AltRefFather intersect.$FASTQ.mat.flipread.fastq > intersect.$FASTQ.matflip2pat.flipread.bowtie;  wc -l intersect.$FASTQ.matflip2pat.flipread.*

	bowtie --un intersect.$FASTQ.patflip2mat.flipread.unaligned --max intersect.$FASTQ.patflip2mat.flipread.multi --best --strata -v 2 -m 1 -q $PGENOME_PATH/AltRefMother/AltRefMother intersect.$FASTQ.pat.flipread.fastq > intersect.$FASTQ.patflip2mat.flipread.bowtie;  wc -l intersect.$FASTQ.patflip2mat.flipread.*
	bowtie --un intersect.$FASTQ.patflip2pat.flipread.unaligned --max intersect.$FASTQ.patflip2pat.flipread.multi --best --strata -v 2 -m 1 -q $PGENOME_PATH/AltRefFather/AltRefFather intersect.$FASTQ.pat.flipread.fastq > intersect.$FASTQ.patflip2pat.flipread.bowtie;  wc -l intersect.$FASTQ.patflip2pat.flipread.*

	bowtie --un intersect.$FASTQ.matflip2ref.flipread.unaligned --max intersect.$FASTQ.matflip2ref.flipread.multi --best --strata -v 2 -m 1 -q /gpfs/scratch/fas/gerstein/jc2296/reference_genomes/fasta/b37_g1k_phase2/Refhs37d5ss intersect.$FASTQ.mat.flipread.fastq > intersect.$FASTQ.matflip2ref.flipread.bowtie; wc -l intersect.$FASTQ.matflip2ref.flipread.*
	bowtie --un intersect.$FASTQ.patflip2ref.flipread.unaligned --max intersect.$FASTQ.patflip2ref.flipread.multi --best --strata -v 2 -m 1 -q /gpfs/scratch/fas/gerstein/jc2296/reference_genomes/fasta/b37_g1k_phase2/Refhs37d5ss intersect.$FASTQ.pat.flipread.fastq > intersect.$FASTQ.patflip2ref.flipread.bowtie; wc -l intersect.$FASTQ.patflip2ref.flipread.*

	cd ..
fi

## 6 unaligned
if [[ $FLAG -eq 6 || $FLAG -eq 0 ]] ; then
	echo "###########################################"
        echo "## 6-check unaligned flipped reads  #######"
        echo "###########################################"
	mkdir 6-unaligned-$NAME
	cd 6-unaligned-$NAME
	mkdir trash

	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.matflip2pat.flipread.unaligned 
	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.patflip2mat.flipread.unaligned 
	
	### original mat and pat
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.mat.snp.calls.txt
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.pat.snp.calls.txt
	
	$PL/alleledb_multis-and-unaligneds-wrapper.sh intersect.$FASTQ.matflip2pat.flipread.unaligned intersect.$FASTQ.mat.snp.calls.txt mat
	$PL/alleledb_multis-and-unaligneds-wrapper.sh intersect.$FASTQ.patflip2mat.flipread.unaligned intersect.$FASTQ.pat.snp.calls.txt pat
	
	cd ..
fi

## 7 multi
if [[ $FLAG -eq 7 || $FLAG -eq 0 ]] ; then
	echo "#######################################"
        echo "## 7-check multi flipped reads  #######"
        echo "#######################################"
	mkdir 7-multi-$NAME
	cd 7-multi-$NAME
	mkdir trash

	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.matflip2pat.flipread.multi
	ln -s ../5-alignment2-$NAME/intersect.$FASTQ.patflip2mat.flipread.multi

	### original mat and pat
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.mat.snp.calls.txt
	ln -s ../3-intersectBed-$NAME/intersect.$FASTQ.pat.snp.calls.txt
	
	$PL/alleledb_multis-and-unaligneds-wrapper.sh intersect.$FASTQ.matflip2pat.flipread.multi intersect.$FASTQ.mat.snp.calls.txt mat
        $PL/alleledb_multis-and-unaligneds-wrapper.sh intersect.$FASTQ.patflip2mat.flipread.multi intersect.$FASTQ.pat.snp.calls.txt pat
	
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

	cat originalmatreads.intersect.$FASTQ.matflip2pat.flipread.multi.bed originalpatreads.intersect.$FASTQ.patflip2mat.flipread.multi.bed | sed 's/\#\*o\*\#/\t/g' | cut -f4 | sort | uniq  > originalmatpatreads.multi.ids
	
	## Thunder can only do this on cluster since it is Java
	## 1) bed2fastq for mapped reads from folder 2 (smallfastq) for this we use all the original reads; concantenating mat and pat contains redundant entries - bedbowtie2fastq gives unique read info
	## 2) cut for BED and then sort and uniq to obtain ids; Thunder doesnt require them to be in order
	## 3) Thunder to obtain biasfiltered fastq

	## largefastq
	zcat $FASTQ | java -Xmx2G -jar $PL/alleledb_ThunderByRob.jar FilterFastxByIDList -b -IDs ./originalmatpatreads.multi.ids - | gzip -c > biasfiltered.$FASTQ    ;  echo $FASTQ ; zcat $FASTQ | wc -l ;  echo biasfiltered.$FASTQ ; zcat biasfiltered.$FASTQ | wc -l ;  mkdir src  ;  mv $FASTQ originalmatreads.intersect.$FASTQ.matflip2pat.flipread.multi.bed originalpatreads.intersect.$FASTQ.patflip2mat.flipread.multi.bed originalmatpatreads.multi.ids src  ;  make -f $PGENOME_PATH/PIPELINE.mk ;  echo \"folder=\\\"$(pwd)/\\\"; setwd(folder)\" | cat - $PL/alleledb_calcOverdispersion.R > alleledb_calcOverdispersion.R  ;  $PL/alleledb_alleleseqOutput2betabinomFormat.sh $NAME $AS counts ; R CMD BATCH ./alleledb_calcOverdispersion.R  ; echo \"folder=\\\"$(pwd)/\\\"; setwd(folder)\" | cat - $8/alleledb_alleleseqBetabinomial.R > alleleseqBetabinomial.R ; R CMD BATCH ./alleleseqBetabinomial.R  ;  $PL/alleledb_alleleseqOutput2betabinomFormat.sh $NAME $AS interestingHets ;  $PL/alleledb_alleleseqOutput2betabinomFormat.sh $NAME $AS interestingHets.betabinom   

#	cd ..
fi
 
