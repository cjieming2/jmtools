## takes the addRD split-by-chrom vcf2snp snp.calls from alleleWrap_2a_cnvnator_rd.sh and merge them
## to give the new snp.calls with read depths
## same input as 2a
## USAGE: alleleWrap_cnvnator_rd <1> <2> <3> <4> <5>
## <1> = individual's ID, e.g. NA12878
## <2> = path for BAM file, note that a softlink does NOT work
## <3> = <sequencer>_<genotypeCaller>_<date> e.g. hiseq_pcrfree_hc_130506
## <4> = path to FASTAs
## <5> = binsize e.g. 100 for high coverage (trio), 1000 for low coverage (1KG)
## e.g. ./alleleWrap_2_cnvnator_rd.sh NA12878 /here/na12878.bam miseq_pcr_free_131313 /here/reference/fasta

mkdir scripts_logs
mv *.log myscript-*.sh scripts_logs

mkdir trash
mv fsplitchr*.$1.snp.calls trash
mv $1.snp.calls_ trash

head -1 fsplitchr22.$1.snp.calls.cnv > header

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 X; do sed 1d fsplitchr22.$1.snp.calls.cnv >> rd.$1.$3.snp.calls ; done

cat header rd.$1.$3.snp.calls > rd.$1.$3.snp.calls_
mv rd.$1.$3.snp.calls_ > rd.$1.$3.snp.calls

wc -l rd.$1.$3.snp.calls $1.snp.calls
mv fsplit*.cnv trash

