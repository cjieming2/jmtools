## alleleCountsPeakIntersect.sh counts/intHets 6

## convert counts.txt to counts.bed; intHets same
awk '{OFS="\t"}{FS="\t"}{print $1,$2-1,$2,$0}' $1.txt | cut -f1-3,6- | sed 1d | awk '{OFS="\t"}{FS="\t"}{print "chr"$0}' > $1.bed

## min read counts
num=$(echo $2); awk '{OFS="\t"}{FS="\t"}{if(($11+$12+$13+$14) >= n){print $0}}' n=$num $1.bed > $1.min$2.bed

## make sure that peaks folder are in the folder already
## make sure intersectBed tool is in place
## make sure custom script sortByNum.sh is in place
## Some SNPs will be found in multiple entries because they are found in multiple overlapping peaks!! so uniq
zcat peaks/*.gz | intersectBed -a $1.bed -b - -wa | sortByChr.sh - | uniq > $1.peaks.bed
zcat peaks/*.gz | intersectBed -a $1.min$2.bed -b - -wa | sortByChr.sh - | uniq > $1.peaks.min$2.bed

## for nonpeaks
zcat peaks/*.gz | intersectBed -a $1.bed -b - -wa -v | sortByChr.sh - | uniq > $1.nonpeaks.bed
zcat peaks/*.gz | intersectBed -a $1.min$2.bed -b - -wa -v | sortByChr.sh - | uniq > $1.nonpeaks.min$2.bed

## check
wc -l $1*
echo peaks/*.gz
zcat peaks/*.gz | wc -l 
