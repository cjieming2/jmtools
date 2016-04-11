### USAGE   rnaseq.test.sh <file.uniq.sam> <file.sam>

## calculate number of lines with NH:i:1 (uniquely mapped reads) and make sure that there are pairs (2)
echo "calculate number of lines with NH:i:1 (uniquely mapped reads) and make sure that most of them are pairs (2) ="
##grep -v "^@" $1 | grep -w "NH\:i\:1" | distinct -kc1 | distinct -kc2 seems to take up lotsa time; try the following:
## cuts ID col in SAM | sort | count the number of uniq items | print the counts | count the number of counts in the number of uniq items (I want to see a lot of 2s since paired)
cut -f1 $1 | sort | uniq -c | awk '{print $1}' | uniq -c

echo "top 10 most frequent IDs uniq IDs = "
##grep -v "^@" $1 | grep -w "NH\:i\:1" | distinct -kc1 | sort -nrk2 | head -10
cut -f1 $1 | sort | uniq -c | sort -nrk1 | head -10

## calculate number of lines with NH:i:1 (uniquely mapped reads) and count the number of unique IDs
echo "number of unique IDs with NH:i:1 = "
##grep -v "^@" $1 | grep -w "NH\:i\:1" | cut -f1 | sort | uniq | wc -l
cut -f1 $1 | sort | uniq | wc -l

## calculate number of lines without NH:i:1 (multimappers)
echo "number of unique IDs with non-NH:i:1 = "
grep -v "^@" $2 | grep -v -w "NH\:i\:1" | cut -f1 | sort | uniq | wc -l
