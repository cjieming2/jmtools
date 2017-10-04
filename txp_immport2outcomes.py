#!/usr/bin/env python3

import os, sys, distutils, re
import argparse
from string import Template

parser = argparse.ArgumentParser(description='This script takes a tab-delimited input file, and outputs another tab-delimited file. The output will present outcomes with corresponding time FROM TRANSPLANT and subject ID name based on the user-specified columns. This script assumes that the first column is the unique ID column and uses it to annotate by individual patients. Outputs 3 files, named by the input file, and prefixed with txp_immport2outcomes and the last one suffixed with .log',
                                 usage='txp_immport2outcomes.py -c 1,2,0 -i <tsv-file>',
                                 epilog='EXAMPLE: txp_immport2outcomes.py -c 1,2 -i file.txt')
parser.add_argument('-i', help='input file or STDIN -; header required; "-" means STDIN')
parser.add_argument('-c', help='comma-separated triplets of numbers, with the 1st number being the outcome/condition we want our network to have as a node, binary; 2nd number being the min/start date e.g. in days; 3rd number being the max/end date; -1 means to skip that category. E.g. -c 3,2,-1 would mean take column 3 for a certain outcome/condition we want Cytoscape to have as a node, typically, yes or no, 1 or 0, and column 2 is the start date, with no end date in this case. Note that the columns do not have to be in order, but they do have conform to the triplet definition, and the first number CANNOT be -1.')


## help if no arguments or -h/--help
if len(sys.argv) == 1:
	parser.print_help()
	sys.exit(1)

args = parser.parse_args()

##### functions #####
###################################
## this function parses the header
def processHeader(cols, fields):
	
	col2outcomes = {}
	
	for i in range(0, len(cols), 3):
				if(cols[i] == -1):
					sys.exit("First number of the triplet of comma-sep columns CANNOT be -1!")
				else:
					try:
						col2outcomes[ cols[i] ] = fields[ int(cols[i])-1 ]
						col2outcomes[ cols[i+1] ] = fields[ int(cols[i+1])-1 ]
						col2outcomes[ cols[i+2] ] = fields[ int(cols[i+2])-1 ]
						
						logfile.write("cols" + cols[i]+","+cols[i+1]+","+cols[i+2] + ": " + fields[ int(cols[i])-1 ]+","+fields[ int(cols[i+1])-1 ]+","+fields[ int(cols[i+2])-1 ] + "\n")
					except IndexError: 
						## catch errors in c2 and c3 are -1s
						if(cols[i+1] == -1):
							logfile.write("cols" + cols[i]+","+cols[i+1]+","+cols[i+2] + ": " + fields[ int(cols[i])-1 ]+",skipped,"+fields[ int(cols[i+2])-1 ] + "\n")
						elif(cols[i+2] == -1):
							logfile.write("cols" + cols[i]+","+cols[i+1]+","+cols[i+2] + ": " + fields[ int(cols[i])-1 ]+","+fields[ int(cols[i+1])-1 ]+",skipped\n")
	
	return col2outcomes;
		
##### main program ######
if __name__ == '__main__':
	## output files
	basename = os.path.splitext(args.i)[0] ## strips only the last '.', or extension
	logfile   = open('txp_immport2outcomes-' + basename + '.log', 'w')
	seqfile   = open('txp_immport2outcomes-' + basename + '.txt', 'w')
	#trajfile  = open('txp_immport2outcomes_traj-' + basename + '.txt', 'w')
	
	## read STDIN when '-' as input
	## else read as a file
	if args.i == '-':
		f1 = sys.stdin
	else:
		f1 = open(args.i, 'r')
	
	## parse columns
	cols = args.c.split(',')
	
	## declare variables
	headerProcessed = 0
	
	# these variables are per subject (row)
	col2outcomes = {}
	
	## process each line in the file
	for line in f1:
		
		## split the row into fields
		fields = line.rstrip().split('\t')
		
		## parse the header
		## print headers to output files
		if(headerProcessed == 0):
			col2outcomes = processHeader(cols, fields) ## process header
			seqfile.write('subject_ID\tevent\tevent_min\tevent_max\n')
			headerProcessed = 1 ## set header to processed
						
		## parse non-header data
		else:
			## reinitialize
			outcome2start = {'transplant' : 0}
			outcome2end = {'transplant' : 0}
			
			## assume first col to be unique ID
			subjID = fields[0]
			
			## collect events/outcomes/conditions for one row 
			## regardless of order
			for i in range(0, len(cols), 3):
				outcome = col2outcomes[ cols[i] ]
				start   = fields[ int(cols[i+1])-1 ]
				end     = fields[ int(cols[i+2])-1 ]
				
				seqfile.write(subjID + '\t' + outcome + '\t' + start + '\t' + end + '\n')				
					
				
				
					
				
	## close files
	f1.close()
	logfile.close()
	seqfile.close()
	#trajfile.close()
	

