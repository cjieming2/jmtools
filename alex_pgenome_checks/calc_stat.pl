#!/usr/bin/perl

use warnings;
use strict;

if (!$ARGV[0]) { exit; }

foreach my $file (@ARGV) {
    my ($n_pat,$n_mat) = (0,0);

    open(FILE,$file);
    while (my $line = <FILE>) {
	if (!($line =~ "Applied")) { next; }
	my @words = split(/\s+/,$line);
	if ($line =~ "paternal") { $n_pat += $words[3]; }
	if ($line =~ "maternal") { $n_mat += $words[3]; }
    }
    close(FILE);

    print $file,":\n";
    printVariants("Paternal",$n_pat);
    printVariants("Maternal",$n_mat);
    print "\n";
}

#print "Paternal genome is different in ",$n_pat," (";
#printf("%3.2f",$n_pat/2.9e+9*100);
#print "%) of bases.\n";
    
exit;


sub printVariants
{
    my ($gen_name,$bases) = @_;
    print $gen_name," genome is different in ",$bases," (";
    printf("%3.2f",$bases/2.9e+7);
    print "%) of bases.\n";
    
}
