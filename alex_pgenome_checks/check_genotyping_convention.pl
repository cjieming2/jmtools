#!/usr/bin/perl

use warnings;
use strict;

my ($child_id,$mother_id,$father_id) = ("","","");
my ($f_child,$f_father,$f_mother) = (-1,-1,-1);
my $f_format = -1;
my ($convention_FM,$convention_MF) = (0,0);
my $n_unphased = 0;

my $usage = $0." -child id -father id -mother id [file1 file2 file3]\n";
if (scalar(@ARGV) <= 0) {
    print STDERR $usage;
    exit;
}

my @files = ();
my $n_args = scalar(@ARGV);
for (my $i = 0;$i < $n_args;$i++) {
    if ($ARGV[$i] eq "-child") {
	if (++$i >= $n_args) { next; }
	$child_id = $ARGV[$i];
    } elsif ($ARGV[$i] eq "-father") {
	if (++$i >= $n_args) { next; }
	$father_id = $ARGV[$i];
    } elsif ($ARGV[$i] eq "-mother") {
	if (++$i >= $n_args) { next; }
	$mother_id = $ARGV[$i];
    } else {
	push(@files,$ARGV[$i]);
    }
}

foreach my $file (@files) {
    if (!open(FILE,$file)) { 
	print STDERR "Can't open file '",$file,"'.\n";
	next;
    }
    while (my $line = <FILE>) {
	if (substr($line,0,1) eq "#") {
	    if (substr($line,0,6) ne "#CHROM") { next; }
	    my @words = split(/\s+/,$line);
	    my $index = 0;
	    foreach my $w (@words) {
		if    ($w eq $child_id)  { $f_child  = $index; }
		elsif ($w eq $father_id) { $f_father = $index; }
		elsif ($w eq $mother_id) { $f_mother = $index; }
		elsif ($w eq "FORMAT")   { $f_format = $index; }
		$index++;
	    }
	} else {
	    if ($f_child < 0 || $f_father < 0 || $f_mother < 0) { next; }
	    my @words = split(/\t/,$line);
	    my $f_genotype = getGenotypeField($words[$f_format]);
	    if ($f_genotype < 0) { next; }
	    my $g_child  = getGenotype($words[$f_child], $f_genotype);
	    if (!($g_child =~ "|")) { next; }
	    my $g_father = getGenotype($words[$f_father],$f_genotype);
	    my $g_mother = getGenotype($words[$f_mother],$f_genotype);
	    if (length($g_father) < 3) { next; }
	    my $gf = substr($g_father,0,1).substr($g_father,2,1);
	    my $gm = substr($g_mother,0,1).substr($g_mother,2,1);
	    if ($g_child eq "1|1" || $g_child eq "0|0") { next; }
	    if (substr($g_child,1,1) eq "/") { $n_unphased++; }
	    if ($g_child eq "0|1") {
		if ($gf eq "11" && $gm ne "11") { $convention_MF++; }
		if ($gf eq "01" && $gm eq "00") { $convention_MF++; }
		if ($gf eq "10" && $gm eq "00") { $convention_MF++; }
		if ($gm eq "11" && $gf ne "11") { $convention_FM++; }
		if ($gm eq "01" && $gf eq "00") { $convention_FM++; }
		if ($gm eq "10" && $gf eq "00") { $convention_FM++; }
	    }
	    if ($g_child eq "1|0") {
		if ($gf eq "11" && $gm ne "11") { $convention_FM++; }
		if ($gf eq "01" && $gm eq "00") { $convention_FM++; }
		if ($gf eq "10" && $gm eq "00") { $convention_FM++; }
		if ($gm eq "11" && $gf ne "11") { $convention_MF++; }
		if ($gm eq "01" && $gf eq "00") { $convention_MF++; }
		if ($gm eq "10" && $gf eq "00") { $convention_MF++; }
	    }
	}
    }
    close($file);
    print $file," ",$convention_FM," (FM) ",$convention_MF," (MF) ",$n_unphased," (unphased)\n";
}


exit;

sub getGenotype
{
    my ($record,$field) = @_;
    my @words = split(/\:/,$record);
    my $n = scalar(@words);
    if ($field >= 0 && $field < $n) { return $words[$field]; }
    return "";
}

sub getGenotypeField
{
    my $record = shift;
    my @words = split(/\:/,$record);
    my $index = 0;
    foreach my $w (@words) {
	if ($w eq "GT") { return $index; }
	$index++;
    }
    return -1;
}
