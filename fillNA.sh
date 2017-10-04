## USAGE
## Setting FS and OFS to tab ensures the output is correctly delimited. The for-loop looks at every field and set it to zero if they're empty. The one at the end is a shorthand for { print $0 }.

awk 'BEGIN { FS = OFS = "\t" } { for(i=1; i<=NF; i++) if($i ~ /^ *$/) $i = "NA" }; 1' $1
