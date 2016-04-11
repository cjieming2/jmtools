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


## 8 fsieve original multi reads from original fastq
## then run alleleseq again on this filtered fastqs
	echo "##############################################"
	echo " 8 rerun alleleseq on bias filtered reads ####"
	echo "##############################################"

	cat originalmatreads.intersect.$FASTQ.matflip2pat.flipread.multi.bed originalpatreads.intersect.$FASTQ.patflip2mat.flipread.multi.bed | sed 's/\#\*o\*\#/\t/g' | cut -f4 | sort | uniq  > originalmatpatreads.multi.ids
	
	## Thunder can only do this on cluster since it is Java
	## 1) bed2fastq for mapped reads from folder 2 (smallfastq) for this we use all the original reads; concantenating mat and pat contains redundant entries - bedbowtie2fastq gives unique read info
	## 2) cut for BED and then sort and uniq to obtain ids; Thunder doesnt require them to be in order
	## 3) Thunder to obtain biasfiltered fastq

	## largefastq
	zcat $FASTQ | java -Xmx2G -jar $PL/alleledb_ThunderByRob.jar FilterFastxByIDList -b -IDs ./originalmatpatreads.multi.ids - | gzip -c > biasfiltered.$FASTQ    ;  echo $FASTQ ; zcat $FASTQ | wc -l ;  echo biasfiltered.$FASTQ ; zcat biasfiltered.$FASTQ | wc -l ;  mkdir src  ;  mv $FASTQ originalmatreads.intersect.$FASTQ.matflip2pat.flipread.multi.bed originalpatreads.intersect.$FASTQ.patflip2mat.flipread.multi.bed originalmatpatreads.multi.ids src  ;  make -f $PGENOME_PATH/PIPELINE.mk ;  echo \"folder=\\\"$(pwd)/\\\"; setwd(folder)\" | cat - $PL/alleledb_calcOverdispersion.R > alleledb_calcOverdispersion.R  ;  $PL/alleledb_alleleseqOutput2betabinomFormat.sh $NAME $AS counts ; R CMD BATCH ./alleledb_calcOverdispersion.R  ; echo \"folder=\\\"$(pwd)/\\\"; setwd(folder)\" | cat - $8/alleledb_alleleseqBetabinomial.R > alleleseqBetabinomial.R ; R CMD BATCH ./alleleseqBetabinomial.R  ;  $PL/alleledb_alleleseqOutput2betabinomFormat.sh $NAME $AS interestingHets ;  $PL/alleledb_alleleseqOutput2betabinomFormat.sh $NAME $AS interestingHets.betabinom   

#	cd ..
fi
 
