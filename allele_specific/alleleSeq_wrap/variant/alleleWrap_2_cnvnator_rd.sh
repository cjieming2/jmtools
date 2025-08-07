## this wrapper script calculates read depth from cnvnator and ROOT 
## do this in the directory you keep the personal genome; bin size=100
## for multiple genomes, write a shell script to create personal genome folders and copy this script individually into each folder and run them; this can be concurrent with vcf2diploid
## USAGE: alleleWrap_cnvnator_rd <1> <2> <3> <4>
## <1> = individual's ID, e.g. NA12878
## <2> = path for BAM file, note that a softlink does NOT work
## <3> = <sequencer>_<genotypeCaller>_<date> e.g. hiseq_pcrfree_hc_130506
## <4> = path to FASTAs
## e.g. ./alleleWrap_2_cnvnator_rd.sh NA12878 /here/na12878.bam miseq_pcr_free_131313 /here/reference/fasta

## creates cnv_rd folder prep for cnv read depth calculation
mkdir cnv_rd_$1_$3
cp -r ~/jmtools/alleleSeq_cnvScript/ cnv_rd_$1_$3
cd cnv_rd_$1_$3
cnvnator -root $1.$3.tree.root -tree $2

cnvnator -root $1.$3.tree.root -outroot $1.$3.his.root -his 100 -chrom 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y -d $4

cnvnator -root $1.$3.his.root -stat 100
cnvnator -root $1.$3.his.root -eval 100 > binSize100.log

## prepare addRD file
ln -s alleleSeq_cnvScript/addRD
rd=$(grep "Average RD per bin (1-22) is" binSize100.log | sed 's/Average RD per bin (1-22) is //g'  | awk '{printf("%d\n"),$1 + 0.5}')
cd alleleSeq_cnvScript
./print_addRDcpp.sh $1.$3.his.root $rd
make addRD
cd .. ## this gets out from cnvScript folder to cnv_rd folder
mv alleleSeq_cnvScript/create-split-chr-qsub.sh alleleSeq_cnvScript/cnvnator-root.sh .

## run addRD
## split and run (manual)
