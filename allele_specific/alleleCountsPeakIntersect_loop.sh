## alleleCountsPeakIntersect_loop.sh counts/interestingHets
## requires alleleCountsPeakIntersect.sh
## this only shows the sample need to loop which folders 
for i in $(find * -maxdepth 0 -type d) 
do
echo $i
cd $i
alleleCountsPeakIntersect.sh $1
cd ..
done > filterByPeaks_$1.log

filter2tsv4allele filterByPeaks_$1.log
