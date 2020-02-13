## USAGE: mail.sh <subject> <attachment> <email address>
## EX: mail -s "imvigor210 sunrise bwa" -a sunrise_rdy_imvigor210_bwa.txt chenj220@gene.com < filename.txt
touch jm_filenamezz.txt
mail -s $1 -a $2 $3 < jm_filenamezz.txt
rm jm_filenamezz.txt
