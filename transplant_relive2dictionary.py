#!/usr/bin/env python

import os, sys, distutils, re
import argparse, unicodedata
from string import Template

parser=argparse.ArgumentParser(description='This script takes the transplant RELIVE Formats.txt file from ImmPort and '
                                           'another ImmPort column file, convert them into a tab-delimited '
                                           '3-col dictionary',
                               usage='transplant_relive2dictionary.py -c <colfile> -f <formatfile> > <output>',
                               epilog="EXAMPLE: transplant_relive2dictionary.py -c all_RELIVE_Data_Dict.txt "
                                      "-f Formats.excel.txt > threecol.out")
parser.add_argument('-c', help='tab-delimited input file with 3 columns; header required; "-" means '
                               'STDIN; the columns are col1: colnum, col2=Name, col3=Format')
parser.add_argument('-f', help='gibberish-looking Formats.txt file, with special chars replaced by "#", '
                               'with no standard format but has certain anchors such as "#FORMAT". Please '
                               'combine those boxes with CONTD')
parser.add_argument('output', nargs='?', type=argparse.FileType('w'), default=sys.stdout, help='STDOUT')

## help if no arguments or -h/--help
if len(sys.argv)==1:
    parser.print_help()
    sys.exit(1)
args=parser.parse_args()


def parse_Formats_file(datafilename):
    ## the errors option this will cover the rest of the byte sequences that I havent been able to replace with '#' (or
    # 'non-UTF8' encodings, that cannot be decoded using UTF-8 codec to a correct Unicode character)
    f1 = open(datafilename, 'r', errors="replace")

    ## variables
    d = {}
    dd = {}
    ctr = 0
    fn = 'HEY'

    ## parse Formats.excel.txt
    for line in f1:

        ## if line doesn't start with #, skip
        if ((not line.strip()) or line[0] != "#"):
            continue
        else:  ## if line starts with #
            ## if line has ## consecutively, skip
            if (line[1] == "#"):
                ctr = ctr + 1
                continue
            else:  ## you want these lines
                ## look for FORMAT
                formatname = re.match('#FORMAT NAME:\ (.+)\ +LENGTH', line.rstrip(), re.I | re.M)

                if formatname:
                    ctr = 0
                    # print(fn+'1')  ##debug
                    # print(ctr) ##debug
                    if fn == 'HEY':
                        fn = formatname.group(1)
                    else:
                        # print(fn+'2')  ##debug
                        # print(ctr)  ##debug
                        # print(dd) ##debug
                        d[fn.strip()] = dd
                        fn = formatname.group(1)
                        dd = {}
                        # print(fn+'3')## debug
                        # print(ctr) ##debug
                elif ctr >= 2:
                    # print(ctr) ##debug
                    defi = re.match('#(.+)#(.+)#(.+)#', line.rstrip(), re.I | re.M)

                    colon = re.match('(.+): *(.+)', defi.group(3).strip())

                    if colon:
                        dd[defi.group(2).strip()] = colon.group(2).strip()
                    else:
                        dd[defi.group(2).strip()] = defi.group(3).strip()

                else:
                    continue

    ## wrap up the last one
    d[fn.strip()] = dd

    f1.close()

    ## debug
    # for x in sorted(d):
    #     print(x + ' oo')
    #     for y in sorted(d[x]):
    #         print(y,'-',d[x][y])

    return d


def parse_studyfile(studyfilename):
    ## the errors option this will cover the rest of the byte sequences that I havent been able to replace with '#' (or
    # 'non-UTF8' encodings, that cannot be decoded using UTF-8 codec to a correct Unicode character)
    f2 = open(studyfilename, 'r', errors="replace")

    ## variables
    s = {}

    ## parse studyfile with 3 columns: colnum, colname, formatname
    for line in f2:
        fields = line.strip().split('\t')

        ## skip lines that do not have a format
        if (fields[2] == '0') or (fields[2] == '#N/A') or \
                (fields[0] == 'col') or (fields[2] == '$') or \
                (fields[2].strip() == ''):
            continue

        fields[0] = int(fields[0].strip())
        s[fields[0]] = fields[2].strip()

    f2.close()

    # print(s)
    return s

## main program
if __name__ == '__main__':

    ## parse a dictionary of formatname : { code : definition }
    d = parse_Formats_file(args.f)

    ## parse column info colnum : formatname
    s = parse_studyfile(args.c)

    ## print output
    ## col1: colnum
    ## col2: code
    ## col3: definition
    ## open a logfile to capture errors
    loggfilename = 'relive2dictionary-' + args.c + '.log'
    logfile = open(loggfilename, 'w')
    for x in sorted(s):
        if (s[x] not in d):
            logfile.write('Format: ' + s[x] + ', not available in Formats file in -f')
            continue
        for y in sorted(d[s[x]]):
            if y == '**OTHER**':
                logfile.write('Removed the following code and definition: ' + y + ' : ' + d[s[x]][y] + '\n')
                continue

            print(x, '\t', y, '\t', d[s[x]][y], sep='')


    logfile.close()