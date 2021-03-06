#!/usr/bin/perl

use warnings;
use strict;

my $usage = $0." pat_chrom_file mat_chrom_file SNP_file sample_id\n";
if (scalar(@ARGV) < 4) {
    print STDERR $usage;
    exit;
}

my ($chr1,$chr2) = ("","");
if    ($ARGV[0] =~ "chrom(.+)_NA") { $chr1 = $1; }
elsif ($ARGV[0] =~ "chr(.+)_NA")   { $chr1 = $1; }
elsif ($ARGV[0] =~ "(.+)_NA")      { $chr1 = $1; }
if    ($ARGV[1] =~ "chrom(.+)_NA") { $chr2 = $1; }
elsif ($ARGV[1] =~ "chr(.+)_NA")   { $chr2 = $1; }
elsif ($ARGV[1] =~ "(.+)_NA")      { $chr2 = $1; }
if ($chr2 ne $chr1) {
    print STDERR "Files for different chromosomes.\n";
    exit;
}
#$chr2 = substr($chr1,3);
#$chr2 = "chr".$chr2;
#$chr1 = "chr".$chr1;

my $pat_seq = parseSequence($ARGV[0]);
my $mat_seq = parseSequence($ARGV[1]);
if (length($pat_seq) <= 0 || length($mat_seq) <= 0) {
    print STDERR "Empty sequence(s).\n";
    exit;
}

my $file = $ARGV[2];
if (!open(FILE,$file)) {
    print STDERR "Can't open file '",$file,"'.\n";
    next;
}

my $id = $ARGV[3];
my $index = -1;
my ($n_corr,$n_wrong) = (0,0);
open(FILE,$file);
while (my $line = <FILE>) {
    if (substr($line,0,2) eq "##") { next; }
    my @w = split(/\s+/,$line);
    if (substr($line,0,2) eq "#C") {
	my $n = scalar(@w);
	for (my $i = 0;$i < $n;$i++) {
	    if ($w[$i] eq $id) { $index = $i; last; }
	}
    }
    if (substr($w[0],0,5) eq "chrom") {
	$w[0] = substr($w[0],5);
    } elsif (substr($w[0],0,5) eq "chr") {
	$w[0] = substr($w[0],3);
    }
    if ($w[0] ne $chr1 && $w[0] ne $chr2) { next; }
    my ($pos,$ref,$alt,$gen) = (1,"","","");
    if ($index >= 0) {
	$pos = $w[1];
	$ref = $w[3];
	$alt = $w[4];
	$gen = getGenotype($w[$index]);
    }
    my $pc = substr($pat_seq,$pos - 1,1);
    my $mc = substr($mat_seq,$pos - 1,1);
    $pc =~ tr/[a-z]/[A-Z]/;
    $mc =~ tr/[a-z]/[A-Z]/;
    if ($gen eq "00") {
	if ($pc eq $ref && $mc eq $ref) { $n_corr++; }
	else                            { $n_wrong++; }
    } elsif ($gen eq "11") {
	if ($pc eq $alt && $mc eq $alt) { $n_corr++; }
	else                            { $n_wrong++; }
    } elsif ($gen eq "10") {
	if ($pc eq $alt && $mc eq $ref) { $n_corr++; }
	else                            { $n_wrong++; }
    } elsif ($gen eq "01") {
	if ($pc eq $ref && $mc eq $alt) { $n_corr++; }
	else                            { $n_wrong++; }
    }
}
close(FILE);
print $n_corr," ",$n_wrong,"\n";

exit;



sub getGenotype
{
    my $in = shift;
    my @w = split(/\:/,$in);
    return substr($in,0,1).substr($in,2,1);
}

sub parseSequence
{
    my $file = shift;
    if (!open(FILE,$file)) {
        print STDERR "Can't open file '",$file,"'.\n";
        return 0;
    }
    my ($header,$seq) = ("","");
    while (my $line = <FILE>) {
        chomp($line);
        if (substr($line,0,1) eq ">") {
            $header = $seq = "";
        } else {
            $seq .= $line;
        }
    }
    close(FILE);
    if (length($seq) <= 0) { return ""; }
    return $seq;
}
