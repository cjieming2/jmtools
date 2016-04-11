## alleleCombineCounts.sh counts/interestingHets /scratch/fas/gerstein/jc2296/alleleseq_runs/12878/yongkong_datadump_louise_NA12878_hiseq/chipseq-AS/
## collect data from all the bed files from alleleCountsPeakIntersect.sh

## remove all bed first
rm *.bed

## create links in compare folders
g=$2;
for i in *
do
#ln -s "$i"/$1.peaks.bed "$i"_$1.peaks.bed
awk '{OFS="\t"}{FS="\t"}{if(($11+$12+$13+$14) >= minread){print $0}}' minread=$g "$i"/$1.peaks.bed > "$i"_$1.peaks.me$2.bed
done

## format files to your format
for j in *_$1.peaks.me$2.bed
do
g=$(echo $j); awk '{OFS="\t"}{FS="\t"}{print $1,$2,$3,$4","$9","$10","$11","$12","$13","$14","$11+$12+$13+$14","$17","gene}' gene=$g $j >> combined.$1.me$2.bed
done

## sort and mergedStrict
## requires mergeBed_strict and tool sortBed
sortBed -i combined.$1.me$2.bed | mergeBed_strict - > combined.$1.sorted.mergedStrict.me$2.bed

rm *.peaks.me$2.bed
