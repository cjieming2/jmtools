#!/usr/bin/env python

import os, sys, distutils
import argparse
import re

parser=argparse.ArgumentParser(description='This script processes est file of HLA-HD output and formats in the form of the final.result.txt file. Currently, only grab results for A,B,C,DPA1,DPB1,DQA1,DQB1,DRB1,DRB3,DRB4,DRB5',
                               usage='hlahd_est_postprocessing.py <foldername>',
                               epilog="EXAMPLE: hlahd_est_postprocessing.py HH003230 > test.out")
parser.add_argument('foldername', nargs=1, help='name of sample folder containing HLA-HD est files, note that we assume the result folder in this folder; first 2 lines start with a hash, followed by a line with 4 columns, which can separated by commas')

## help if no arguments or -h/--help
if len(sys.argv)==1:
    parser.print_help()
    sys.exit(1)
args=parser.parse_args()

## main program
if __name__ == '__main__':

    ## define the alleles that are impt here; in this order
    alleles = ["A","B","C","DRB1","DQA1","DQB1","DPA1","DPB1","DRB3","DRB4","DRB5"]
    
    ## open each est file
    foldername = sys.argv[1].strip()
    for allele in alleles:
    	ctr = 0
    	allele1nottypedflag = 0
    	filename = foldername + '/result/' + foldername + '_' + allele + '.est.txt' 
    	f1 = open(filename, 'r')
    	
    	# print allele (row name)
    	print "%s\t" % (allele),
    	
    	## read HLA-HD est 
    	for line in f1:
    		
    		## DRB3/4/5 if no candidates, skip file
    		## found that there can be more than 3 lines in est file, skip file 
    		## more than 3 lines due to (1) ambiguous pairs, (2) 2 best allele pairs (same score probably?)
    		if(line.strip() == "No candidate."):
    			print "Not typed\tNot typed"
    			break
    		elif(ctr == 3):
    			break
    		## if #Pair Count and #Best allele pair skip line
    		elif(line.strip()[0] == "#"):
    			ctr += 1
    			continue
    		
    		## else format the 3rd 
    		ctr += 1
    		fields = line.rstrip().split('\t')
    		allele1 = fields[0].strip().split(',')[0]
    		allele2 = fields[1].strip().split(',')[0] # could be a '-'
    		status1 = fields[2].strip()
    		status2 = fields[3].strip()
    		
    		## apply incomp filter
    		# for allele1
    		if(re.search('incomp+', status1, re.I | re.M)):
    			print "Not typed" + "\t",
    			allele1nottypedflag = 1
    		else:
    			print allele1 + "\t",
    			
    		# for allele2
    		if(re.search('incomp+', status2, re.I | re.M)):
    			print "Not typed"
    		elif((allele2 == "-") and ((allele1nottypedflag) or (allele1 == "Not typed"))):
    			print "Not typed"
    		else:
    			print allele2
    			
    	## close file
    	f1.close()
      