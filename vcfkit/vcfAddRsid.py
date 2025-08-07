#!/usr/bin/env python3

import os, sys, distutils, re
import argparse
import pymysql
from string import Template

parser = argparse.ArgumentParser(description='This script takes a vcf input file and a BED file with 4 columns, 4th column contains rsID and replaces the ID column (5th col) in VCF file with the rsID in the BED file, using ONLY the position information. This is unlike annotate command in Bcftools that also checks the alleles. Outputs to STDOUT.',
                                 usage='vcfAddRsid.py -b <bed_file> -i <input_vcf> -s <name>',
                                 epilog='EXAMPLE: vcfAddRsid.py -b a.bed -i test.vcf -s 70-1005')
parser.add_argument('-i', help='vcf file or STDIN -; header required; "-" means STDIN')
parser.add_argument('-b', help='bed file with 4th col rsID')
parser.add_argument('-s', help='name for log file; make it sample name or someting unique')


## help if no arguments or -h/--help
if len(sys.argv) == 1:
	parser.print_help()
	sys.exit(1)

args = parser.parse_args()

##### main program
if __name__ == '__main__':
	## log file
	logfile = open('vcfAddRsid-' + args.s + '.log', 'w')
	
	## read STDIN when '-' as input
	## else read as a file
	## parse VCF
	if args.i == '-':
		f1 = sys.stdin
	else:
		f1 = open(args.i, 'r')
	
	## declare variables	
	b1 = open(args.b, 'r')
	bedfile = {}
	
	## open the BED file
	for bline in b1:
		bfields = bline.rstrip().split('\t')
		
		#print(bfields[0] + "+" + bfields[2] + "->" + bfields[3]) ## debug
		
		## store dictionary chr:position and rsID
		## assume no redundancies in rows
		## add key to existing nested dictionary
		## otherwise create a new nested dictionary if it doesnt exist
		try:
			bedfile[ bfields[0] ][ bfields[2] ] = bfields[3]
		except KeyError:
			bedfile[ bfields[0] ] = { bfields[2] : bfields[3] }
	
	## VCF 			
	for line in f1:
		# print(line.rstrip()) ## debug
		## if VCF comment/first character == "#" skip
		if (line[0] == "#"):
			print(line.rstrip())
			next
		else:  ## these are normal lines
			## split line into columns
			fields = line.rstrip().split('\t')
			chr = fields[0]
			pos = fields[1]
			
			try: 
				bedfile[chr][pos]
			except KeyError:
				logfile.write("chr" + chr + ":" + pos + " not found in BED rsID.\n") 
			else:
				fields[2] = bedfile[chr][pos]
				
			print('\t'.join(fields))
			
	## close files
	logfile.close()
	f1.close()
	b1.close()