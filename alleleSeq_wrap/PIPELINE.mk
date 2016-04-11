
BASE=/home/fas/gerstein/jc2296/jmtools/alleleSeq_wrap
PL:=/home/fas/gerstein/jc2296/software/AlleleSeq_pipeline_v1.1
SNPS:=$(BASE)/snp.calls
CNVS:=
BNDS:=hits.bed
MAPS:=$(BASE)/%s_.map
FDR_SIMS:=6
FDR_CUTOFF:=0.1

sourcefiles := $(wildcard *.fastq.gz)
countfiles := $(subst .fastq.gz,.cnt,$(sourcefiles))

%.cnt:%.fastq.gz
	bash -c "python $(PL)/MergeBowtie.py \
           <($(PL)/filter_input.sh $(PL) $< | bowtie --best --strata -v 2 -m 1 -f $(BASE)/personal_genome/AltRefFather/AltRefFather - ) \
           <($(PL)/filter_input.sh $(PL) $< | bowtie --best --strata -v 2 -m 1 -f $(BASE)/personal_genome/AltRefMother/AltRefMother - ) \
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
