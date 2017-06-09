#!/usr/bin/env python3

import os, sys, distutils, re
import argparse
import pymysql
from string import Template

parser = argparse.ArgumentParser(description='This script takes a tab-delimited input file, and converts into tab-delimited Cytoscape compatible format. The output will allow plotting of transplant outcome sequelae and trajectories based on the user-specified columns. This script assumes that the first column is the unique ID column and uses it to annotate by individual patients. Outputs 4 files, named by the input file, and prefixed with txp_immport2cytoscape_events, txp_immport2cytoscape_seq and txp_immport2cytoscape_traj (ip) and the last one suffixed with .log',
                                 usage='txp_immport2cytoscape.py -c 1,2,0 -i <tsv-file>',
                                 epilog='EXAMPLE: txp_immport2cytoscape.py -c 1,2 -i file.txt')
parser.add_argument('-i', help='input file or STDIN -; header required; "-" means STDIN')
parser.add_argument('-c', help='comma-separated triplets of numbers, with the 1st number being the outcome/condition we watn cytoscape to have as a node, binary; 2nd number being the start date e.g. in days; 3rd number being the end date; x means to skip that category. E.g. -c 3,2,x would mean take column 3 for a certain outcome/condition we want Cytoscape to have as a node, typically, yes or no, 1 or 0, and column 2 is the start date, with no end date in this case. Note that the columns do not have to be in order, but they do have conform to the triplet definition, and the first number CANNOT be x.')


## help if no arguments or -h/--help
if len(sys.argv) == 1:
	parser.print_help()
	sys.exit(1)

args = parser.parse_args()

##### functions #####
###################################
## this function parses the header
def processHeader(cols, fields):
	for i in range(0, len(cols), 3):
				if(col[i] == -1):
					sys.exit("First number of the triplet of comma-sep columns CANNOT be 0!")
				else:
					try:
						logfile.write("cols" + cols[i]+","+cols[i+1]+","+cols[i+2] + ": " + fields[ cols[i]-1 ]+","+fields[ cols[i+1]-1 ]+","+fields[ cols[i+2]-1 ] + "\n")
					except IndexError: 
						## catch errors in c2 and c3 are -1s
						if(cols[i+1] == -1):
							logfile.write("cols" + cols[i]+","+cols[i+1]+","+cols[i+2] + ": " + fields[ cols[i]-1 ]+",skipped,"+fields[ cols[i+2]-1 ] + "\n")
						elif(cols[i+2] == -1):
							logfile.write("cols" + cols[i]+","+cols[i+1]+","+cols[i+2] + ": " + fields[ cols[i]-1 ]+","+fields[ cols[i+1]-1 ]+",skipped\n")
	return;

##################################################
## this fxn prints the non-transplant events file
## each row is the subjID, outcome, start, end; does not include the transplant
def processEventFile(eventfile, subjID, outcome, start, end):
	eventfile.write(subjID + '\t' + outcome + '\t' + start + '\t' + end + '\n')
	return;

#######################################################################################
## this fxn prints the sequence of events based on the start date of the outcome event
## this includes the event 'transplant', which is set to 0
## this helps to generate network in Cytoscape
## also, each row, the edge type is denoted by 'subjID'
def processSequenceFile(seqfile, subjID, outcome2start):
	outcomelist = []
	
	for k in sorted(outcome2start.items(), key=d.get):
		outcomelist.append(k)
	
	for i in range(0, len(outcome2start)):
		seqfile.write(outcomelist[i] + '\t' + subjID + '\t' + outcomelist[i+1] + '\n')
	
	return;
		
#########################################################################################################
## this fxn prints the trajectories of events based on the start date of the outcome event




##### main program ######
if __name__ == '__main__':
	## output files
	basename = os.path.splitext(args.i)[0] ## strips only the last '.', or extension
	logfile   = open('txp_immport2cytoscape-' + basename + '.log', 'w')
	eventfile = open('txp_immport2cytoscape_events-' + basename + '.txt', 'w')
	seqfile   = open('txp_immport2cytoscape_seq-' + basename + '.txt', 'w')
	trajfile  = open('txp_immport2cytoscape_traj-' + basename + '.txt', 'w')
	
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
	#outcomes = ['transplant']
	outcome2start = {'transplant' : 0}
	outcome2end = {'transplant' : 0}
	
	## process each line in the file
	for line in f1:
		
		## split the row into fields
		fields = line.rstrip().split('\t')
		
		## parse the header
		## print headers to output files
		if(headerProcessed == 0):
			processHeader(cols, fields) ## process header
			eventfile.write('subject_ID\toutcome\tstart\tend\n')
			seqfile.write('event_A\tsubject_ID\tevent_B\n')
			headerProcessed = 1 ## set header to processed
						
		## parse non-header data
		else:
			## assume first col to be unique ID
			subjID = fields[0]
			
			## collect events/outcomes/conditions for one row 
			## regardless of order
			for i in range(0, len(cols), 3):
				outcome = fields[ cols[i]-1 ]
				start   = fields[ cols[i+1]-1 ]
				end     = fields[ cols[i+2]-1 ]
				
				## an ordered list of outcomes in each row
				if(re.match('[yY]es', outcome, re.I | re.M)):
					#outcomes.append(outcome)
					outcome2start.update({outcome:start})
					outcome2end.update({outcome:end})
					
					##### print to events file for every available outcome for each subject #####
					processEventFile(eventfile, subjID, outcome, start, end)
					
				##### print to sequence file the sequence of events, using order from outcome start for each subject #####
				##### event A -> event B per line
				processSequenceFile(seqfile, subjID, outcome2start)
				
					
				
				
					
				
	## close files
	f1.close()
	logfile.close()
	eventfile.close()
	seqfile.close()
	trajfile.close()
	

