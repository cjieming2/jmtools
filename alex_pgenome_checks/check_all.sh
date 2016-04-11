#!/bin/csh -f

set id = "NA12878"
if ($#argv > 0) then
    set id = $argv[1]
endif

set dir = "/scratch/fas/gerstein/jc2296/reference_genomes/fasta/b37_g1k_phase2"

set script1 = `echo $0 | sed s/check_all.sh/calc_stat.pl/`
set script2 = `echo $0 | sed s/check_all.sh/check_chain.pl/`
set script3 = `echo $0 | sed s/check_all.sh/check_chrom_chain.pl/`
set script4 = `echo $0 | sed s/check_all.sh/check_map_file.pl/`
set script5 = `echo $0 | sed s/check_all.sh/check_chromosomes.pl/`

$script1 *.out
$script2 *.chain
$script3 *.chain *.fa
$script4 chr*_$id.map
$script5 $dir"/chr1.fa"  "chr1_"$id"_paternal.fa"  "chr1_"$id"_maternal.fa"  "chr1_"$id".map"
$script5 $dir"/chr2.fa"  "chr2_"$id"_paternal.fa"  "chr2_"$id"_maternal.fa"  "chr2_"$id".map"
$script5 $dir"/chr3.fa"  "chr3_"$id"_paternal.fa"  "chr3_"$id"_maternal.fa"  "chr3_"$id".map"
$script5 $dir"/chr4.fa"  "chr4_"$id"_paternal.fa"  "chr4_"$id"_maternal.fa"  "chr4_"$id".map"
$script5 $dir"/chr5.fa"  "chr5_"$id"_paternal.fa"  "chr5_"$id"_maternal.fa"  "chr5_"$id".map"
$script5 $dir"/chr6.fa"  "chr6_"$id"_paternal.fa"  "chr6_"$id"_maternal.fa"  "chr6_"$id".map"
$script5 $dir"/chr7.fa"  "chr7_"$id"_paternal.fa"  "chr7_"$id"_maternal.fa"  "chr7_"$id".map"
$script5 $dir"/chr8.fa"  "chr8_"$id"_paternal.fa"  "chr8_"$id"_maternal.fa"  "chr8_"$id".map"
$script5 $dir"/chr9.fa"  "chr9_"$id"_paternal.fa"  "chr9_"$id"_maternal.fa"  "chr9_"$id".map"
$script5 $dir"/chr10.fa" "chr10_"$id"_paternal.fa" "chr10_"$id"_maternal.fa" "chr10_"$id".map"
$script5 $dir"/chr11.fa" "chr11_"$id"_paternal.fa" "chr11_"$id"_maternal.fa" "chr11_"$id".map"
$script5 $dir"/chr12.fa" "chr12_"$id"_paternal.fa" "chr12_"$id"_maternal.fa" "chr12_"$id".map"
$script5 $dir"/chr13.fa" "chr13_"$id"_paternal.fa" "chr13_"$id"_maternal.fa" "chr13_"$id".map"
$script5 $dir"/chr14.fa" "chr14_"$id"_paternal.fa" "chr14_"$id"_maternal.fa" "chr14_"$id".map"
$script5 $dir"/chr15.fa" "chr15_"$id"_paternal.fa" "chr15_"$id"_maternal.fa" "chr15_"$id".map"
$script5 $dir"/chr16.fa" "chr16_"$id"_paternal.fa" "chr16_"$id"_maternal.fa" "chr16_"$id".map"
$script5 $dir"/chr17.fa" "chr17_"$id"_paternal.fa" "chr17_"$id"_maternal.fa" "chr17_"$id".map"
$script5 $dir"/chr18.fa" "chr18_"$id"_paternal.fa" "chr18_"$id"_maternal.fa" "chr18_"$id".map"
$script5 $dir"/chr19.fa" "chr19_"$id"_paternal.fa" "chr19_"$id"_maternal.fa" "chr19_"$id".map"
$script5 $dir"/chr20.fa" "chr20_"$id"_paternal.fa" "chr20_"$id"_maternal.fa" "chr20_"$id".map"
$script5 $dir"/chr21.fa" "chr21_"$id"_paternal.fa" "chr21_"$id"_maternal.fa" "chr21_"$id".map"
$script5 $dir"/chr22.fa" "chr22_"$id"_paternal.fa" "chr22_"$id"_maternal.fa" "chr22_"$id".map"
$script5 $dir"/chrX.fa"  "chrX_"$id"_paternal.fa"  "chrX_"$id"_maternal.fa"  "chrX_"$id".map"
$script5 $dir"/chrY.fa"  "chrY_"$id"_paternal.fa"  "chrY_"$id"_maternal.fa"  "chrY_"$id".map"
