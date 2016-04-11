### Usage: strucPBSgen.sh 2 5

let max=$2+1
for ((i=$1;i<$max;i++))
{
	echo "#!/bin/sh" > script-struct$i.sh
	echo "#PBS -N jm-struct$i" >> script-struct$i.sh
	echo "#PBS -l ncpus=1" >> script-struct$i.sh
	echo "#PBS -V" >> script-struct$i.sh
	echo "#PBS -o job$i.log" >> script-struct$i.sh
	echo "#PBS -e job$i.err" >> script-struct$i.sh
	echo "date" >> script-struct$i.sh
	echo cd $(pwd) >> script-struct$i.sh
	echo "structure -K $i -o output$i > struct-out-new.$i" >> script-struct$i.sh
	echo "date" >> script-struct$i.sh
}

echo "#!/bin/sh" > script-wrap$1$2
echo "for ((i=$1;i<$max;i++))" >> script-wrap$1$2
echo "do" >> script-wrap$1$2
echo "	qsub script-struct\$i.sh" >> script-wrap$1$2
echo "done" >> script-wrap$1$2
chmod +x script-wrap$1$2
