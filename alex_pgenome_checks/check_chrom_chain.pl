#!/usr/bin/perl

use warnings;
use strict;

if (scalar(@ARGV) == 0) {
    print "The program checks chromosome lengths in chain file and .fa files.\n";
    exit;
}

my %len_hash = ();
foreach my $file (@ARGV) {
    my @words = split(/\./,$file);
    my $n = scalar(@words);
    if ($n > 1) {
	if ($words[$n - 1] eq "chain") { parseChain($file); }
	if ($words[$n - 1] eq "fa")    {
	    my ($name,$seq) = parseSeq($file);
	    my $len = length($seq);
	    if (defined($len_hash{$name}) &&
		$len != $len_hash{$name}) {
		print STDERR "Inconsistent length for '",$name,"'.\n";
		print STDERR "Length in .chain file is ",$len_hash{$name},"\n";
		print STDERR "Length in    .fa file is ",$len,"\n";
	    }
	}
    }
}

exit;

sub parseChain
{
    my $file = shift;
    if (!open(FILE,$file)) { next; }
    while (my $line = <FILE>) {
	my @words = split(/\s+/,$line);
	my $n = scalar(@words);
	if ($n > 9) { 
	    $len_hash{$words[2]} = $words[3];
	    $len_hash{$words[7]} = $words[8];
	}
    }
    close(FILE);
}

sub parseSeq
{
    my $file = shift;
    if (!open(FILE,$file)) { next; }
    my $line = <FILE>;
    chomp($line);
    my $name = substr($line,1);
    my $seq = "";
    while ($line = <FILE>) {
	chomp($line);
	$seq .= $line;
    }
    close(FILE);
    return ($name,$seq);
}
