
BASE:=/home/rdb9/working/Joel/012312/testing_sandbox
PL:=$(BASE)/Pipeline
SNPS:=$(BASE)/GM12878/snp.calls
CNVS:=$(BASE)/GM12878/CEU.SRP000032.2010_03.genotypes.vcf.cnv 
BNDS:=hits.bed
MAPS:=$(BASE)/GM12878/NA12878_diploid_genome_May3_2011/%s_NA12878.map
FDR_SIMS:=5
FDR_CUTOFF:=0.1

sourcefiles := $(wildcard *.fastq.gz)
countfiles := $(subst .fastq.gz,.cnt,$(sourcefiles))


# aligner command to produce SAM output
ALIGN2SAM_PAT="bowtie --best --strata -v 2 -m 1 -f AltRefFather/AltRefFather -"
ALIGN2SAM_MAT="bowtie --best --strata -v 2 -m 1 -f AltRefFather/AltRefFather -"


%.cnt:%.fastq.gz
	bash -c "python $(PL)/MergeBowtie.py \
           <($(PL)/filter_input.sh $(PL) $< | $(ALIGN2SAM_PAT) ) \
           <($(PL)/filter_input.sh $(PL) $< | $(ALIGN2SAM_MAT) ) \
           $(MAPS) | python $(PL)/SnpCounts.py $(SNPS) - $(MAPS) $@"

all: interestingHets.txt

check:
	@echo $(sourcefiles)

counts.txt: $(countfiles)
	python $(PL)/CombineSnpCounts.py 5 $(SNPS) $(BNDS) $(CNVS) counts.txt counts.log $(countfiles)

# calculate false discovery rates
FDR.txt: counts.txt
	python $(PL)/FalsePos.py counts.txt $(FDR_SIMS) $(FDR_CUTOFF) > FDR.txt

interestingHets.txt: counts.txt FDR.txt
	awk -f $(PL)/finalFilter.awk thresh=$(shell awk 'END {print $$6}' FDR.txt) < counts.txt > interestingHets.txt

clean:
	@rm -f FDR.txt interestingHets.txt counts.txt

cleanall: clean
	@rm -f *.cnt

.DELETE_ON_ERROR:
