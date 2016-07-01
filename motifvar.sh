#!/bin/bash

## THINGS TO DO
## --need to add catches (e.g. no files to softlink, die)"
## --dependencies 
##   - requires VEP installation for module 6 (otherwise you do not need VEP)
##   - requires intersectBed from bedtools

if [[ "$#" -ne 9 && "$1" -ne -1 ]] ; then
	echo "==============================="
	echo "== USAGE ======================"
	echo "==============================="
	echo "motifvar.sh <flag> <smart domain name> <SMART fasta file> <Ensembl version> <Ensembl fasta file> <ensembl2coding file> <SNV BED file> <column number> <SNV catalog name>" 
	echo "e.g. motifvar.sh 12 TPR /path/HUMAN_TPR.fa 73 - ExAC.pass.bed 8 ExAC.r0.3 > motifvar-160424.log"
  echo "--note for paths do not end with '/' pls"
  echo "this script needs 7 arguments"
  echo "--if a file is module-specific, you can use '-' to replace"
  echo "arg1:flag (refer to flag code) "
  echo "arg2:domain name from SMART database, e.g. TPR"
  echo "arg3:full path of fasta file from SMART database, with header >smart|TPR-ensembl|ENSP00000245105|ENSP00000245105/560-593 no description [Homo sapiens]"
  echo "arg4:Ensembl version e.g. 73"
  echo "arg5:module 3; full path of fasta file from Ensembl BioMart, with header >19|ENSG00000104969|ENSP00000221566" 
  echo "arg6:module 4; full path of ensembl2coding file (adapted from Ensembl BioMart); required by module 'protPos2gPos' as well"
  echo "      --file header: EnsemblGeneID   EnsemblTranscriptID"
	echo "        EnsemblProteinID    EnsemblExonID  chr      strand"  echo "genomicCodingStart (1-based)      genomicCodingEnd"
	echo "arg7:module 5; SNV BED file (should be in folder 4)"
	echo "arg8:module 5; column for allele count in SNV BED file to filter singletons (AC=1)"
	echo "arg9:module 5; SNV catalog name, e.g. ExAC.r0.3"
  echo -e "\n\n"
  echo "==============================="
  echo "== FLAG CODE =================="
  echo "==============================="
  echo "\"protPos2gPos\": run only the module 'protPos2gPos' (SmartAApos2genomePos), which converts protein positions in SMART domains to genomic positions using Ensembl IDs of proteins with SMART domains"
  echo "1:fasta2prot; convert fasta files from SMART to tab-delimited files, using the fasta headers"
  echo "2:domain2info; requires \"protPos2gPos\", obtain domain info from protPos2gPos info master file"
  echo "3:info2seq; requires installation of WebLogo, with .bash_profile modified to run WebLogo (download from GitHub), grabs protein sequences and make a sequence logo using WebLogo"
  echo "4:domain2codon; requires modules 1 and 3, outputs a BED file; splice up the DNA sequences into codons using ensembl2coding file"
  echo "a combination of modules:e.g. 12, will run modules 1 and 2; 123, runs modules 1,2 and 3"
  echo "5:codonIntersectSnv; requires modules 1 and 4, output a BED file; intersects codon BED file with SNV BED file, removes chrX, chrY, chrM (auto), removes allele count 1 based on arg8 provided by user"
  echo "6:VEP; include information from VEP, requires VEP installation"
  echo "-1: if $1 -eq -1, clean up everything; creates a folder 'trash'"
  echo "e.g. motifvar.sh -1"
  echo -e "\n\n"
	echo "==============================="
	echo "== 'protPos2gPos' module ======"
	echo "==============================="
	echo "arg1: protPos2gPos"
	echo "arg2: ensembl2coding file path (adapted from Ensembl BioMart)"
	echo "      --file header: EnsemblGeneID   EnsemblTranscriptID"
	echo "        EnsemblProteinID    EnsemblExonID  chr      strand"  echo "genomicCodingStart (1-based)      genomicCodingEnd"
	echo "arg3: SMART domain file path with EnsemblProtID (converted from"
	echo "      motifVar_smartAApos2tsv after obtaining SMART domain info from" 
	echo "Ensembl using perl_api_smart_domains_suganthi.pl)"
	echo "      --file header: chr     smart   protaastart     protaaend"
	echo "        EnsemblProtID"
	echo "arg4: SMART domain file path directly from SMART database"
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
	
	LFILE="0-motifVar_protPos2gPos.log"
	
	ln -s ${ENSEMBLFILE}
	ln -s ${DOMAINENSFILE}
	ln -s ${DOMAINFILE}

	## start log print
	echo "#######################" > ${LFILE}
	echo "## protPos2gPos #######" >> ${LFILE}
	echo "#######################" >> ${LFILE}
	 
	echo "Parameters:" >> ${LFILE}
	echo "ENSEMBL FILE         =${ENSEMBLFILE}" >> ${LFILE}
	echo "DOMAIN ENSEMBL FILE  =${DOMAINENSFILE}" >> ${LFILE}
	echo "DOMAIN FILE          =${DOMAINFILE}" >> ${LFILE}
	echo "ENSEMBL DB VERSION   =${ENS_VER}" >> ${LFILE}
	
	echo "\n\n" >> ${LFILE}
	
	date >> ${LFILE}
	
	## convert protein positions of SMART domains to genomic positions using Ensembl
	motifVar_smartAApos2genomePos -e ${ENSEMBLFILE} ${DOMAINENSFILE} | awk 'NR == 1; NR > 1 {if($2>$3){print $1"\t"$3"\t"$2"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10}else{print $0}}' > temp.txt
	
	## integrate SMART domain information
	fselect a.+,b.DOMAIN,b.DEFINITION from temp.txt, $DOMAINFILE where a.smart=b.ACC | sed 's/ /_/g' | sed -e 's/\t\t/\tNA\t/g' -e 's/\t\n/\tNA\n/g' > motifVar_protPos2gPos.ens${ENS_VER}.smartdomains.txt
	
	## housekeeping
	echo "Converting protein positions in SMART domains to genomic positions using EnsemblProtIDs and SMART domains... Done." >> ${LFILE}
	echo -e "motifVar_protPos2gPos.ens${ENS_VER}.smartdomains.txt created. \n\n"
	echo "Program ran successfully" >> ${LFILE}
	echo "[MANUAL WORK] Pls note: post-processing on the smartDomain2gPos output file might be needed - e.g. ID errors, missing data, linesWprobs, CDS not fully annotated etc. This script doesn't check for these. Check Word documentation for details." >> ${LFILE}
	date >> ${LFILE}
	
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
ENSEMBFILE_PATH=$6
SNV_BED=$7
AC_COL=$8
SNV_NAME=$9


#############################
## print parameters to log
#############################
echo "FLAG               =${FLAG}"
echo "DOMAIN             =${DOMAIN}"
echo "SMARTFASTA_PATH    =${SMARTFASTA_PATH}"  
echo "ENS_VER            =${ENS_VER}"
echo "ENSEMFASTA_PATH    =${ENSEMFASTA_PATH}"
echo "ENSEMBFILE_PATH    =${ENSEMBFILE_PATH}"
echo "SNV_BED            =${SNV_BED}"
echo "ALLELE_COUNT_COL   =${AC_COL}"
echo "SNV_CATALOG_NAME   =${SNV_NAME}"

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
	
	echo -e "\n\n[MANUAL WORK] Please use the ensProteinIDList on the Ensembl BioMart (archived or current version) to obtain the fasta file for the proteins and include the fasta file in this folder - named similar to ensProteinIDList with .fasta extension" >> ${LFILE}

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


##############################################################
### 4 domain2codon
##############################################################
if [[ ${FLAG} =~ 4 ]] ; then
	## set up
	mkdir 4-domain2codon-${DOMAIN}
	cd 4-domain2codon-${DOMAIN} 
	
	LFILE="4-domain2codon-${DOMAIN}.log"
	EFILE=${ENSEMBFILE_PATH}
	ln -s ${EFILE}
	NFILE="${DOMAIN}_mostCommonMotifLen.txt"
	ln -s ../1-fasta2prot-${DOMAIN}/${NFILE}
	CLEN=$(cat ${NFILE})
  IFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.seq.${CLEN}aa.txt"
  ln -s ../3-domaininfo2seq-${DOMAIN}/${IFILE}
  OFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.seq.${CLEN}aa.codon.bed"
	
	## start log printing
	echo "############################" > ${LFILE}
  echo "## 4-domain2codon ##########" >> ${LFILE}
  echo "############################" >> ${LFILE}
  
  date >> ${LFILE}
  
	## converting to codons
	motifVar_Domain2ResidueBed -e ${EFILE} ${IFILE} > ${OFILE}

	date >> ${LFILE}
	echo "[MANUAL WORK] This module prepares the domains, by converting them into codons. The next file needs to be prepared manually: the SNV BED file from a catalog, e.g. ExAC. Since the last info column of this BED file can vary depending on the catalog source and since there isn't header in a BED file, the SNV BED file needs to be prepared separately and manually. Put this file in this 4-~ folder. e.g. ExAC.r0.3.sites.vep.snps.pass.bed - you do not need to remove singletons" >> ${LFILE}
	
	cd ..
fi


##############################################################
### 5 codonIntersectSnv
##############################################################
if [[ ${FLAG} =~ 5 ]] ; then

	## set up
	mkdir 5-codonIntersectSnv-${DOMAIN}
	cd 5-codonIntersectSnv-${DOMAIN} 
	
	LFILE="5-codonIntersectSnv-${DOMAIN}.log"
	NFILE="${DOMAIN}_mostCommonMotifLen.txt"
	ln -s ../1-fasta2prot-${DOMAIN}/${NFILE}
	CLEN=$(cat ${NFILE})
  IFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.seq.${CLEN}aa.codon.bed"
  ln -s ../4-domain2codon-${DOMAIN}/${IFILE}
  ln -s ../4-domain2codon-${DOMAIN}/${SNV_BED}
  OFILE="motifVar_${SNV_NAME}.ens${ENS_VER}.codon.${DOMAIN}.auto.noS.bed"
	
	## start log printing
	echo "############################" > ${LFILE}
  echo "## 5-codonIntersectSnv ##########" >> ${LFILE}
  echo "############################" >> ${LFILE}
  
  date >> ${LFILE}
  
	## intersect codon with SNVs
	## remove chrX chrY chrM
	col=${AC_COL}
	intersectBed -a ${SNV_BED} -b ${IFILE} -wa -wb | awk '{OFS="\t"}{FS="\t"}{if($1 != "chrX" && $1 != "chrY" && $1 != "chrM"){print $0}}' | awk '{OFS="\t"}{FS="\t"}{if($col > 1){print $0}}' col=$col > ${OFILE}
	
	## count how many SNVs
	wc -l ${OFILE} >> ${LFILE}
	
	## count how many unique SNVs
	echo "Number of unique SNVs = " $(cut -f1-3 ${OFILE} | sortyChr.sh - | uniq | wc -l) >> ${LFILE}

	echo "NOTE: ${OFILE} can be redundant because an SNV can affect codons from different proteins from the same gene." >> ${LFILE}
	date >> ${LFILE}
	
fi


##############################################################
### 6 vep
##############################################################
if [[ $1 == "vep" ]] ; then
	## setting up
	## make directories, go in directory, set up links
	mkdir 6-vep
	cd 6-vep
	
	ENSEMBLFILE=$2
	DOMAINENSFILE=$3
	DOMAINFILE=$4
	ENS_VER=$5
	
	ln -s ${ENSEMBLFILE}
	ln -s ${DOMAINENSFILE}
	ln -s ${DOMAINFILE}

	## set up
	mkdir 5-codonIntersectSnv-${DOMAIN}
	cd 5-codonIntersectSnv-${DOMAIN} 
	
	LFILE="5-codonIntersectSnv-${DOMAIN}.log"
	NFILE="${DOMAIN}_mostCommonMotifLen.txt"
	ln -s ../1-fasta2prot-${DOMAIN}/${NFILE}
	CLEN=$(cat ${NFILE})
  IFILE="motifVar_protPos2gPos.ens${ENS_VER}.${DOMAIN}.seq.${CLEN}aa.codon.bed"
  ln -s ../4-domain2codon-${DOMAIN}/${IFILE}
  ln -s ../4-domain2codon-${DOMAIN}/${SNV_BED}
  OFILE="motifVar_${SNV_NAME}.ens${ENS_VER}.codon.${DOMAIN}.auto.noS.bed"
	
	## start log printing
	echo "############################" > ${LFILE}
  echo "## 5-codonIntersectSnv ##########" >> ${LFILE}
  echo "############################" >> ${LFILE}
  
  echo "Parameters:" >> ${LFILE}
	echo "ENSEMBL FILE         =${ENSEMBLFILE}" >> ${LFILE}
	echo "DOMAIN ENSEMBL FILE  =${DOMAINENSFILE}" >> ${LFILE}
	echo "DOMAIN FILE          =${DOMAINFILE}" >> ${LFILE}
	echo "ENSEMBL DB VERSION   =${ENS_VER}" >> ${LFILE}
	
  date >> ${LFILE}
  
  echo "\n\n" >> ${LFILE}
  
	## intersect codon with SNVs
	## remove chrX chrY chrM
	col=${AC_COL}
	intersectBed -a ${SNV_BED} -b ${IFILE} -wa -wb | awk '{OFS="\t"}{FS="\t"}{if($1 != "chrX" && $1 != "chrY" && $1 != "chrM"){print $0}}' | awk '{OFS="\t"}{FS="\t"}{if($col > 1){print $0}}' col=$col > ${OFILE}

	echo "NOTE: ${OFILE} can be redundant because an SNV can affect codons from different proteins from the same gene." >> ${LFILE}
	date >> ${LFILE}
	
fi