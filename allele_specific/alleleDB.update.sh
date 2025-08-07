NOW=$(date +"%m%d%y%H%M")
target=/gpfs/scratch/fas/gerstein/jc2296/alleledb/alleleDB
source=/gpfs/scratch/fas/gerstein/jc2296/alleledb/alleleseq-runs-mirror

## RNA-seq
echo "## " $(date) "RNA-seq" > $target/logs/alleleDB.update.$NOW.log
for i in NA06984 NA06986 NA06989 NA06994 NA07000 NA07037 NA07048 NA07051 NA07056 NA07347 NA07357 NA10847 NA10851 NA11829 NA11830 NA11831 NA11843 NA11892 NA11893 NA11894 NA11920 NA11930 NA11931 NA11992 NA11993 NA11994 NA11995 NA12004 NA12006 NA12043 NA12044 NA12045 NA12058 NA12144 NA12154 NA12155 NA12249 NA12272 NA12273 NA12275 NA12282 NA12283 NA12286 NA12287 NA12340 NA12341 NA12342 NA12347 NA12348 NA12383 NA12399 NA12400 NA12413 NA12489 NA12546 NA12716 NA12717 NA12718 NA12749 NA12750 NA12751 NA12761 NA12763 NA12775 NA12777 NA12778 NA12827 NA12829 NA12830 NA12842 NA12843 NA12878 NA12889 NA12890 NA12891 NA12892 NA18486 NA18487 NA18489 NA18498 NA18499 NA18501 NA18502 NA18504 NA18505 NA18507 NA18508 NA18510 NA18511 NA18516 NA18517 NA18519 NA18520 NA18522 NA18523 NA18526 NA18853 NA18856 NA18858 NA18861 NA18867 NA18868 NA18870 NA18871 NA18873 NA18907 NA18908 NA18909 NA18910 NA18912 NA18916 NA18917 NA18923 NA18933 NA18934 NA18951 NA19093 NA19098 NA19099 NA19102 NA19107 NA19108 NA19114 NA19116 NA19119 NA19129 NA19130 NA19131 NA19137 NA19138 NA19147 NA19152 NA19160 NA19171 NA19172 NA19189 NA19190 NA19197 NA19198 NA19200 NA19204 NA19207 NA19209 NA19213 NA19223 NA19225 NA19235 NA19236 NA19247 NA19248 NA19256 NA19257 NA20502 NA20503 NA20504 NA20505 NA20506 NA20507 NA20508 NA20509 NA20510 NA20512 NA20513 NA20515 NA20516 NA20517 NA20518 NA20519 NA20520 NA20521 NA20524 NA20525 NA20527 NA20528 NA20529 NA20530 NA20531 NA20532 NA20534 NA20535 NA20536 NA20537 NA20538 NA20539 NA20540 NA20541 NA20542 NA20543 NA20544 NA20581 NA20582 NA20585 NA20586 NA20588 NA20589 NA20752 NA20754 NA20756 NA20757 NA20758 NA20759 NA20760 NA20761 NA20765 NA20766 NA20768 NA20769 NA20770 NA20771 NA20772 NA20773 NA20774 NA20778 NA20783 NA20785 NA20786 NA20787 NA20790 NA20792 NA20795 NA20796 NA20797 NA20798 NA20799 NA20800 NA20801 NA20802 NA20803 NA20804 NA20805 NA20806 NA20807 NA20808 NA20809 NA20810 NA20811 NA20812 NA20813 NA20814 NA20815 NA20816 NA20819 NA20826 NA20828 HG00096 HG00100 HG00103 HG00106 HG00108 HG00111 HG00112 HG00114 HG00116 HG00117 HG00118 HG00119 HG00120 HG00122 HG00123 HG00124 HG00125 HG00126 HG00127 HG00131 HG00133 HG00136 HG00137 HG00138 HG00139 HG00141 HG00142 HG00143 HG00146 HG00148 HG00149 HG00150 HG00151 HG00152 HG00154 HG00155 HG00156 HG00158 HG00159 HG00160 HG00171 HG00173 HG00174 HG00176 HG00177 HG00178 HG00179 HG00180 HG00182 HG00183 HG00185 HG00186 HG00187 HG00188 HG00189 HG00231 HG00232 HG00233 HG00236 HG00239 HG00242 HG00243 HG00244 HG00245 HG00246 HG00247 HG00249 HG00250 HG00251 HG00252 HG00253 HG00256 HG00257 HG00258 HG00259 HG00260 HG00261 HG00262 HG00263 HG00264 HG00265 HG00266 HG00267 HG00268 HG00269 HG00271 HG00272 HG00273 HG00274 HG00275 HG00276 HG00277 HG00278 HG00280 HG00281 HG00282 HG00284 HG00285 HG00306 HG00309 HG00310 HG00311 HG00312 HG00313 HG00315 HG00319 HG00320 HG00321 HG00323 HG00324 HG00325 HG00326 HG00327 HG00328 HG00329 HG00330 HG00331 HG00334 HG00335 HG00336 HG00337 HG00338 HG00339 HG00342 HG00343 HG00344 HG00345 HG00346 HG00353 HG00361 HG00366 HG00367 HG00369 HG00372 HG00373 HG00375 HG00377 HG01334
do 
	cd $target/"$i"/rnaseq

	## clean up first 
	rm counts.acc.bed interestingHets.betabinom.min6.bed

	## copy accessible and interestingHets files from source directories (rnaseq)
	cp $source/"$i"/rnaseq/counts.acc.bed .
	cp $source/"$i"/rnaseq/interestingHets.betabinom.min6.auto.bed .
	echo $i $(wc -l counts.acc.bed interestingHets.betabinom.min6.auto.bed) >> $target/logs/alleleDB.update.$NOW.log 

	cd ../../
done


## ChIP-seq
echo "## " $(date) "ChIP-seq" >> $target/logs/alleleDB.update.$NOW.log
for i in NA12878 NA12891 NA12892 NA10847 NA11830 NA11831 NA11894 NA12043 NA12890 NA18486 NA18505 NA18526 NA18951 NA19099
do 
	cd $target/"$i"/chipseq

	rm -r *
	
	## create names for the loop to create the directories later 
	for j in $source/"$i"/chipseq/*_"$i"
	do
		ln -s $j
	done

	## remove links from above and create directories based on links
	for k in *_"$i"
	do 
		rm $k
		mkdir $k
		cd $k
		cp $source/"$i"/chipseq/"$k"/counts.acc.bed .
		cp $source/"$i"/chipseq/"$k"/interestingHets.betabinom.min6.auto.peaks.bed .
		echo $k $(wc -l counts.acc.bed interestingHets.betabinom.min6.auto.peaks.bed) >> $target/logs/alleleDB.update.$NOW.log
		cd ..
	done 

	cd ../../
done

## collect all RNA-seq data: intHets and accHets
mkdir trash; mv zrnaseq.samples.interestingHets.betabinom.min6.auto.bed zrnaseq.samples.counts.acc.minN.auto.bed zchipseq.samples.interestingHets.betabinom.min6.auto.peaks.bed zchipseq.samples.counts.acc.minN.auto.peaks.bed trash

for i in NA* HG0*; do indiv=$(echo $i) ; awk '{OFS="\t"}{FS="\t"}{print $1,$2,$3,indiv}' indiv=$indiv "$i"/rnaseq/interestingHets.betabinom.min6.auto.bed | awk '{OFS="\t"}{FS"\t"}{if($1 != "chrX" && $1 != "chrY"){print $0}}' | sortByChr.sh - | uniq >> zrnaseq.samples.interestingHets.betabinom.min6.auto.bed; done

for i in NA* HG0*; do indiv=$(echo $i) ; awk '{OFS="\t"}{FS="\t"}{print $1,$2,$3,indiv}' indiv=$indiv "$i"/rnaseq/counts.acc.bed | awk '{OFS="\t"}{FS"\t"}{if($1 != "chrX" && $1 != "chrY"){print $0}}' | sortByChr.sh - | uniq >> zrnaseq.samples.counts.acc.minN.auto.bed; done

## collect all ChIP-seq data: intHets and accHets
for i in NA12878 NA12891 NA12892 NA10847 NA11830 NA11831 NA11894 NA12043 NA12890 NA18486 NA18505 NA18526 NA18951 NA19099; do cd "$i"/chipseq; for j in *_"$i"; do indiv=$(echo $j) ; awk '{OFS="\t"}{FS="\t"}{print $1,$2,$3,indiv}' indiv=$indiv "$j"/interestingHets.betabinom.min6.auto.peaks.bed | awk '{OFS="\t"}{FS"\t"}{if($1 != "chrX" && $1 != "chrY"){print $0}}' | sortByChr.sh - | uniq >> ../../zchipseq.samples.interestingHets.betabinom.min6.auto.peaks.bed; done; cd ../..; done

for i in NA12878 NA12891 NA12892 NA10847 NA11830 NA11831 NA11894 NA12043 NA12890 NA18486 NA18505 NA18526 NA18951 NA19099; do cd "$i"/chipseq; for j in *_"$i"; do indiv=$(echo $j) ; awk '{OFS="\t"}{FS="\t"}{print $1,$2,$3,indiv}' indiv=$indiv "$j"/counts.acc.bed | awk '{OFS="\t"}{FS"\t"}{if($1 != "chrX" && $1 != "chrY"){print $0}}' | sortByChr.sh - | uniq >> ../../zchipseq.samples.counts.acc.minN.auto.peaks.bed; done; cd ../..; done
