#!/usr/bin/env python3

#######################################################
## author: Jieming Chen                            ####
## Oct 1 2019                                      ####
## if use script, please provide acknowledgements. ####
#######################################################


import os, sys, distutils, re, argparse

## IMGT is apparently a variant of the EMBL format
## SeqIO contains IMGT parser from BioPython
from Bio import SeqIO 

parser=argparse.ArgumentParser(description='this script will extract the exon information, parse the file hla.dat v3.35.0 from IMGT github page and converts to a tab-delimited file and it currently extracts aa sequence of exon 2 of all alleles. col1: hla_allele, col2: exonstatus, col3: ex2 seq; TODO: list_of_HLA_alleles',
                               usage='imgt_hladat_parser.py <list_of_HLA_alleles> <hla_dat> > out.fasta',
                               epilog="EXAMPLE: imgt_hladat_parser.py my.hlaii.list hla.dat > test.fasta")
#parser.add_argument('list_of_HLA_alleles', nargs=1, help='headerless list of HLA alleles in std 4-digit (or better) nomenclature')
parser.add_argument('hla_dat', nargs=1, help='hla.dat file from IMGT')
parser.add_argument('output', nargs='?', type=argparse.FileType('w'), default=sys.stdout, help='STDOUT')


## help if no arguments or -h/--help
#if len(sys.argv) < 2:
if len(sys.argv) < 1:
    parser.print_help()
    sys.exit(1)
args = parser.parse_args()

## variables
entryctr = 0
termctr = 0
exonctr = 0
cdsflag = 0
bline_FT_CDS = ''
bline_FT_CDS_full = ''
exonflag = 0
exonstatus = list('--------') ## HLAI genes have 8 ex, HLAII-alpha have 5 ex HLAII-beta have 6 ex

## main program
if __name__ == '__main__':
	
		#### OUTPUT header ####
		## a tab delimited file with 3 cols
		f_output = 'imgt_parsed_' + os.path.basename(sys.argv[1]).strip().split('.')[0] + '.txt'
		print("HLA_allele\texon_status\tex2_aa_seq")
		
		## open hla.dat
		## biopython to read format
		## this works but with insuff information for me!
		#records = list(SeqIO.parse(sys.argv[1], "imgt"))
		
		#print(records) # debug
		
		
		## manual parse line by line
		with open(sys.argv[1], 'r') as f_hladat:
			line = f_hladat.readline()
			ctr = 0
			
			while line:

				## strip line of whitespaces
				line = f_hladat.readline().strip()
				
				## retain only DE description, gives HLA allele name
				## retain FT feature table for exon info
				patt = re.compile('^SQ|^FH|^XX|^DT|^AC|^SV|^KW|^OS|^OC|^RN|^RC|^RP|^RX|^RA|^RT|^RL|^DR|^CC|^bb')
				if patt.match(line):
					continue
				
				#print("Line {}: {}".format(ctr, line)) ## debug
				
				#### store DE as start of each entry ####
				if re.search(r'^DE', line):
					bline_DE = line.split() ## split by whitespaces, exclude arg ' '
					#print("Line {}: {}".format(ctr, bline_DE)) ## debug
					hla_allele = bline_DE[1].strip().replace(',', '')
					
					
					## count each entry by DE
					entryctr += 1
				
				
				#### find FT lines ####
				if re.search(r'^FT', line) or cdsflag:
					bline_FT = line.split()
					
					#### find CDS ####
					if re.search(r'/translation=', line) or cdsflag:
						bline_FT_CDS = bline_FT[1].strip().replace('/translation="','')
						#print(bline_FT_CDS) ## debug
						
						## on the cds flag to concat the string
						cdsflag = 1
						
						## close the cds flag to close off
						if re.search(r'"$', line):
							bline_FT_CDS = bline_FT_CDS.replace('"','')
							cdsflag = 0
						
						## concat the full CDS sequence
						bline_FT_CDS_full = bline_FT_CDS_full + bline_FT_CDS
					
					#### find exon2 ####
					elif bline_FT[1] == "exon" or exonflag == 1:
						
						if exonflag == 0:
							
							## parse the exon positions in this line
							exon_gpos = bline_FT[2]
							#print(exon_gpos) ## debug
							
							## set up exon ctr and flag for encounter with "exon"
							exonflag = 1
							exonctr += 1 ## count number of word "exon" 
							continue
						
						## --rationale: we are using the CDS aa sequence directly, but using the 
						## genomic positions to guide the identification of start and end of exon2 amino acids
						## --because exons are defined in genomic sequence, the actual protein sequence might not be 
						## in threes of codons of protein CDS of exon2, 
						## i.e. the first amino acid of exon2 can be a combination of exon1 and 2
						## but, the last amino acid of exon2 will not be part of e3, if the nucleotides 
						## are not enough to form a codon
						## hence use end position of exon1 to estimate start of e2, and end of e2
						## --this will include all nucleotides of e2 (less the last few that can't form a codon)
						## and shouldnt affect alignment
						## if exon2 parse start and end position of exons
						## ** [UPDATED] from analyses of HLA alleles with full sequences, we then
						## assume here that exon1 ALWAYS contributes 1nut and e2 contributes 2nut
						## for the first aa of e2
						elif exonflag == 1:
							
							## if exon1 exists, then we need to count preceding amino acids
							if bline_FT[1] == '/number="1"':
								sta_e1_gpos = int(exon_gpos.split('..')[0])
								end_e1_gpos = int(exon_gpos.split('..')[1])
								len_e1_gpos = end_e1_gpos - sta_e1_gpos + 1 ## start and end are 1-based
								
								spill_e1_e2_gpos = 1 ## assume that e1 always contri 1nut to first aa of e2
								len_e1_ppos = int((len_e1_gpos - spill_e1_e2_gpos) / 3)
								exonflag = 0
								
								## update exon status bar
								exonstatus[0] = '+'
								
								#print("sta_e1_gpos = %i, end_e1_gpos = %i, exonctr = %i" % (sta_e1_gpos, end_e1_gpos, exonctr)) ## debug
								continue
								
							## assume here that exon1 ALWAYS contributes 1nut and e2 contributes 2nut
							## for the first aa of e2
							## hence we directly look for e2 via /number="2"
							## TODO: 1) use '-++-----' to denote which exons are found
							##       2) possibly add exon3 for class I alleles
							elif bline_FT[1] == '/number="2"':
								sta_e2_gpos = int(exon_gpos.split('..')[0])
								end_e2_gpos = int(exon_gpos.split('..')[1])
								len_e2_gpos = end_e2_gpos - sta_e2_gpos + 1 ## start and end are 1-based
								
								spill_e2_e1_gpos = 2 ## assume that e2 always contri 2nut to first aa of e2
								len_e2_ppos = int((len_e2_gpos - spill_e2_e1_gpos) / 3) + 1 ## add back the first aa from 2nut
								sta_e2_ppos = len_e1_ppos
								end_e2_ppos = sta_e2_ppos + len_e2_ppos
								exonflag = 0
								
								## update exon status bar
								exonstatus[1] = '+'
								
								#print("sta_e2_gpos = %i, end_e2_gpos = %i, exonctr = %i" % (sta_e2_gpos, end_e2_gpos, exonctr)) ## debug
								continue
							
							elif bline_FT[1] == '/number="3"':
								## update exon status bar
								exonstatus[2] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="4"':
								## update exon status bar
								exonstatus[3] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="5"':
								## update exon status bar
								exonstatus[4] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="6"':
								## update exon status bar
								exonstatus[5] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="7"':
								## update exon status bar
								exonstatus[6] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="8"':
								## update exon status bar
								exonstatus[7] = '+'
								exonflag = 0
							else: # beyond exon 8
								## a line containing 'partial' denoting a partial exon but it doesnt come here
								## because it comes after the exonflag closes
								## but there might instances where this info is useful
								## TODO: not sure how and what to do with them yet...
								## look at DRB1*01:04 to see an 
								exonflag = 0
								continue
							
						else: # if exonflag != 0 or 1
							sys.exit("ERROR: exonflag not 0 or 1!")
						
						
					else: # FT but not exon or CDS or translation
						continue
						
					
					
					
				
				## end of each entry
				if re.search(r'^//', line):
					
					## make sure the termination counter == entryctr
					termctr += 1
					
					if termctr != entryctr: 
						print("termination counter // %i != number of entries %i so far!" % (termctr, entryctr))
						sys.exit(1)
					
					#### OUTPUT ####
					
					## a tab delimited file with 3 cols
					## col1: hla allele
					## col2: exon status; note that HLAI genes have 8 ex, HLAII-alpha have 5 ex HLAII-beta have 6 ex
					##       currently, everything is set to 8 '-' by default, where a '+' is existence of an exon
					##       TODO: partial exons info are not incorporated
					## col3: exon2 aa sequence
					print("%s\t%s\t%s" % (hla_allele, ''.join(exonstatus), bline_FT_CDS_full[sta_e2_ppos:end_e2_ppos]))
					
					
					
					#print(hla_allele) ## debug
					#print(bline_FT_CDS_full) ## debug
					#print(sta_e2_ppos) ## debug
					#print(end_e2_ppos) ## debug
					#print(exonstatus) ## debug
					
					## variables to be reinitialized every record/entry
					exonctr = 0
					cdsflag = 0
					bline_FT_CDS = ''
					bline_FT_CDS_full = ''
					start_e2_ppos = 0
					end_e2_ppos = 0
					
					sta_gpos = 0
					end_gpos = 0
					len_gpos = 0
					spill_gpos = 0
					sta_e2_gpos = 0
					end_e2_gpos = 0
					len_e2_gpos = 0
					len_e2_ppos = 0
					
					exonstatus = list('--------')
				
				## ctr
				ctr += 1
	
	
	
	
	#f_listOfAlleles.close()
	#f_hladat.close()