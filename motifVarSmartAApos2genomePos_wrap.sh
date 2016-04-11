##smartAApos2genomePos_wrap.sh ensemblfile.tsv protDomainMapfromEnsembl.tsv > out.txt
motifVarSmartAApos2genomePos -e $1 $2 | awk 'NR == 1; NR > 1 {if($2>$3){print $1,$3,$2,$4,$5,$6,$7,$8,$9,$10}else{print $0}}' > hearthstone.txt
fselect a.+,b.DOMAIN,b.DEFINITION from hearthstone.txt, $3 where a.smart=b.ACC > wrap.out.test.domains2

##rm hearthstone.txt
