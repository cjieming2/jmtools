#!/usr/bin/env python3

import os, sys, distutils, re
import argparse
from string import Template

parser = argparse.ArgumentParser(description='This script takes a tab-delimited input file, and converts into tab-delimited Cytoscape compatible format. The output will allow plotting of transplant outcome sequelae based on the user-specified columns. This script assumes that the first column is the unique ID column and uses it to annotate by individual patients. Outputs 3 files, named by the input file, and prefixed with txp_immport2cytoscape_seq and the last one suffixed with .log',
                                 usage='txp_immport2cytoscape.py -c 1,2,0 -i <tsv-file>',
                                 epilog='EXAMPLE: txp_immport2cytoscape.py -c 1,2 -i file.txt')
parser.add_argument('-i', help='input file or STDIN -; header required; "-" means STDIN')
parser.add_argument('-c', help='comma-separated triplets of numbers, with the 1st number being the outcome/condition we watn cytoscape to have as a node, binary; 2nd number being the min/start date e.g. in days; 3rd number being the max/end date; x means to skip that category. E.g. -c 3,2,x would mean take column 3 for a certain outcome/condition we want Cytoscape to have as a node, typically, yes or no, 1 or 0, and column 2 is the start date, with no end date in this case. Note that the columns do not have to be in order, but they do have conform to the triplet definition, and the first number CANNOT be x.')


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
					sys.exit("First number of the triplet of comma-sep columns CANNOT be 0!")
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

#######################################################################################
## this fxn prints the sequence of events based on the start date of the outcome event
## this includes the event 'transplant', which is set to 0
## this helps to generate network in Cytoscape
## also, each row, the edge type is denoted by 'subjID'
def processSequenceFile(seqfile, logfile, subjID, outcome2start, outcome2end):
	outcomelist = []
	ct = 0 # debug
	
	## create list for printing one after the other
	for k in sorted(outcome2start, key=outcome2start.get):
		outcomelist.append(k)
		
	for i in range(0, len(outcomelist)):
		
		if(i < (len(outcomelist)-1) or i == 0):
			try:
				seqfile.write(outcomelist[i] + '\t' + subjID + '\t' + outcomelist[i+1] + '\t' + \
													str(outcome2start[ outcomelist[i] ]) + '\t' + str(outcome2end[ outcomelist[i] ]) + '\t' + \
													str(outcome2start[ outcomelist[i+1] ]) + '\t' + str(outcome2end[ outcomelist[i+1] ]) + '\n')
			except IndexError:
				#seqfile.write(outcomelist[i] + '\t' + subjID + '\tNA\n') ## debug
				logfile.write('No sequence of events for ' + subjID + '\n')
	
	return;
		
##### main program ######
if __name__ == '__main__':
	## output files
	basename = os.path.splitext(args.i)[0] ## strips only the last '.', or extension
	logfile   = open('txp_immport2cytoscape-' + basename + '.log', 'w')
	seqfile   = open('txp_immport2cytoscape_seq-' + basename + '.txt', 'w')
	#trajfile  = open('txp_immport2cytoscape_traj-' + basename + '.txt', 'w')
	
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
			seqfile.write('eventA\tsubject_ID\teventB\teventA_min\teventA_max\teventB_min\teventB_max\n')
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
				
				## an ordered list of outcomes in each row
				if(re.match('[Yy][Ee][Ss]', fields[ int(cols[i])-1 ], re.I | re.M)):
					#print(subjID + '|' + outcome + '|' + start + '|' + end) ## debug
					try:
						outcome2start.update({outcome:int(start)})
						outcome2end.update({outcome:int(end)})
					except ValueError:
						## if start is NA, but outcome is Yes
						## pseudo max time and tagging an 'NA' to it
						#print('ERROR:' + subjID + '|outcome:' + outcome + '|col:' + str(int(cols[i+1])-1) + '|start:' + start + '|end:' + end) ## debug
						outcome2start.update({outcome:5000000000})
						outcome2end.update({outcome:5000000000})
						outcome2start.update({'NA':5000000001})
						outcome2end.update({'NA':5000000001})
					
			##### print to sequence file the sequence of events, using order from outcome start for each subject #####
			##### event A -> event B per line
			#print(outcome2start) ## debug
			processSequenceFile(seqfile, logfile, subjID, outcome2start, outcome2end)
				
					
				
				
					
				
	## close files
	f1.close()
	logfile.close()
	seqfile.close()
	#trajfile.close()
	

