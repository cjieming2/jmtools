head -n1 data.sub.0.0.genome > header
cat data.sub*genome | fgrep -v FID1 | cat header - > data.genome
rm tmp.list*
rm data.sub.*
rm header
