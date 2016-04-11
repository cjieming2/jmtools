let i=0 a=5
let j=0

while [ $i -le $a ]
do
  while [ $j -le $a ]
  do
	create-script-erwin.sh `printf "%03i" $i` `printf "%03i" $j`
	chmod +x script-`printf "%03i" $i`-`printf "%03i" $j`.sh
	qsub script-`printf "%03i" $i`-`printf "%03i" $j`.sh
	
	let j=$j+1
  done
  let i=$i+1
  let j=$i
done
