## alleleCountsPeakIntersect.sh counts/intHets

## convert counts.txt to counts.bed; intHets same
awk '{OFS="\t"}{FS="\t"}{print $1,$2-1,$2,$0}' $1.txt | cut -f1-3,6- | sed 1d > $1.bed

## make sure that peaks folder are in the folder already
## make sure intersectBed tool is in place
## make sure custom script sortByNum.sh is in place
## Some SNPs will be found in multiple entries because they are found in multiple overlapping peaks!! so uniq
zcat peaks/*.gz | intersectBed -a $1.bed -b - -wa | sortByNum.sh - | uniq > $1.peaks.bed

## for nonpeaks
zcat peaks/*.gz | intersectBed -a $1.bed -b - -wa -v | sortByNum.sh - | uniq > $1.nonpeaks.bed

## check
wc -l $1*
echo peaks/*.gz
zcat peaks/*.gz | wc -l 
