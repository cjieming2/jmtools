USAGE := "make -f motifVarGetDomains DOMAIN_FILE=smartDomain2gPos.ens73.alldomainfeatures.34domains (without extension) DOMAIN=TPR FASTA=tpr.fa SNP_OUTPUT_PREFIX=1KG.snps.nonmono"

## note that this makefile requires jmtools/motifVar* dependencies


## 
## Variables
##
DOMAIN_FILE := NULL
DOMAIN := NULL
DOMAIN_U := upper($(DOMAIN))
DOMAIN_L := lower($(DOMAIN))
FASTA := NULL
SNP_FILE := 1KG.vat_run_output_msp.vat.pass.nonmono.bed
SNP_OUTPUT_PREFIX := NULL
ENS_FILE := ensembl2coding_ensembl73.proteinIDs.genomicPos.chrs.strand.txt

## 1. getting domain master file for this particular domain

$(DOMAIN_FILE).$(DOMAIN_U).txt: $(DOMAIN_FILE).txt
	mkdir sequences stats
	g=$(echo $(DOMAIN_U)); awk '{OFS="\t"}{FS="\t"}{if($$11 == "DOMAIN" || $$11 == domain){print $0}}' domain=$g $(DOMAIN_FILE).txt > $(DOMAIN_FILE).$(DOMAIN_U).txt

## 2. get FASTA sequences from Ensembl


## 3. get sequences for domains from FASTA
$(DOMAIN_FILE).$(DOMAIN_U).seqgrab.txt: $(DOMAIN_FILE).$(DOMAIN_U).txt
	motifVarFastaGrab -f $(FASTA) $(DOMAIN_FILE).$(DOMAIN_U).txt > $(DOMAIN_FILE).$(DOMAIN_U).seqgrab.txt


## 4. get motif stats
$(DOMAIN_L).motifnum.txt: $(DOMAIN_U)_$(DOMAIN_FILE)
	distinct -kc10 $(DOMAIN_FILE).$(DOMAIN_U).seqgrab.txt | awk 'NR==1;NR>1{print $$0 | "sort -n" }' | egrep -v "motifSize" > stats/$(DOMAIN_L).motifsize.txt
	cut -f1,5 $(DOMAIN_FILE).$(DOMAIN_U).seqgrab.txt | uniq | distinct -kc1 > chrprot.txt
	cut -f1,6 $(DOMAIN_FILE).$(DOMAIN_U).seqgrab.txt | uniq | distinct -kc1 > chrprot1.txt
	paste chrprot.txt chrprot1.txt | sed 1,2d | cut -f1,2,4 | sortByChr.sh - | sed 's/chr//g' | sed 1i\chr"\t"protein"\t"gene > stats/$(DOMAIN_L).chr.byprot.txt
	distinct -kc5 $(DOMAIN_FILE).$(DOMAIN_U).seqgrab.txt | distinct -kc2 > stats/$(DOMAIN_L).motifnum.txt


## 5. extract highest motifSize and do weblogo and motif stats

## 6. SNP mapping (you need (5))

	motifVarDomain2ResidueBed -e $(ENS_FILE) smartDomain2gPos.ens73.alldomainfeatures.34domains.TPR.seqgrab.34aa.txt > smartDomain2gPos.ens73.alldomainfeatures.34domains.TPR.seqgrab.34aa.codon.bed

## 7. intersect SNPs with this file
	intersectBed -a $(SNP_FILE) -b smartDomain2gPos.ens73.alldomainfeatures.34domains.TPR.seqgrab.34aa.codon.bed -wa -wb | awk '{OFS="\t"}{FS="\t"}{if($$35 ~ "nonsynonymous"){print $$0"\tNS"}else{print $$0"\tS"}}' | sed 's/#/\t/g'  > $(SNP_OUTPUT_PREFIX).smartDomain2gPos.TPR.34aa.bed

## cleanup
clean:
	rm chrprot*.txt
