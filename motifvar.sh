#!/bin/bash

## THINGS TO DO
## --need to add catches (e.g. no files to softlink, die)"

if [[ "$#" -ne 5 && "$1" -ne -1 ]] ; then
	echo "==============================="
	echo "== USAGE ======================"
	echo "==============================="
	echo "motifvar.sh <flag> <smart domain name> <SMART fasta file> <Ensembl version> <Ensembl fasta file>" 
	echo "e.g. motifvar.sh 12 TPR /path/HUMAN_TPR.fa 73 - > motifvar-160424.log"
  echo "--note for paths no end '/' pls"
  echo "this script needs 5 arguments"
  echo "--if a file is module-specific, you can use '-' to replace"
  echo "arg1:flag (refer to flag code) "
  echo "arg2:domain name from SMART database, e.g. TPR"
  echo "arg3:full path of fasta file from SMART database, with header >smart|TPR-ensembl|ENSP00000245105|ENSP00000245105/560-593 no description [Homo sapiens]"
  echo "arg4:Ensembl version e.g. 73"
  echo "arg5:module 3; full path of fasta file from Ensembl BioMart, with header >19|ENSG00000104969|ENSP00000221566"  
  echo -e "\n\n"
  echo "==============================="
  echo "== FLAG CODE =================="
  echo "==============================="
  echo "\"protPos2gPos\": run only the module 'protPos2gPos' (SmartAApos2genomePos), which converts protein positions in SMART domains to genomic positions using Ensembl IDs of proteins with SMART domains"
  echo "1:fasta2prot; convert fasta files from SMART to tab-delimited files, using the fasta headers"
  echo "2:domain2info; requires \"protPos2gPos\", obtain domain info from protPos2gPos info master file"
  echo "3:info2seq; requires installation of WebLogo, with .bash_profile modified to run WebLogo (download from GitHub)"
  echo "a combination of modules:e.g. 12, will run modules 1 and 2; 123, runs modules 1,2 and 3"
  echo "-1: if $1 -eq -1, clean up everything; creates a folder 'trash'"
  echo "e.g. motifvar.sh -1"
  echo -e "\n\n"
	echo "==============================="
	echo "== 'protPos2gPos' module ======"
	echo "==============================="
	echo "arg1: protPos2gPos"
	echo "arg2: ensembl2coding file (adapted from Ensembl BioMart)"
	echo "      --file header: EnsemblGeneID   EnsemblTranscriptID"
	echo "        EnsemblProteinID    EnsemblExonID  chr      strand"  echo "genomicCodingStart (1-based)      genomicCodingEnd"
	echo "arg3: SMART domain file with EnsemblProtID (converted from"
	echo "      motifVar_smartAApos2tsv after obtaining SMART domain info from" 
	echo "Ensembl using perl_api_smart_domains_suganthi.pl)"
	echo "      --file header: chr     smart   protaastart     protaaend"
	echo "        EnsemblProtID"
	echo "arg4: SMART domain file directly from SMART database"
	echo "      --file header: DOMAIN  ACC     DEFINITION      DESCRIPTION"
	echo "arg5: ensembl version"
	echo "e.g. motifvar.sh protPos2gPos /ens/path/ensembl2coding_ens.noErr.txt /ens/path/allchr.ens73.noErr.tsv /smart/path/smart_domains_1158_all_131025.txt 73"

	exit 1
fi


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
	mv motifVar_protPos2gPos [12]-* trash
	mv *.err *.log trash
	
	exit 0

fi

#############################################################
## protPos2gPos - converts protein positions in SMART domains to genomic positions using EnsemblProtIDs and SMART domains
#############################################################
if [[ $1 == "protPos2gPos" ]] ; then
	## setting up
	## make directories, go in directory, set up links
	mkdir 0-motifVar_protPos2gPos
	cd 0-motifVar_protPos2gPos
	
	ENSEMBLFILE=$2
	DOMAINENSFILE=$3
	DOMAINFILE=$4
	ENS_VER=$5
	
	ln -s ${ENSEMBLFILE}
	ln -s ${DOMAINENSFILE}
	ln -s ${DOMAINFILE}

	## start log print
	echo "#######################" > 0-motifVar_protPos2gPos.log
	echo "## protPos2gPos #######" >> 0-motifVar_protPos2gPos.log
	echo "#######################" >> 0-motifVar_protPos2gPos.log
	
	date >> 0-motifVar_protPos2gPos.log
	
	## convert protein positions of SMART domains to genomic positions using Ensembl
	motifVar_smartAApos2genomePos -e ${ENSEMBLFILE} ${DOMAINENSFILE} | awk 'NR == 1; NR > 1 {if($2>$3){print $1"\t"$3"\t"$2"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10}else{print $0}}' > temp.txt
	
	## integrate SMART domain information
	fselect a.+,b.DOMAIN,b.DEFINITION from temp.txt, $DOMAINFILE where a.smart=b.ACC | sed 's/ /_/g' | sed -e 's/\t\t/\tNA\t/g' -e 's/\t\n/\tNA\n/g' > motifVar_protPos2gPos.ens${ENS_VER}.smartdomains.txt
	
	## housekeeping
	echo "Converting protein positions in SMART domains to genomic positions using EnsemblProtIDs and SMART domains... Done." >> 0-motifVar_protPos2gPos.log
	echo -e "motifVar_protPos2gPos.ens${ENS_VER}.smartdomains.txt created. \n\n"
	echo "**NOTE: Program ran successfully but pls note: post-processing on the smartDomain2gPos output file might be needed - e.g. ID errors, missing data, linesWprobs, CDS not fully annotated etc. This script doesn't check for these. Check Word documentation for details." >> 0-motifVar_protPos2gPos.log
	date >> 0-motifVar_protPos2gPos.log
	
	mkdir src
	mv ${ENSEMBLFILE} ${DOMAINENSFILE} ${DOMAINFILE} src
	
	rm temp.txt
	
	cd ..
	
	exit 0
	
fi
 

#############################

FLAG=$1
DOMAIN=$2  
SMARTFASTA_PATH=$3
ENS_VER=$4
ENSEMFASTA_PATH=$5


#############################
## print parameters to log
#############################
echo "FLAG               =${FLAG}"
echo "DOMAIN             =${DOMAIN}"
echo "SMARTFASTA_PATH    =${SMARTFASTA_PATH}"  
echo "ENS_VER            =${ENS_VER}"
echo "ENSEMFASTA_PATH    =${ENSEMFASTA_PATH}"


#############################################################
## 1 fasta2prot
#############################################################
if [[ ${FLAG} =~ 1 ]] ; then
	## setting up
	## make directories, go in directory, set up links
	mkdir 1-fasta2prot-${DOMAIN}
	cd 1-fasta2prot-${DOMAIN}
	
	IFILE="${DOMAIN}.fasta"
	OFILE_prot="${DOMAIN}.prot"
	OFILE_indi="${DOMAIN}.prot.indiv"
	LFILE="1-fasta2prot-${DOMAIN}.log"
	SFILE="${DOMAIN}_mostCommonMotifLen.txt"
	ln -s ${SMARTFASTA_PATH} ${IFILE}
	
	## start log print
	echo "######################" > ${LFILE}
	echo "## 1-fasta2prot ######" >> ${LFILE}
	echo "######################" >> ${LFILE}
	
	date >> ${LFILE}
	
	## converts smart fasta to tab-delimited prot grouped by proteins
	motifVar_fastaSmart2tsv4lyn ${IFILE} -o ${OFILE_prot}

	## converts smart fasta to tab-delimited prot split by individual motif
	motifVar_fastaSmart2tsv4lyn ${IFILE} -o ${OFILE_indi} -i 1
	
	echo "Converted SMART fasta to prot and prot.indiv... Done." >> ${LFILE}
	
	## obtain most common motif length
	distinct -kc$(head -2 ${OFILE_indi} | ftranspose | grep -n '' | sed 's/:/\t/g' | grep length | cut -f1) ${OFILE_indi} | sort -nrk2 | head -1 | cut -f1 > ${SFILE}
	
	echo -e "\n\n" >> ${LFILE}
	distinct -kc$(head -2 ${OFILE_indi} | ftranspose | grep -n '' | sed 's/:/\t/g' | grep length | cut -f1) ${OFILE_indi} | sort -nrk2 >> ${LFILE}
	
	echo "Obtained most common motif length... Done." >> ${LFILE}
	
	## housekeeping
	date >> ${LFILE}
	
	cd ..
fi

##############################################################
### 2 domain info (domain2info)
##############################################################
if [[ ${FLAG} =~ 2 ]] ; then
	## setting up
	## make directories, go in directory, set up links
	mkdir 2-domain2info-${DOMAIN}
	cd 2-domain2info-${DOMAIN}
	
	IFILE="motifVar_protPos2gPos.ens${ENS_VER}.smartdomains.txt"
	OFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.txt"
	LFILE="2-domain2info-${DOMAIN}.log"
	SFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.ensProteinIDList"
	ln -s ../0-motifVar_protPos2gPos/${IFILE}
	
	## start log print
	echo "#########################" > ${LFILE}
  echo "## 2-domain2info ########" >> ${LFILE}
  echo "#########################" >> ${LFILE}
  
  date >> ${LFILE}
	
	## get domain info file from master file created in protPos2gPos
	d=$(echo ${DOMAIN})
	awk '{OFS="\t"}{FS="\t"}{if($11 == "DOMAIN" || $11 == domain){print $0}}' domain=$d ${IFILE} > ${OFILE}
	
	echo "cut -f5 | uniq -c" >> ${LFILE}
	cut -f5 ${OFILE} | uniq -c >> ${LFILE}
	
	## produce unique Ensembl protein IDs with this domain
	cut -f8 ${OFILE} | sed 1d | sort | uniq > ${SFILE}
	
	## housekeeping
	date >> ${LFILE}
	
	echo -e "\n\nPlease use the ensProteinIDList on the Ensembl BioMart (archived or current version) to obtain the fasta file for the proteins and include the fasta file in this folder - named similar to ensProteinIDList with .fasta extension" >> ${LFILE}

	cd ..
fi



##############################################################
### 3  add domain sequence (info2seq)
##############################################################
if [[ ${FLAG} =~ 3 ]] ; then
	
	## set up
	mkdir 3-domaininfo2seq-${DOMAIN}
	cd 3-domaininfo2seq-${DOMAIN}
	
	IFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.txt"
	OFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.seq.txt"
	NFILE="${DOMAIN}_mostCommonMotifLen.txt"
	ln -s ../1-fasta2prot-${DOMAIN}/${NFILE}
	CLEN=$(cat ${NFILE})
  OFILE2="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.seq.${CLEN}aa.txt"
	LFILE="3-domaininfo2seq-${DOMAIN}.log"
	SFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.seq.${CLEN}aa.1${DOMAIN}"
	ln -s ../2-domain2info-${DOMAIN}/${IFILE}
	
	## start log printing	
	echo "##########################" > ${LFILE}
  echo "## 3-info2seq ############" >> ${LFILE}
  echo "##########################" >> ${LFILE}
  
  date >> ${LFILE}

	## integrate sequence from fasta file from BioMart
	motifVar_fastaGrab -f ${ENSEMFASTA_PATH} ${IFILE} > ${OFILE}
  
  ## grab info and sequences of the most common motif length
  awk '{OFS="\t"}{FS="\t"}{if($10 == commonlength || $10 == "motifSize"){print $0}}' commonlength=${CLEN} ${OFILE} > ${OFILE2}

	## create sequence logos of most common motif length using WebLogo
	cut -f11 ${OFILE2} | sed 1d | sort | uniq > ${SFILE}
	weblogo -f ${SFILE} -o ${SFILE}.pdf -F pdf -A protein -U bits --composition "{'L':9.975,'A':7.013,'S':8.326,'V':5.961,'G':6.577,'K':5.723,'T':5.346,'I':4.332','E':7.096,'P':6.316,'R':5.650,'D':4.728,'F':3.658,'Q':4.758,'N':3.586,'Y':2.653,'C':2.307,'H':2.639,'M':2.131,'W':1.216}"  -n ${CLEN} -c chemistry --stack-width 25 --errorbars no

  ## housekeeping
	date >> ${LFILE}
	
	cd ..
fi



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
