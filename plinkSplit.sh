## we have files numbered i to a, hence total num of a+1 files
let i=0 a=2
let j=0

while [ $i -le $a ]
do
	while [ $j -le $a ]
	do 
		bsub -o out -e err plink --bfile renamed-recoded-286samples-578404snps-axiom-asi-t2d-db128-b36-na30 \
                	--read-freq renamed-recoded-286samples-578404snps-axiom-asi-t2d-db128-b36-na30-freq.frq \
			--all \
                	--genome \
                	--genome-lists tmp.list`printf "%03i\n" $i` \
                     	               tmp.list`printf "%03i\n" $j` \
                	--out data.sub.$i.$j
	
	let j=$j+1
	done
	
	let i=$i+1
	let j=$i
done
