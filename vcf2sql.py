#!/usr/bin/env python

import os, sys, distutils, re
import argparse
import MySQLdb

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

## main program
if __name__ == '__main__':

    ## log file
    logfile = open('vcf2sql-' + args.i + '.log', 'w')
    datafile = open('vcf2sql-' + args.i + '.out', 'w')

    ## open database connection
    db = MySQLdb.connect(host=args.n,
                         user=args.u,
                         passwd=args.p,
                         db=args.d)

    ## prepare a cursor object using cursor() method
    ## this will let me execute all the queries
    cursor = db.cursor()

    # Drop table if it already exist using execute() method.
    tablename = "dz_risk_" + args.s
    droptable = "DROP TABLE IF EXISTS " + tablename 
    cursor.execute(droptable)
    #warnings.filterwarnings('ignore', 'unknown table') ## otherwise will generate an annoying warning

    ## Create table as per requirement
    sql = "CREATE TABLE " + tablename + """ (
             sample_ID  VARCHAR(20) NOT NULL,
             dbSNP  VARCHAR(20),
             genotype CHAR(2) ) """ 

    cursor.execute(sql)

    ## read STDIN when '-' as input
    ## else read as a file
    if args.i == '-':
        lines = sys.stdin.readlines()
    else:
        f1 = open(args.i)
        lines = f1.xreadlines()

    for line in lines:

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

                # insert data
                # try:
                #     insertdata = "INSERT INTO " + tablename + " VALUES (%s, %s, %s)"
                #     cursor.execute(insertdata, (args.s, rsID, genotype))
                #     db.commit()
                # except:
                #     db.rollback()
                datafile.write(args.s + '\t' + rsID + '\t' + genotype + '\n')  ## debug

            else:
                logfile.write('At position ' + snp + ', ' + 'no matches for regex \"' + args.r + '\"\n')

    ## insert data using insertdata_fast
    try :
        cwd = os.getcwd()
        datafilename = cwd + '/vcf2sql-' + args.i + '.out'
        insertdata_fast = "LOAD DATA INFILE \'" + datafilename + "\' INTO TABLE " + tablename
        print datafilename ##debug
        cursor.execute(insertdata_fast)
        db.commit()
    except:
        db.rollback()

    db.close()
    datafile.close()
    logfile.close()
