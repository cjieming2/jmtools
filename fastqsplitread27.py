#!/usr/bin/env python

import os, sys, distutils
import argparse

parser=argparse.ArgumentParser(description='This script takes a 4-line FASTQ/gz input file '
                                           'split the read and read quality into user-defined '
                                           'read length. An additional "::n" is suffixed for every '
                                           'additional n read. It is printed in as-is order of '
                                           'original file. If the read length is not divisible by '
                                           'desired length, currently does NOT discard excess. STDOUT.'
                                           'Python 2.7 compatible.'
                                           'TO-DO: implement option to discard or retain excess'
                                           'TO-DO: implement STDIN',
                               usage='fastqsplitread27.py <fastqfile> <readlen_desired> <readlen_min_discard> <mode>',
                               epilog="EXAMPLE: fastqsplitread27.py my.fastq 50 100 1 > test.fastq")
parser.add_argument('fastqfile', nargs=1, help='4-line FASTQ file')
parser.add_argument('readlen_desired', nargs=1, help='desired read length')
parser.add_argument('readlen_min_discard', nargs=1, help='min read length to discard before splitting read')
parser.add_argument('mode', nargs=1, help='1: retain any read that is more than the min read length, assume single reads - for PE, use nixshorts_PE.sh; 3: mode 1 + split the remaining read into desired readlengths or longer; 4: mode 3 + retain only the first read with desired length')
parser.add_argument('output', nargs='?', type=argparse.FileType('w'), default=sys.stdout, help='STDOUT')


## fastq parser from https://scipher.wordpress.com/2010/05/06/simple-python-fastq-parser/
class ParseFastQ(object):
    """Returns a read-by-read fastQ parser analogous to file.readline()"""
    def __init__(self,filePath,headerSymbols=['@','+']):
        """Returns a read-by-read fastQ parser analogous to file.readline().
        Exmpl: parser.next()
        -OR-
        Its an iterator so you can do:
        for rec in parser:
            ... do something with rec ...
 
        rec is tuple: (seqHeader,seqStr,qualHeader,qualStr)
        """
        if filePath.endswith('.gz'):
            self._file = gzip.open(filePath)
        else:
            self._file = open(filePath, 'rU')
        self._currentLineNumber = 0
        self._hdSyms = headerSymbols
         
    def __iter__(self):
        return self
     
    def next(self):
        """Reads in next element, parses, and does minimal verification.
        Returns: tuple: (seqHeader,seqStr,qualHeader,qualStr)"""
        # ++++ Get Next Four Lines ++++
        elemList = []
        for i in range(4):
            line = self._file.readline()
            self._currentLineNumber += 1 ## increment file position
            if line:
                elemList.append(line.strip('\n'))
            else: 
                elemList.append(None)
         
        # ++++ Check Lines For Expected Form ++++
        trues = [bool(x) for x in elemList].count(True)
        nones = elemList.count(None)
        # -- Check for acceptable end of file --
        if nones == 4:
            raise StopIteration
        # -- Make sure we got 4 full lines of data --
        assert trues == 4,\
               "** ERROR: It looks like I encountered a premature EOF or empty line.\n\
               Please check FastQ file near line number %s (plus or minus ~4 lines) and try again**" % (self._currentLineNumber)
        # -- Make sure we are in the correct "register" --
        assert elemList[0].startswith(self._hdSyms[0]),\
               "** ERROR: The 1st line in fastq element does not start with '%s'.\n\
               Please check FastQ file near line number %s (plus or minus ~4 lines) and try again**" % (self._hdSyms[0],self._currentLineNumber) 
        assert elemList[2].startswith(self._hdSyms[1]),\
               "** ERROR: The 3rd line in fastq element does not start with '%s'.\n\
               Please check FastQ file near line number %s (plus or minus ~4 lines) and try again**" % (self._hdSyms[1],self._currentLineNumber) 
        # -- Make sure the seq line and qual line have equal lengths --
        assert len(elemList[1]) == len(elemList[3]), "** ERROR: The length of Sequence data and Quality data of the last record aren't equal.\n\
               Please check FastQ file near line number %s (plus or minus ~4 lines) and try again**" % (self._currentLineNumber) 
         
        # ++++ Return fatsQ data as tuple ++++
        return tuple(elemList)


## help if no arguments or -h/--help
if len(sys.argv) < 4:
    parser.print_help()
    sys.exit(1)
args=parser.parse_args()

## variables
readlendesired = int(sys.argv[2])
readlendiscard = int(sys.argv[3])
mode = int(sys.argv[4])
start = 0
end = 0


## scenario1 - close this section later 
#sidefile = sys.argv[1] + '.mt100_single.fastq'
#f1 = open(sidefile, "w") 

## main program
if __name__ == '__main__':

    ## open input file
#    if sys.argv[1] == '-':
#        lines = sys.stdin.readlines()
#    else:
#        lines = sys.argv[1]
        
		parser = ParseFastQ(sys.argv[1])  # optional arg: headerSymbols allows changing the header symbols
		for record in parser:
		    
		    ## initialize
		    seqHeadernew,seqStrnew,qualStrnew = '', '' ,''
		    flag = 0
		    
		    ## split read record
		    seqHeader,seqStr,qualHeader,qualStr = record[0].strip(), record[1].strip(), record[2].strip(), record[3].strip()
		     
		    ## format seqHeader
		    seqHeaderlist = seqHeader.split(" ")
		    
		    ## skip if min read length not reached
		    if(len(seqStr) < readlendiscard):
		    	continue
		    
		    ## if more than min read length ## for mt100_single
		    ## mode 1: retain any read that is more than the min read length, assume single reads - for PE, use nixshorts_PE.sh
		    #f1.write("%s\n%s\n%s\n%s\n" % (seqHeader,seqStr,qualHeader,qualStr))
		    if(mode == 1):
		    	print "%s\n%s\n%s\n%s" % (seqHeader,seqStr,qualHeader,qualStr)
		    
		    ## do a ceiling to find multiples of desired read len to split
		    n = (len(seqStr) // readlendesired) + (len(seqStr) % readlendesired > 0)
		    #print n ## debug
		    for i in range(0, n):
		    	
		    	## print new seqHeader
		    	seqHeadernew = seqHeaderlist[0] + "::" + str(i+1) + " " + seqHeaderlist[1] + " " + seqHeaderlist[2]
		    	
		    	## print new split sequence
		    	start = i * readlendesired
		    	end = start + readlendesired
		    	seqStrnew = seqStr[start:end]		    		
		    		
		    	## **** discards if new read (excess) is < multiple of desired read length
		    	#if(len(seqStrnew) < readlendesired):
		    	#	continue
		    			    		
		    	## print new seq quality
		    	qualStrnew = qualStr[start:end]
		    		
		    	## do not discard excess if < multiple of desired read length
		    	## append to last read
		    	if((i != 0) and (i == n-2) and (end != len(seqStr))):
		    		#print "HERE i=%i|n=%i|len(seqStr)=%i|end=%i" % (i,n,len(seqStr),end) #debug
		    		end = len(seqStr)
		    		seqStrnew = seqStr[start:end]
		    		qualStrnew = qualStr[start:end]
		    		flag = 1
		    	
		    	## mode 3: mode 1 thresholding at a min readlen + split the remaining read into desired readlengths or longer
		    	if(mode == 3):
		    		print "%s\n%s\n%s\n%s" % (seqHeadernew,seqStrnew,qualHeader,qualStrnew)
		    		
		    	## mode 4: threshold + split + retain only the first read with desired length'
		    	if(mode == 4):
		    		if(i == 0):
		    			print "%s\n%s\n%s\n%s" % (seqHeadernew,seqStrnew,qualHeader,qualStrnew)
		    			break

		    	if(flag == 1):
		    		break
		    		
#f1.close()