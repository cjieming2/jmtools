## USAGE: alleledb_enrichment_cleanup.sh <name of files>

mkdir scripts_logs
mv *.err *.log *.sh scripts_logs/; 

mkdir trash
cat split-*.r > $1.r; mv split-*.r trash/
cat split-*.Rout > $1.Rout ; mv split-*.Rout trash
cat split-*.fishersresultsCounts | egrep "accHets|intHets" -v  > $1.fishersresultsCounts; mv split-*.fishersresultsCounts trash/

cat split-*.fishersresults > $1.fishersresults; mv split-*.fishersresults trash/
mv split-*.Rfisherslist trash/

