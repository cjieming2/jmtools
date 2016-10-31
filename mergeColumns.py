#!/usr/bin/env python

import os, sys, distutils
import argparse

parser=argparse.ArgumentParser(description='This script takes a tsv input file and an additional 4-column fileX to '
                                           'merge all the input columns stated by the last fileX column to the '
                                           'input column stated by the first fileX column. The second column is the '
                                           'entry in the input and definition of that entry, e.g. 10 in col1, '
                                           '1 in col2 and Asian in col3 means for each input col10, replace 1 with '
                                           'Asian',
                               usage='mergeColumns.py <inputfile> <fileX>',
                               epilog="EXAMPLE: mergeColumns.py test.txt fourcolumns.txt > test.out")
parser.add_argument('inputfile', nargs=1, help='tab-delimited input file; header required')
parser.add_argument('fileX', nargs=1, help='tab-delimited file with four columns; header not required; col1:col num, '
                                           'col2:entry in input for that column, col3:definition, col4: merge which '
                                           'input columns with format a-b or a-b,c if a range and otherwise')
parser.add_argument('output', nargs='?', type=argparse.FileType('w'), default=sys.stdout, help='STDOUT and a '
                                                                                               'mergeColumns-~.log, '
                                                                                               'an error log showing '
                                                                                               'entries that '
                                                                                               'are not defined in '
                                                                                               'fileX')
## class
class AutoVivification(dict):
    """Implementation of perl's autovivification feature."""
    ## autovivication basically means that data structures are automatically expanded at first use.
    def __getitem__(self, item):
        try:
            return dict.__getitem__(self, item)
        except KeyError:
            value = self[item] = type(self)()
            return value

## help if no arguments or -h/--help
if len(sys.argv)==1:
    parser.print_help()
    sys.exit(1)
args=parser.parse_args()

## main program
if __name__ == '__main__':

    ## open input file
    if sys.argv[1] == '-':
        lines = sys.stdin.readlines()
    else:
        f1 = open(sys.argv[1])
        lines = f1.xreadlines()

    ## open fileX
    if sys.argv[2] == '-':
        xlines = sys.stdin.readlines()
    else:
        f2 = open(sys.argv[2])
        xlines = f2.xreadlines()

    ## define variables
    mylookuptable = AutoVivification()
    ctr = 0
    firsttime = 0
    firstttime = 0

    ## write log file
    if sys.argv[1] == '-':
        fn = "stdin"
    else:
        fn = sys.argv[1]
    logfile = open("mergeColumns_" + fn + ".log", 'w')

    ## read fileX
    for xline in xlines:
        xfields = xline.rstrip().split('\t')

        ## assume no redundancies in rows
        ## add key to existing nested dictionary
        ## otherwise create a new nested dictionary if it doesnt exist
        mylookuptable[xfields[3]][xfields[0]][xfields[1]] = xfields[2]

        # try:
        #     mylookuptable[xfields[3]][xfields[0]][xfields[1]] = xfields[2]
        # except KeyError:
        #     mylookuptable[xfields[3]][xfields[0]] = { xfields[1] : xfields[2] }


    print(mylookuptable) ##debug

    ## read input file
    for line in lines:
        fields = line.rstrip().split('\t')

        ## skip header
        if ctr == 0:
            # print '\t'.join(fields)
            ctr = 1
            continue

        ## count rows
        ctr += 1

        ## redefine the column entry
        for colFour,colOneTwoThree in mylookuptable.items():
            for colOne, colTwoThree in colOneTwoThree.items():
                arrayColOne = int(colOne)-1

                cF = colFour.rstrip().split('-')
                startCol = int(cF[0])-1
                endCol = int(cF[1])-1

                try:
                    fields[arrayColOne] = mylookuptable[str(colOne)][str(fields[arrayColOne])]

                    if firsttime == 0:
                        fields[startCol] = mylookuptable[str(colOne)][str(fields[arrayColOne])]
                        firsttime = 1
                    else:
                        fields[startCol] = str(fields[startCol]) + ";" + str(mylookuptable[str(colFour)][str(colOne)][
                                                                                str(
                            fields[arrayColOne])])

                except KeyError:
                    if firstttime == 0:
                        logfile.write("column"+"\t"+"undefined_entry"+"\t"+"row"+"\n")
                        firstttime = 1

                    logfile.write(str(colOne) + "\t" + str(fields[arrayColOne]) + "\t" + str(ctr) + "\n")

                # print "colOne="+str(colOne)+";inputFileColOneEntry="+fields[arrayColOne] ##debug
                # print "inputFileColOneEntryNew="+fields[arrayColOne]  ##debug

        ## print the line
        # newfields = '\t'.join(fields)
        # print newfields

logfile.close()

