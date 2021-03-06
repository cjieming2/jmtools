#!/usr/bin/env python3

#######################################################
## author: Jieming Chen                            ####
## Jan 28 2021                                     ####
## if use script, please provide acknowledgements. ####
#######################################################


import os, sys, distutils, re, argparse

## IMGT is apparently a variant of the EMBL format
## SeqIO contains IMGT parser from BioPython
## from Bio import SeqIO 

parser=argparse.ArgumentParser(description='this script will extract protein and nucleotide sequence information, parse the entire file hla.dat (e.g. v3.35.0) from IMGT github page and converts to a tab-delimited file. col1: hla_allele, col2: exonstatus, col3: ex2 aa seq, col4: DNA seq; TODO: list_of_HLA_alleles',
                               usage='imgt_hladat_parser.py <hla_dat> > out.txt',
                               epilog="EXAMPLE: imgt_hladat_parser.py hla.dat > test.txt")
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

cdsflag = 0
bline_FT_CDS = ''
bline_FT_CDS_full = ''
bline_FT_dnaseq = ''
bline_FT_dnaseq_full = ''

exonctr = 0
exonflag = 0
exonstatus = list('--------') ## HLAI genes have 8 ex, HLAII-alpha have 5 ex HLAII-beta have 6 ex
exonpos = ['N'] * 8
#exonnum = ['0'] * 8

intrctr = 0
intrflag = 0
intrstatus = list('-------')

sqflag = 0
dna_seq_len = 0
num = {"A":0, "C":0, "G":0, "T":0, "other":0}
numA = 0
numC = 0
numG = 0
numT = 0
numOther = 0

## main program
if __name__ == '__main__':
	
		#### OUTPUT header ####
		## a tab delimited file with 3 cols
		f_output = 'imgt_parsed_' + os.path.basename(sys.argv[1]).strip().split('.')[0] + '.txt'
		print("HLA_allele\tHLA_gene\texon_status\texon_pos\tintron_status\tex2_aa_seq\tDNA_seq_len\tnumA\tnumC\tnumG\tnumT\tnumOther\tDNA_seq")
		
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
				## retain FT feature table for exon and intron info
				## retain SQ for DNA sequence
				patt = re.compile('^FH|^XX|^DT|^AC|^SV|^KW|^OS|^OC|^RN|^RC|^RP|^RX|^RA|^RT|^RL|^DR|^CC|^bb')
				if patt.match(line):
					continue
				
				#print("Line {}: {}".format(ctr, line)) ## debug
				
				#### store DE as start of each entry ####
				if re.search(r'^DE', line):
					bline_DE = line.split() ## split by whitespaces, exclude arg ' '
					hla_allele = bline_DE[1].strip().replace(',', '')
					#print("Line {}: {}".format(ctr, bline_DE)) ## debug
					#print(hla_allele) ## debug
					
					
					## count each entry by DE
					## stops when encounter 2 DEs in a row? those entries are corrections
					## marked by x at end of entry. thats good but why?
					entryctr += 1
					#print(line) ## debug
					continue
				
				
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
						
						## encounter first "exon" but not nec exon1
						if exonflag == 0:
							
							## parse the exon positions in this line
							exon_gpos = bline_FT[2]
							#print(exon_gpos) ## debug
							
							## set up exon ctr and flag for encounter with "exon"
							exonflag = 1
							exonctr += 1 ## count number of word "exon" 
							continue
						
						## --rationale: we are not using the CDS aa sequence directly, but using the 
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
								exonpos[0] = str(exon_gpos)
								#exonnum[0] = "1"
								
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
								exonpos[1] = str(exon_gpos)
								#exonnum[1] = "2"
								
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
								#print("sta_e2_ppos = %i, end_e2_ppos = %i, exonctr = %i" % (sta_e2_ppos, end_e2_ppos, exonctr)) ## debug
								#print(bline_FT_CDS_full[sta_e2_ppos:end_e2_ppos]) ## debug
								continue
							
							elif bline_FT[1] == '/number="3"':
								exonpos[2] = str(exon_gpos)
								#exonnum[2] = "3"
								
								## update exon status bar
								exonstatus[2] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="4"':
								exonpos[3] = str(exon_gpos)
								#exonnum[3] = "4"
								
								## update exon status bar
								exonstatus[3] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="5"':
								exonpos[4] = str(exon_gpos)
								#exonnum[4] = "5"
								
								## update exon status bar
								exonstatus[4] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="6"':
								exonpos[5] = str(exon_gpos)
								#exonnum[5] = "6"
								
								## update exon status bar
								exonstatus[5] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="7"':
								exonpos[6] = str(exon_gpos)
								#exonnum[6] = "7"
								
								## update exon status bar
								exonstatus[6] = '+'
								exonflag = 0
							elif bline_FT[1] == '/number="8"':
								exonpos[7] = str(exon_gpos)
								#exonnum[7] = "8"
								
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
						
					#### find intron ####
					elif bline_FT[1] == "intron" or intrflag == 1:
						
						if intrflag == 0:
							
							## parse the intron positions in this line
							intron_gpos = bline_FT[2]
							#print(intron_gpos) ## debug
							
							## set up intron ctr and flag for encounter with "intron"
							intrflag = 1
							intrctr += 1 ## count number of word "intron"
							continue
							
						elif intrflag == 1:
							
							if bline_FT[1] == '/number="1"':
								## update intron status bar
								intrstatus[0] = '+'
								intrflag = 0
							elif bline_FT[1] == '/number="2"':
								## update intron status bar
								intrstatus[1] = '+'
								intrflag = 0
							elif bline_FT[1] == '/number="3"':
								## update intron status bar
								intrstatus[2] = '+'
								intrflag = 0
							elif bline_FT[1] == '/number="4"':
								## update intron status bar
								intrstatus[3] = '+'
								intrflag = 0
							elif bline_FT[1] == '/number="5"':
								## update intron status bar
								intrstatus[4] = '+'
								intrflag = 0
							elif bline_FT[1] == '/number="6"':
								## update intron status bar
								intrstatus[5] = '+'
								intrflag = 0
							elif bline_FT[1] == '/number="7"':
								## update intron status bar
								intrstatus[6] = '+'
								intrflag = 0
							else: # beyond intron 7 
								## a line containing 'partial' denoting a partial exon but it doesnt come here
								## because it comes after the intronflag closes
								## but there might instances where this info is useful
								## TODO: not sure how and what to do with them yet...
								## look at DRB1*01:04 to see an example
								intrflag = 0
								continue
								
						else: # if intronflag != 0 or 1
							sys.exit("ERROR: intronflag not 0 or 1!")
									
					else: # FT but not exon or intron or CDS or translation
						continue
					
				#### find SQ lines ####
				if re.search(r'^SQ', line):
					bline_SQ = line.split(";") ## split by semicolon
					#print("Line {}: {}".format(ctr, bline_SQ)) ## debug
					
					## dna seq length
					dna_seq_len_array = bline_SQ[0].split()
					dna_seq_len = dna_seq_len_array[2]
					
					## numbers
					numA = bline_SQ[1].strip().split()
					num.update({numA[1]:numA[0]})
					
					numC = bline_SQ[2].strip().split()
					num.update({numC[1]:numC[0]})
					
					numG = bline_SQ[3].strip().split()
					num.update({numG[1]:numG[0]})
					
					numT = bline_SQ[4].strip().split()
					num.update({numT[1]:numT[0]})
					
					numOther = bline_SQ[5].strip().split()
					num.update({numOther[1]:numOther[0]})
					
					#print(dna_seq_len) ## debug
					#print(num) ## debug
										
					## turn on flag that you found SQ
					## sequence lines do not have SQ code
					sqflag = 1
					continue
				
				## prevent sqflag from spilling to next line after sequence
				if re.search(r'^//', line):
					sqflag = 0
				
				if sqflag:
					#if re.search(r'$', line):
						bline_FT_dnaseq1 = line.strip().upper().split()
						bline_FT_dnaseq = ''.join(bline_FT_dnaseq1[:-1])
						
						## concat the full DNA sequence
						bline_FT_dnaseq_full = bline_FT_dnaseq_full + bline_FT_dnaseq
						
						#print(sqflag) ## debug
						#print(bline_FT_dnaseq) ## debug
						#print(bline_FT_dnaseq_full) ## debug
						
						continue
						
						
				
				## end of each entry
				if re.search(r'^//', line):
					
					
					
					## make sure the termination counter == entryctr
					termctr += 1
					#print(":::", bline_FT_dnaseq_full) ## debug
					
					## AssertionError: ERROR: termination counter // 21680 != number of entries 21681 so far! This error occurs and it's ok
					## entryctr will have +2 more due to spill-counting into 2 more lines of correction entries
					assert (termctr == entryctr), "ERROR: termination counter // %i != number of entries %i so far!" % (termctr, entryctr)
					
					
					#### OUTPUT ####
					
					## a tab delimited file with 3 cols
					## col1: hla allele
					## col2: exon status; note that HLAI genes have 8 ex, HLAII-alpha have 5 ex HLAII-beta have 6 ex
					##       currently, everything is set to 8 '-' by default, where a '+' is existence of an exon
					##       TODO: partial exons info are not incorporated
					## col3: exon2 aa sequence
					## col4: hla gene
					hla_gene = re.sub(r"(HLA-)*(\w.*)\*.*", r"\2", hla_allele)
					print("%s\t%s\t%s\t%s\t%s\t%s\t%i\t%i\t%i\t%i\t%i\t%i\t%s" % (hla_allele, hla_gene, ''.join(exonstatus), ';'.join(exonpos).replace("..", "-"), ''.join(intrstatus), bline_FT_CDS_full[sta_e2_ppos:end_e2_ppos], int(dna_seq_len), int(numA[0]), int(numC[0]), int(numG[0]), int(numT[0]), int(numOther[0]), bline_FT_dnaseq_full))
					#print(exonpos) ##debug
					
					#print(numA) ## debug
					#print(hla_allele) ## debug
					#print(bline_FT_CDS_full) ## debug
					#print(sta_e2_ppos) ## debug
					#print(end_e2_ppos) ## debug
					#print(exonstatus) ## debug
					
					## variables to be reinitialized every record/entry
					exonctr = 0
					intrctr = 0
					cdsflag = 0
					sqflag  = 0
					bline_FT_CDS = ''
					bline_FT_CDS_full = ''
					bline_FT_dnaseq = ''
					bline_FT_dnaseq_full = ''
					start_e2_ppos = 0
					end_e2_ppos = 0
					
					sta_e2_gpos = 0
					end_e2_gpos = 0
					len_e2_gpos = 0
					len_e2_ppos = 0
					
					sta_e1_gpos = 0
					end_e1_gpos = 0
					len_e1_gpos = 0
					len_e1_ppos = 0
					
					exonstatus = list('--------')
					intrstatus = list('-------')
					num = {"A":0, "C":0, "G":0, "T":0, "other":0}
					dna_seq_len = 0
					numA = 0
					numC = 0
					numG = 0
					numT = 0
					numOther = 0
					exonpos = ['N'] * 8
					
					
					
				
				## ctr
				ctr += 1
	
	
	
	
	#f_listOfAlleles.close()
	#f_hladat.close()