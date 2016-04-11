#!/bin/sh
#BSUB -J jmtest
#BSUB -o bsub-jmtest.log
#BSUB -e bsub-jmtest.err
#BSUB -W 670:00
date
cd /home/fas/gerstein/jc2296/jmtools
intersectBed -a 2 -b 3
date
