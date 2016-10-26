#!/usr/bin/env python3

import os, sys, distutils, re
import argparse
import pymysql
from string import Template

parser = argparse.ArgumentParser(description='This script takes a vcf input file and converts it to a mySQL table with '
                                             '3 columns: subject, dbSNP, genotype, where dbSNP contains the rsID of '
                                             'the '
                                             'SNP and genotype contains the genotype in format AA,AB, or BB.'
                                             'It outputs a file and uses LOAD_DATA_INFILE to expedite data insertion.',
                                 usage='vcf2sql.py -n <host> -u <username> -d <database> -s <sample_name> -i <input '
                                       'vcf>',
                                 epilog='EXAMPLE: vcf2sql.py -n buttelab-aws -u chenj -s NA12878 -d chenj -r '
                                        'dbSNP142_ID=rs -i test.vcf')
parser.add_argument('-i', help='vcf file; header required; "-" means STDIN')
parser.add_argument('-n', help='hostname for database and table')
parser.add_argument('-u', help='username for database')
parser.add_argument('-d', help='database')
parser.add_argument('-s', help='sample/subject name')
parser.add_argument('-p', nargs='?', help='password for database')
parser.add_argument('-r', nargs='?', help='regex for the INFO field')

## help if no arguments or -h/--help
if len(sys.argv) == 1:
    parser.print_help()
    sys.exit(1)

args = parser.parse_args()

## function from boris to load data
def load_data_from_file(data_file_name, target_table):

   # loads data from file data_file_name into table target_table
   connection = pymysql.connect(host=args.n, user=args.u, passwd=args.p, db=args.d, local_infile=True)
   cursor = connection.cursor()

   ## Create table as per requirement
   droptable = "DROP TABLE IF EXISTS " + tablename
   cursor.execute(droptable)

   createtable = "CREATE TABLE " + tablename + """ (
                   sample_ID  VARCHAR(20) NOT NULL,
                   dbSNP  VARCHAR(20),
                   genotype CHAR(2) ) """
   cursor.execute(createtable)

   ## add data
   sql = Template("""
                       LOAD DATA LOCAL INFILE "$file"
                       INTO TABLE $table CHARACTER SET UTF8 FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';""")
   # sql = Template("""
   #                    LOAD DATA LOCAL INFILE "$file"
   #                    INTO TABLE $table FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';""")

   sql = sql.substitute(file=data_file_name, table=target_table)

   # sql = Template("""
   #         LOAD DATA LOCAL INFILE "$file"
   #         INTO TABLE $table FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n' (id,gsm,val) SET pk = null;""")
   # sql = sql.substitute(file=data_file_name, table=target_table)

   cursor.execute(sql)
   connection.commit()
   cursor.close()
   connection.close()

   # print("finished loading: ", data_file_name)
   # os.remove(data_file_name)
   sys.stdout.flush()

   # SET FOREIGN_KEY_CHECKS = 0;
   # SET UNIQUE_CHECKS = 0;
   # SET SESSION tx_isolation='READ-UNCOMMITTED';
   # SET sql_log_bin = 0;

   return


## main program
if __name__ == '__main__':

    ## log file
    logfile = open('vcf2sql-' + args.i + '.log', 'w')
    datafile = open('vcf2sql-' + args.i + '.out', 'w')

    ## read STDIN when '-' as input
    ## else read as a file
    ## parse VCF
    if args.i == '-':
        f1 = sys.stdin.readline()
    else:
        f1 = open(args.i, 'r')

    for line in f1:

        # print line.rstrip() ## debug
        ## if second character == "##" skip
        if (line[0] == "#") and (line[1] == "#"):
            next;
        elif line[0] == "#":  ## if only first char "#", this is the header
            next;
        else:  ## these are normal lines

            ## split line into columns
            fields = line.rstrip().split('\t')
            snp = fields[0] + ' ' + fields[1]
            ref = fields[3]
            alt = fields[4]
            info = fields[7]
            subj = fields[9]

            ## multiple alternate alleles
            altalleles = alt.rstrip().split(',')
            alleles = [ref]

            for i in range(0, len(altalleles)):
                alleles.append(altalleles[i])

            ## use re.escape to put to escapify the special char
            ## find rsID using the dbSNP -i info option
            ## re.I ignores case and re.M multiline
            ## the regex finds the first (or more) ';' and takes whatever's between the FIRST ';' (it rejects all
            # other ';' and the args.r
            myregex = re.search(re.escape(args.r) + '([^;$]+)', info, re.I | re.M)
            #print myregex ## debug

            if myregex:
                rsID = myregex.group(1)

                ## genotype
                subjinfo = subj.rstrip().split(':', 6)
                assert len(subjinfo) == 6, logfile.write('<6 items in the INFO column')

                unphased = re.match('.+/.+', subjinfo[0], re.I | re.M)
                phased = re.match('.+\|.+', subjinfo[0], re.I | re.M)

                if unphased:
                    a1 = subjinfo[0].rstrip().split('/')[0]
                    a2 = subjinfo[0].rstrip().split('/')[1]
                    genotype = alleles[int(a1)] + alleles[int(a2)]
                elif phased:
                    a1 = subjinfo[0].rstrip().split('|')[0]
                    a2 = subjinfo[0].rstrip().split('|')[1]
                    genotype = alleles[int(a1)] + alleles[int(a2)]
                else:
                    ## some of these haploid genotype are not in Y chr
                    genotype = alleles[ int(subjinfo[0]) ]

                datafile.write(args.s + '\t' + rsID + '\t' + genotype + '\n')  ## debug

            else:
                logfile.write('At position ' + snp + ', ' + 'no matches for regex \"' + args.r + '\"\n')

    ## the function creates table
    ## and load data to mySQL from file
    cwd = os.getcwd()
    datafilename = cwd + '/vcf2sql-' + args.i + '.out'
    tablename = "dz_risk_" + args.s

    load_data_from_file(datafilename, tablename)


    datafile.close()
    logfile.close()
