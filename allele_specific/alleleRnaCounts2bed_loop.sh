## alleleRnaCounts2bed_loop.sh counts/interestingHets 6 NA12878
## requires alleleCountsPeakIntersect.sh
## this only shows the sample need to loop which folders 
for i in $(find * -maxdepth 0 -type d)
do
echo $i
cd $i
alleleRnaCounts2bed.sh $1 $2 $3
cd ..
done > RnaCounts_$1.$2.$3.log
