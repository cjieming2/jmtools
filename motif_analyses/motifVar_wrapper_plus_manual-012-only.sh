#!/bin/bash

## This script tries to integrate the automated pipeline motifVar.sh and the manual portions of it
## the aim is to include all the manual commands that you have already figured out
## and make the run with only a single domain argument so that this can be looped
## Hence, many of the 'manual' parameters are hardcoded into this wrapper script.
## The logic and comments should be able to guide you through how to adapt this for your own use.
## you can loop it like this:
## for i in TPR 
##   do bsub-make-plus.sh motifvar-wrapper-"$i" "motifVar_wrapper_plus_manual.sh $i"
##   bsub -q gerstein < bsub-script-rdy-motifvar-wrapper-"$i".sh 
## done


if [[ "$#" -ne 1 && "$1" -ne -1 ]] ; then
	echo "==============================="
	echo "== USAGE ======================"
	echo "==============================="
	echo "motifVar_wrapper_plus_manual.sh <smart domain name>" 
	echo "e.g. motifVar_wrapper_plus_manual.sh TPR"

	exit 1
fi

## make directory of domain 
## enter domain
mkdir $1
cd $1

#######################################################
####### protPos2gPos; 5 args + m
## e.g. motifvar.sh protPos2gPos /ens/path/ensembl2coding_ens.noErr.txt /ens/path/allchr.ens73.noErr.tsv /smart/path/smart_domains_1158_all_131025.txt 73
####### the columns to grab are hardcoded into the motifVar.sh 
####### for this module
####### they use the same files, so it seems they can't be run concurrently
####### solution is to run 0,1,2 first in series on a separate script (this script)
####### then run a second script to run the rest in parallel
 
motifVar.sh protPos2gPos /gpfs/scratch/fas/gerstein/jc2296/ensembl/ensembl73/ensembl2coding_ensembl73.proteinIDs.genomicPos.chrs.strand.noErr.txt /gpfs/scratch/fas/gerstein/jc2296/ensembl/ensembl73/allchromosomes.ens73.alldomainfeatures.smart.mod.noErr.tsv /gpfs/scratch/fas/gerstein/jc2296/smart/131025/smart_domains_1158_all_131025.txt 73

## manual protPos2gPos
cd 0-motifVar_protPos2gPos-m

REMOVE_CDS_FILE="/gpfs/scratch/fas/gerstein/jc2296/gencode/gencode.17.cds_start_end_NF.ensembl2coding_ensembl73.proteinIDs.txt"
PROTPOS2GPOS_OFILE="motifVar_protPos2gPos.ens73.smartdomains.txt"
PROTPOS2GPOS_OFILE_OLD="motifVar_protPos2gPos.ens73.smartdomains.unprocessed.txt"

# save original file
mv ${PROTPOS2GPOS_OFILE} ${PROTPOS2GPOS_OFILE_OLD}

# remove incomplete/truncated CDS sequences
fsieve2 -s <(cut -f3 ${REMOVE_CDS_FILE}) -m <(awk '{OFS="\t"}{FS="\t"}{print $8,$0}' ${PROTPOS2GPOS_OFILE_OLD} | sed 's/EnsemblProtID/EnsemblProtID1/1') | cut -f2- > ${PROTPOS2GPOS_OFILE}


# get out of folder
cd ..

#######################################################
####### 1 fasta2prot; 9 args
####### the columns to grab are hardcoded into the motifVar.sh 
####### for this module

SMART_FASTA_PATH="/scratch/fas/gerstein/jc2296/smart/131025/fasta/HUMAN_$1.fa"
motifVar.sh 1 $1 ${SMART_FASTA_PATH} 73 - - - - -

#######################################################
####### 2 domain info (domain2info); 9 args
####### the columns to grab are hardcoded into the motifVar.sh 
####### for this module

motifVar.sh 2 $1 - 73 - - - - -


### get out 
cd ..