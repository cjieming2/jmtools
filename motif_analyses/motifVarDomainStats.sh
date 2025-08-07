## USAGE motifVarDomainStats file_to_get_data_from.txt domain_prefix_output
## e.g. motifVarDomainStats smartDomain2gPos.ens73.alldomainfeatures.34domains.BROMO.seqgrab.txt bromo

mkdir stats
distinct -kc10 $1 | awk 'NR==1;NR>1{print $0 | "sort -n" }' | egrep -v "motifSize" > stats/$2.motifsize.txt

cut -f1,5 $1 | uniq | distinct -kc1 > chrprot.txt
cut -f1,6 $1 | uniq | distinct -kc1 > chrprot1.txt
paste chrprot.txt chrprot1.txt | sed 1,2d | cut -f1,2,4 | sortByChr.sh - | sed 's/chr//g' | sed 1i\chr"\t"protein"\t"gene > stats/$2.chr.byprot.txt

distinct -kc5 $1 | distinct -kc2 > stats/$2.motifnum.txt

rm chrprot*.txt
