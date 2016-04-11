## alleleRnaCounts2bed.sh counts/interestingHets 6 NA12878

## convert counts.txt to counts.bed; intHets same
awk '{OFS="\t"}{FS="\t"}{print "chr"$1,$2-1,$2,$0}' $1.txt | cut -f1-3,6- | sed 1d > $1.bed

## min read counts
num=$(echo $2); awk '{OFS="\t"}{FS="\t"}{if(($11+$12+$13+$14) >= n){print $0}}' n=$num $1.bed > $1.min$2.bed

echo $3 $(wc -l $1.txt) $(wc -l $1.bed) $(wc -l $1.min$2.bed)
