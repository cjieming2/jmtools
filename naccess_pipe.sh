# usage: naccess_pipe.sh pdbfile.list directoryOfStructures
# input file: list of pdb files (NO HEADER PLS)
# assumes you are in naccess_chains, or wherever you want to have your pdb files
# you can change your structure directory here
(while read line; do ln -s "$2$line"; done; ) < $1

# split into chains
(while read line; do pdbsplit "$line"; done; ) < $1

# naccess
for i in *.pdb; do naccess -z 0.05 -h $i; done >> $1_naccess.log

# compile results
naccess2csa $1 > atomsNotFound.txt

# create directories
mkdir naccess_rsa naccess_asa naccess_log
mv *.asa naccess_asa
mv *.rsa naccess_rsa
mv *.log naccess_log
