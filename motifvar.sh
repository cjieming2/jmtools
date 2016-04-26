#!/bin/bash
### motifvar.sh <flag> <smart domain name> <SMART fasta file>
### e.g. motifvar.sh 0 TPR /path/HUMAN_TPR.fa > motifvar-160424.log
## note for paths no end '/' pls
## flag 0 runs everything except flag "protPos2gPos" (SmartAApos2genomePos), which converts protein positions in SMART domains to genomic positions using Ensembl IDs of proteins with SMART domains

##===============================
##== FLAG CODE ==================
## "protPos2gPos": run only the module 'protPos2gPos'
## 0:run everything from 1-8
## 1:fasta2prot; convert fasta files from SMART to tab-delimited files, using the fasta headers
##-1: if $1 -eq -1, clean up everything; creates a folder 'trash'
## 	 e.g. motifvar.sh -1



##===============================
##== 'protPos2gPos' module ======
##===============================
## arg1: protPos2gPos
## arg2: ensembl2coding file (adapted from Ensembl BioMart)
##       --file header: EnsemblGeneID   EnsemblTranscriptID     EnsemblProteinID    EnsemblExonID  chr      strand  genomicCodingStart (1-based)      genomicCodingEnd
## arg3: SMART domain file with EnsemblProtID (converted from motifVar_smartAApos2tsv after obtaining SMART domain info from Ensembl using perl_api_smart_domains_suganthi.pl)
##       --file header: chr     smart   protaastart     protaaend       EnsemblProtID
## arg4: SMART domain file directly from SMART database
##       --file header: DOMAIN  ACC     DEFINITION      DESCRIPTION
## arg5: ensembl version
## e.g. motifvar.sh protPos2gPos /ens/path/ensembl2coding_ens.noErr.txt /ens/path/allchr.ens73.noErr.tsv /smart/path/smart_domains_42_131025.txt 73




#######################################################
## this causes the script to exit if there's any error in any part of the pipeline 
## The shell does NOT exit if the command that fails is part of the command list 
## immediately following a while or until keyword, part of the test in an if statement, 
## part of a && or || list, or if the command's return value is being inverted via !
#set -e

#############################################################
## -1 clean up everything
#############################################################
if [[ $1 -eq -1 ]] ; then

	mkdir trash
	mv * trash
	mv *.log trash
	
	exit 0

fi

#############################################################
## protPos2gPos - converts protein positions in SMART domains to genomic positions using EnsemblProtIDs and SMART domains
#############################################################
if [[ $1 == "protPos2gPos" ]] ; then
	## setting up
	## make directories, go in directory, set up links
	mkdir protPos2gPos
	cd protPos2gPos
	
	ENSEMBLFILE=$2
	DOMAINENSFILE=$3
	DOMAINFILE=$4
	ENS_VER=$5
	
	ln -s ${ENSEMBLFILE}
	ln -s ${DOMAINENSFILE}
	ln -s ${DOMAINFILE}

	## start log print
	echo "#######################" > protPos2gPos.log
	echo "## protPos2gPos #######" >> protPos2gPos.log
	echo "#######################" >> protPos2gPos.log
	
	date >> protPos2gPos.log
	
	## convert protein positions of SMART domains to genomic positions using Ensembl
	motifVar_smartAApos2genomePos -e ${ENSEMBLFILE} ${DOMAINENSFILE} | awk 'NR == 1; NR > 1 {if($2>$3){print $1"\t"$3"\t"$2"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10}else{print $0}}' > temp.txt
	
	## integrate SMART domain information
	fselect a.+,b.DOMAIN,b.DEFINITION from temp.txt, $DOMAINFILE where a.smart=b.ACC | sed 's/ /_/g' > smartDomain2gPos.ens${ENS_VER}.alldomainfeatures.txt
	
	echo "Converting protein positions in SMART domains to genomic positions using EnsemblProtIDs and SMART domains... Done." >> protPos2gPos.log
	echo "NOTE: post-processing on the smartDomain2gPos output file might be needed - e.g. ID errors, missing data, linesWprobs, CDS not fully annotated etc. Check Word documentation." >> protPos2gPos.log
	date >> protPos2gPos.log
	
	rm temp.txt
	
	cd ..
	
	exit 0
	
fi
 

#############################

FLAG=$1
DOMAIN=$2  
SMARTFASTA_PATH=$3
ENS_VER=$4


#############################
## print parameters to log
#############################
echo "FLAG               =${FLAG}"
echo "DOMAIN             =${DOMAIN}"
echo "SMARTFASTA_PATH    =${SMARTFASTA_PATH}"  
echo "ENS_VER            =${ENS_VER}"


#############################################################
## 1 fasta2prot
#############################################################
if [[ ${FLAG} -eq 1 || ${FLAG} -eq 0 ]] ; then
	## setting up
	## make directories, go in directory, set up links
	mkdir 1-fasta2prot-${DOMAIN}
	cd 1-fasta2prot-${DOMAIN}
	ln -s ${SMARTFASTA_PATH} ${DOMAIN}.fasta
	
	## start log print
	echo "######################" > 1-fasta2prot-${DOMAIN}.log
	echo "## 1-fasta2prot #######" >> 1-fasta2prot-${DOMAIN}.log
	echo "######################" >> 1-fasta2prot-${DOMAIN}.log
	
	date >> 1-fasta2prot-${DOMAIN}.log
	
	## converts smart fasta to tab-delimited prot grouped by proteins
	motifVar_fastaSmart2tsv4lyn ${SMARTFASTA_PATH} -o ${DOMAIN}.prot

	## converts smart fasta to tab-delimited prot split by individual motif
	motifVar_fastaSmart2tsv4lyn ${SMARTFASTA_PATH} -o ${DOMAIN}.prot.indiv -i 1
	
	echo "Converting SMART fasta to prot and prot.indiv... Done." >> 1-fasta2prot-${DOMAIN}.log
	date >> 1-fasta2prot-${DOMAIN}.log
	
	cd ..
fi

##############################################################
### 2 map to ref
##############################################################
#if [[ ${FLAG} -eq 2 || ${FLAG} -eq 0 ]] ; then
#	## setting up
#	## make directories, go in directory, set up links
#	mkdir 2-map.back.ref-${NAME}
#	cd 2-map.back.ref-${NAME}
#	
#	## start log print
#	echo "#######################" > 2-map.back.ref-${NAME}.log
#  echo "## 2-map to ref #######" >> 2-map.back.ref-${NAME}.log
#  echo "#######################" >> 2-map.back.ref-${NAME}.log
#  
#  date >> 2-map.back.ref-${NAME}.log
#  
#	
#	## chain files
#	ln -s ${PGENOME_PATH}/mat2ref.chain
#	ln -s ${PGENOME_PATH}/pat2ref.chain
#
#	for i in ../1-alignment-${NAME}/*.bowtie
#	do
#	ln -s $i
#	done
#
#	## map
#	## there is a lot of compute here
#	${PL}/alleledb_map.back.ref.wrapper.sh ${FASTQ}.mat.bowtie maternal MAT mat2ref.chain ${PL} &
#	${PL}/alleledb_map.back.ref.wrapper.sh ${FASTQ}.pat.bowtie paternal PAT pat2ref.chain ${PL} &
#	
#	wait
#
#	## postprocess
#	wc -l *.maternal.*.bed >> 2-map.back.ref-${NAME}.log
#	wc -l *.paternal.*.bed >> 2-map.back.ref-${NAME}.log
#
#	#### clean up/debugging code ####
#	#cat \
#	#${FASTQ}.[mp]at.bowtie.[1-9]_[mp]aternal.bed \
#	#${FASTQ}.[mp]at.bowtie.1[0-9]_[mp]aternal.bed \
#	#${FASTQ}.[mp]at.bowtie.2[0-2]_[mp]aternal.bed \
#	#${FASTQ}.[mp]at.bowtie.[XY]_[mp]aternal.bed > ${FASTQ}.[mp]at.bowtie.${MATPATERNAL}.bed
#	rm ${FASTQ}.mat.bowtie.*_maternal.bed ${FASTQ}.mat.bowtie.*_maternal.bowtie
#	rm ${FASTQ}.pat.bowtie.*_paternal.bed ${FASTQ}.pat.bowtie.*_paternal.bowtie
#	
#	date >> 2-map.back.ref-${NAME}.log
#	
#	cd ..
#fi
#
#
#
#
##############################################################
### 3  intersectBed
##############################################################
#if [[ ${FLAG} -eq 3 || ${FLAG} -eq 0 ]] ; then
#	
#	## set up
#	mkdir 3-intersectBed-${NAME}
#	cd 3-intersectBed-${NAME}
#	ln -s ${SNPCALLS_PATH}
#	
#	
#	## start log printing	
#	echo "##########################" > 3-intersectBed-${NAME}.log
#  echo "## 3-intersectBed  #######" >> 3-intersectBed-${NAME}.log
#  echo "##########################" >> 3-intersectBed-${NAME}.log
#  
#  date >> 3-intersectBed-${NAME}.log
#
#	for i in ../2-map.back.ref-${NAME}/*.map2ref.bed
#	do
#	ln -s $i
#	done
#	
#	## intersect
#	## note that my chain files do not have prefix "chr"; could do away if present
#	intersectBed -a <(awk '{OFS="\t"}{FS="\t"}{print "chr"$0}' ${FASTQ}.mat.bowtie.maternal.map2ref.bed) -b snp.calls.bed -wa -wb > intersect.${FASTQ}.mat.snp.calls.txt &
#	intersectBed -a <(awk '{OFS="\t"}{FS="\t"}{print "chr"$0}' ${FASTQ}.pat.bowtie.paternal.map2ref.bed) -b snp.calls.bed -wa -wb > intersect.${FASTQ}.pat.snp.calls.txt &
#	
#	wait
#	
#	## preprocess
#	wc -l intersect.${FASTQ}.mat.snp.calls.txt >> 3-intersectBed-${NAME}.log
#	wc -l intersect.${FASTQ}.pat.snp.calls.txt >> 3-intersectBed-${NAME}.log
#	
#	date >> 3-intersectBed-${NAME}.log
#	
#	cd ..
#fi
#
#
#
#
##############################################################
### 4 flip the reads
##############################################################
#if [[ ${FLAG} -eq 4 || ${FLAG} -eq 0 ]] ; then
#	## set up
#	mkdir 4-flip-${NAME}
#	cd 4-flip-${NAME} 
#	
#	## start log printing
#	echo "############################" > 4-flip-${NAME}.log
#  echo "## 4-flip the reads  #######" >> 4-flip-${NAME}.log
#  echo "############################" >> 4-flip-${NAME}.log
#  
#  date >> 4-flip-${NAME}.log
#  
#	
#	for i in ../3-intersectBed-${NAME}/intersect.*.snp.calls.txt
#	do
#	ln -s $i
#	done
#	
#	## flip and convert to fastq
#	sort -nk4,4 intersect.${FASTQ}.mat.snp.calls.txt | ${PL}/flipread flipread2fastq 0 5 intersect.${FASTQ}.mat.snp.calls stdin | gzip -c > intersect.${FASTQ}.mat.flipread.fastq.gz &
#	sort -nk4,4 intersect.${FASTQ}.pat.snp.calls.txt | ${PL}/flipread flipread2fastq 0 5 intersect.${FASTQ}.pat.snp.calls stdin | gzip -c > intersect.${FASTQ}.pat.flipread.fastq.gz &
#	
#	wait
#	
#	## postprocess
#	echo -e "$(zcat intersect.${FASTQ}.mat.flipread.fastq.gz | wc -l) intersect.${FASTQ}.mat.flipread.fastq.gz" >> 4-flip-${NAME}.log
#	wc -l *.mat.*.ids >> 4-flip-${NAME}.log
#	
#	echo -e "$(zcat intersect.${FASTQ}.pat.flipread.fastq.gz | wc -l) intersect.${FASTQ}.pat.flipread.fastq.gz" >> 4-flip-${NAME}.log
#	wc -l *.pat.*.ids >> 4-flip-${NAME}.log
#	
#	date >> 4-flip-${NAME}.log
#	
#	cd ..
#fi
#
#
#
#
#
#
##############################################################
### 5 alignment2
##############################################################
#if [[ ${FLAG} -eq 5 || ${FLAG} -eq 0 ]] ; then
#	
#	## set up
#	mkdir 5-alignment2-${NAME}
#	cd 5-alignment2-${NAME}
#	
#	## start log printing
#	echo "#####################################" > 5-alignment2-${NAME}.log
#  echo "## 5-alignment2 flipped reads #######" >> 5-alignment2-${NAME}.log
#  echo "#####################################" >> 5-alignment2-${NAME}.log
#  
#  date >> 5-alignment2-${NAME}.log
#
#
#	for i in ../4-flip-${NAME}/*.fastq.gz
#	do
#	ln -s $i
#	done
#
#	## align flipped reads
#	# mat flip to mat and pat genomes
#	zcat intersect.${FASTQ}.mat.flipread.fastq.gz | bowtie --un intersect.${FASTQ}.matflip2pat.flipread.unaligned --max intersect.${FASTQ}.matflip2pat.flipread.multi --best --strata -v 2 -m 1 -q ${PGENOME_PATH}/AltRefFather/AltRefFather - > intersect.${FASTQ}.matflip2pat.flipread.bowtie 2> intersect.${FASTQ}.matflip2pat.flipread.log &  
#
#	# pat flip to mat and pat genomes
#	zcat intersect.${FASTQ}.pat.flipread.fastq.gz | bowtie --un intersect.${FASTQ}.patflip2mat.flipread.unaligned --max intersect.${FASTQ}.patflip2mat.flipread.multi --best --strata -v 2 -m 1 -q ${PGENOME_PATH}/AltRefMother/AltRefMother - > intersect.${FASTQ}.patflip2mat.flipread.bowtie 2> intersect.${FASTQ}.patflip2mat.flipread.log &
#	
#	wait
#	
#	## make chain files
#	ln -s ${PGENOME_PATH}/mat2ref.chain
#	ln -s ${PGENOME_PATH}/pat2ref.chain
#	
#	## check if mat and pat locations of the same read match
#	## map back to reference; mat and pat locations should match
#	${PL}/alleledb_map.back.ref.wrapper.sh intersect.${FASTQ}.matflip2pat.flipread.bowtie paternal PAT pat2ref.chain ${PL} &
#	${PL}/alleledb_map.back.ref.wrapper.sh intersect.${FASTQ}.patflip2mat.flipread.bowtie maternal MAT mat2ref.chain ${PL} &
#	
#	wait 
#	
#	## compare mat and pat reference coordinates
#	join -t $'\t' <(sed 's/\#\*o\*\#/\t/g' intersect.${FASTQ}.matflip2pat.flipread.bowtie.paternal.map2ref.bed | awk '{OFS="\t"}{FS="\t"}{print $4,$1,$2,$3}' | sort ) \
#	<(sed 's/\#\*o\*\#/\t/g' intersect.${FASTQ}.patflip2mat.flipread.bowtie.maternal.map2ref.bed | awk '{OFS="\t"}{FS="\t"}{print $4,$1,$2,$3}' | sort ) \
#	| sort | uniq | awk '{OFS="\t"}{FS="\t"}{if($2!=$5 && (sqrt(($3-$6)^2)>10 || sqrt(($4-$7)^2)>10)){print $0}}' > matpat.remove.reads.location.not.matched.txt
#	
#	
#	## remove the mapping intermediate files
#	rm intersect.${FASTQ}.matflip2pat.flipread.bowtie.*_paternal.bed intersect.${FASTQ}.matflip2pat.flipread.bowtie.*_paternal.bowtie intersect.${FASTQ}.matflip2pat.flipread.bowtie.paternal.map2ref.bed intersect.${FASTQ}.matflip2pat.flipread.bowtie.paternal.unmap2ref.log
#	rm intersect.${FASTQ}.patflip2mat.flipread.bowtie.*_maternal.bed intersect.${FASTQ}.patflip2mat.flipread.bowtie.*_maternal.bowtie intersect.${FASTQ}.patflip2mat.flipread.bowtie.maternal.map2ref.bed intersect.${FASTQ}.patflip2mat.flipread.bowtie.maternal.unmap2ref.log
#	
#	## postprocessing
#	echo "Note that there are redundancies in read IDs of the all files from here on due to multiple flipped reads simulated from reads that overlap >1 hetSNVs; unless there are only reads with 1 SNV" >> 5-alignment2-${NAME}.log
#	echo "Here, the matpat.remove.reads.~txt file is only sorted and unique by row, not by read IDs" >> 5-alignment2-${NAME}.log
#	wc -l intersect.${FASTQ}.matflip2pat.flipread.* >> 5-alignment2-${NAME}.log
#	wc -l intersect.${FASTQ}.patflip2mat.flipread.* >> 5-alignment2-${NAME}.log
#	wc -l matpat.remove.reads.location.not.matched.txt >> 5-alignment2-${NAME}.log
#	
#	date >> 5-alignment2-${NAME}.log
#	
#	cd ..
#fi
#
#
#
#
#
##############################################################
### 6 unaligned
##############################################################
#if [[ ${FLAG} -eq 6 || ${FLAG} -eq 0 ]] ; then
#	## set up
#	mkdir 6-unaligned-${NAME}
#	cd 6-unaligned-${NAME}
#	
#	
#	## start log printing
#	echo "###########################################" > 6-unaligned-${NAME}.log
#  echo "## 6-check unaligned flipped reads  #######" >> 6-unaligned-${NAME}.log
#  echo "###########################################" >> 6-unaligned-${NAME}.log
#  
#  date >> 6-unaligned-${NAME}.log
#
#	ln -s ../5-alignment2-${NAME}/intersect.${FASTQ}.matflip2pat.flipread.unaligned 
#	ln -s ../5-alignment2-${NAME}/intersect.${FASTQ}.patflip2mat.flipread.unaligned 
#	
#	## original mat and pat
#	ln -s ../3-intersectBed-${NAME}/intersect.${FASTQ}.mat.snp.calls.txt
#	ln -s ../3-intersectBed-${NAME}/intersect.${FASTQ}.pat.snp.calls.txt
#
#	## preprocess for unaligned analyses	
#	echo "Note that there are redundancies in read IDs of the all files from here on due to multiple flipped reads simulated from reads that overlap >1 hetSNVs; unless there are only reads with 1 SNV"
#	${PL}/alleledb_multis-and-unaligneds-wrapper.sh intersect.${FASTQ}.matflip2pat.flipread.unaligned intersect.${FASTQ}.mat.snp.calls.txt mat ${PL}
#	${PL}/alleledb_multis-and-unaligneds-wrapper.sh intersect.${FASTQ}.patflip2mat.flipread.unaligned intersect.${FASTQ}.pat.snp.calls.txt pat ${PL}
#	
#	date >> 6-unaligned-${NAME}.log
#	
#	cd ..
#fi
#
#
#
#
#
##############################################################
### 7 multi
##############################################################
#if [[ ${FLAG} -eq 7 || ${FLAG} -eq 0 ]] ; then
#	## set up
#	mkdir 7-multi-${NAME}
#	cd 7-multi-${NAME}
#	
#	## start log printing
#	echo "#######################################" > 7-multi-${NAME}.log
#  echo "## 7-check multi flipped reads  #######" >> 7-multi-${NAME}.log
#  echo "#######################################" >> 7-multi-${NAME}.log
#  
#  date >> 7-multi-${NAME}.log
#
#	ln -s ../5-alignment2-${NAME}/intersect.${FASTQ}.matflip2pat.flipread.multi
#	ln -s ../5-alignment2-${NAME}/intersect.${FASTQ}.patflip2mat.flipread.multi
#
#	## original mat and pat
#	ln -s ../3-intersectBed-${NAME}/intersect.${FASTQ}.mat.snp.calls.txt
#	ln -s ../3-intersectBed-${NAME}/intersect.${FASTQ}.pat.snp.calls.txt
#	
#	## preprocess for multimappers
#	echo "Note that there are redundancies in read IDs of the all files from here on due to multiple flipped reads simulated from reads that overlap >1 hetSNVs; unless there are only reads with 1 SNV"
#	${PL}/alleledb_multis-and-unaligneds-wrapper.sh intersect.${FASTQ}.matflip2pat.flipread.multi intersect.${FASTQ}.mat.snp.calls.txt mat ${PL}
#  ${PL}/alleledb_multis-and-unaligneds-wrapper.sh intersect.${FASTQ}.patflip2mat.flipread.multi intersect.${FASTQ}.pat.snp.calls.txt pat ${PL}
#	
#	date >> 7-multi-${NAME}.log
#	
#	cd ..
#fi
#
### get out of allelicbias folder
#cd ..
#
#
#
#
#
##############################################################
### 8 fsieve original multi reads from original fastq
### then run alleleseq again on this filtered fastqs
##############################################################
#if [[ ${FLAG} -eq 8 || ${FLAG} -eq 0 ]] ; then
#	echo "################################################" > 8-final-run.log
#	echo "## 8 rerun alleleseq on bias filtered reads ####" >> 8-final-run.log
#	echo "################################################" >> 8-final-run.log
#	
#	date >> 8-final-run.log
#
#	## 1) cut for BED and then sort and uniq to obtain ids
#	## 2a) removes reads from original aligned bowtie files in folder 1
#	## 2b) Run AlleleSeq-betabinomial on filtered bowtie
#	
#	ln -s ./allelicbias-${PGENOME}-${NAME}/1-alignment-${NAME}/${FASTQ}.mat.bowtie
#	ln -s ./allelicbias-${PGENOME}-${NAME}/1-alignment-${NAME}/${FASTQ}.pat.bowtie
#	
#	## 1) create ID list of all reads that multimap	
#	echo "Note that all redundancies in read IDs that are to be removed are made unique here"
#	cat <(cat ./allelicbias-${PGENOME}-${NAME}/7-multi-${NAME}/originalpatreads.intersect.${FASTQ}.patflip2mat.flipread.multi.bed ./allelicbias-${PGENOME}-${NAME}/7-multi-${NAME}/originalmatreads.intersect.${FASTQ}.matflip2pat.flipread.multi.bed | sed 's/\#\*o\*\#/\t/g' | cut -f4) \
#	./allelicbias-${PGENOME}-${NAME}/4-flip-${NAME}/intersect.${FASTQ}.mat.snp.calls.removedreads.ids \
#	./allelicbias-${PGENOME}-${NAME}/4-flip-${NAME}/intersect.${FASTQ}.mat.snp.calls.taggedreads.ids \
#	./allelicbias-${PGENOME}-${NAME}/4-flip-${NAME}/intersect.${FASTQ}.mat.snp.calls.tooManySNVsReads.ids \
#	./allelicbias-${PGENOME}-${NAME}/4-flip-${NAME}/intersect.${FASTQ}.pat.snp.calls.removedreads.ids \
#	./allelicbias-${PGENOME}-${NAME}/4-flip-${NAME}/intersect.${FASTQ}.pat.snp.calls.taggedreads.ids \
#	./allelicbias-${PGENOME}-${NAME}/4-flip-${NAME}/intersect.${FASTQ}.pat.snp.calls.tooManySNVsReads.ids \
#	<(cut -f1 ./allelicbias-${PGENOME}-${NAME}/5-alignment2-${NAME}/matpat.remove.reads.location.not.matched.txt) \
#	 | sort | uniq > originalmatpatreads.toremove.ids
#
#
#
#	## 2) run alleleseq with betabinomial calculations
#	echo "##############################" >> 8-final-run.log
#	echo "### ALLELESEQ-BINOMIAL-RUN ###" >> 8-final-run.log
#	echo "##############################" >> 8-final-run.log
#	date >> 8-final-run.log
#	make -f ${PGENOME_PATH}/${PIPELINEFILE} PREFIX=${FASTQ} >> 8-final-run.log
#	
#	${PL}/alleledb_alleleseqOutput2betabinomFormat.sh ${NAME} ${AS} ${PL} counts
#	${PL}/alleledb_alleleseqOutput2betabinomFormat.sh ${NAME} ${AS} ${PL} interestingHets 
#	
#	# betabinomial
#	echo "folder=\"$(pwd)/\"; setwd(folder)" | cat - ${PL}/alleledb_calcOverdispersion.R > calcOverdispersion.R 
#	R CMD BATCH ./calcOverdispersion.R  
#	echo "folder=\"$(pwd)/\"; setwd(folder)" | cat - ${PL}/alleledb_alleleseqBetabinomial.R > alleleseqBetabinomial.R 
#	R CMD BATCH "--args FDR.thresh=$FDR_THRESH" ./alleleseqBetabinomial.R  
#	
#	${PL}/alleledb_alleleseqOutput2betabinomFormat.sh ${NAME} ${AS} ${PL} interestingHets.betabinom
#	${PL}/alleledb_alleleseqOutput2betabinomFormat.sh ${NAME} ${AS} ${PL} counts.betabinom
#	
#	date >> 8-final-run.log
#fi
#
#
