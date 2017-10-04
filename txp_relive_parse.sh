#!/bin/bash
### usage: transplant_relive_parse.sh col.info.SDY289.txt Formats.excel.txt relive2dictionary.SDY289.out relive_01_data.txt relive_01_data_relive2dict.new.txt

txp_relive2dictionary.py -c $1 -f $2 > $3
mvColumn.py $4 $3 > $5
