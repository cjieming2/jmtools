#!/usr/bin/env python

import os, sys, distutils
import argparse

parser=argparse.ArgumentParser(description='This script takes a tsv input file and an additional 3-column fileX to '
                                           'redefine the first column stipulated in fileX in the input file, '
                                           'from the second column to entries in the third column'
                                           'e.g. 10 in col1, 1 in col2 and Asian in col3 means for each input 10'
                                           'replace 1 with Asian',
                               usage='mvColumn.py <inputfile> <fileX>',
                               epilog="EXAMPLE: mvColumn.py test.txt threecolumns.txt > test.out")
parser.add_argument('inputfile', nargs=1, help='tab-delimited input file; header required')
parser.add_argument('fileX', nargs=1, help='tab-delimited file with three columns; header not required')
parser.add_argument('output', nargs='?', type=argparse.FileType('w'), default=sys.stdout, help='STDOUT and a '
                                                                                               'mvColumn-~.log, '
                                                                                               'an error log showing '
                                                                                               'entries that '
                                                                                               'are not defined in '
                                                                                               'fileX')

## help if no arguments or -h/--help
if len(sys.argv)==1:
    parser.print_help()
    sys.exit(1)
args=parser.parse_args()

## main program
if __name__ == '__main__':

    ## define variables
    if sys.argv[1] == '-':
        lines = sys.stdin.readlines()
    else:
        lines = open(sys.argv[1])
        # f1 = open(sys.argv[1]) #python2.7
        # lines = f1.xreadlines() #python2.7

    if sys.argv[2] == '-':
        xlines = sys.stdin.readlines()
    else:
        xlines = open(sys.argv[2])
        # f2 = open(sys.argv[2]) #python2.7
        # xlines = f2.xreadlines() #python2.7

    mylookuptable = {}
    ctr = 0

    # log file
    if sys.argv[1] == '-':
        fn = "stdin"
    else:
        fn = sys.argv[1]
    logfile = open("mvColumn_" + fn + ".log", 'w')

    ## read fileX; 3 columns, no header
    for xline in xlines:
        xfields = xline.rstrip().split('\t')

        ## assume no redundancies in rows
        ## add key to existing nested dictionary
        ## otherwise create a new nested dictionary if it doesnt exist
        try:
            mylookuptable[xfields[0]][xfields[1]] = xfields[2]
        except KeyError:
            mylookuptable[xfields[0]] = { xfields[1] : xfields[2] }

    # print(mylookuptable)  ##debug

    ##variables
    firstttime = 0

    ## read input file tsv matrix file
    for line in lines:
        fields = line.rstrip().split('\t')

        ## skip header
        if ctr == 0:
            print ('\t'.join(fields), sep='')
            ctr = 1
            continue

        ## count rows
        ctr += 1

        ## redefine the column entry
        for colOne,colTwoThree in mylookuptable.items():
            arrayColOne = int(colOne)-1

            try:
                fields[arrayColOne] = mylookuptable[str(colOne)][str(fields[arrayColOne])]
            except KeyError:
                if firstttime == 0:
                    logfile.write("column" + "\t" + "undefined_entry" + "\t" + "row" + "\n")
                    firstttime = 1
                ## if key or code doesnt exist, record in log file
                logfile.write(str(colOne) + "\t" + str(fields[arrayColOne]) + "\t" + str(ctr) + "\n")

            # print("colOne="+str(colOne)+";inputFileColOneEntry="+fields[arrayColOne]) ##debug
            # print("inputFileColOneEntryNew="+fields[arrayColOne])  ##debug

        ## print the line
        newfields = '\t'.join(fields)
        print(newfields, sep='')

logfile.close()