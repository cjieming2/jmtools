#!/usr/bin/env python3

import os, sys, distutils, re
import argparse
import pymysql
from string import Template

parser = argparse.ArgumentParser(description='This script takes in a list of samples with their respective '
                                             'populations, and reorganizes the LR and risk files generated from '
                                             'Varimed analyses by Weronika by the header broad_phenotype. Script '
                                             'assumes filenames in the current folder (.) to be sampleid_LR.txt and '
                                             'sampleid_risk.txt',
                                 usage='varimed2phenotype.py population.list',
                                 epilog='EXAMPLE: varimed2phenotype.py -d disease.list -p population.list -o '
                                        '170101_output_')
parser.add_argument('-p', help='tab-delimited file, no header required; col1: sample name, matching files; col2: '
                               'population')
parser.add_argument('-o', nargs='?', help='output file prefix; required to end with an underscore')

## help if no arguments or -h/--help
if len(sys.argv) == 1:
    parser.print_help()
    sys.exit(1)

args = parser.parse_args()


## function from boris to load data
def load_data_from_file(data_file_name, target_table):

    return


## main program
if __name__ == '__main__':

    ## log file
    logfile = open(args.o + 'varimed2phenotype' + '.log', 'w')

    ## read population file
    f1 = open(args.i, 'r')

    ## for each line: no header, col1 sampleid, col2 population
    for line in f1:

        ## parse columns
        fields = line.rstrip().split('\t')
        sampleid = fields[0]
        population = fields[1]

        ## find _LR file


        ## find _risk file





    ## close log file
    logfile.close()
