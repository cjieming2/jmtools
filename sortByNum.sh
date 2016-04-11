cat $1 | sed 's/^X/23/' | sed 's/^Y/24/' | sed 's/ M/ 25/' | sort -k 1,1n -k 2,2n -k 3,3n | sed 's/^23/X/' | sed 's/^24/Y/' | sed 's/^25/M/'
