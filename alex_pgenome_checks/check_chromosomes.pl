#!/usr/bin/perl

use warnings;
use strict;

my $usage = $0." ref_crom_file pat_chrom_file mat_chrom_file map_file\n";
if (scalar(@ARGV) < 4) {
    print STDERR $usage;
    exit;
}

my @seqs = ();
if (!parseSequence($ARGV[0])) { exit; }
if (!parseSequence($ARGV[1])) { exit; }
if (!parseSequence($ARGV[2])) { exit; }

my $n_seq = scalar(@seqs);
if ($n_seq < 3) {
    print STDERR "Not enough sequences.\n";
    exit;
}
if ($n_seq > 3) {
    print STDERR "Too many sequences.\n";
    exit;
}

my ($rl,$pl,$ml) = (length($seqs[0]),length($seqs[1]),length($seqs[2]));
my ($rps,$rms,$pms) = (0,0,0);
my ($rpn,$rmn,$pmn) = (0,0,0);

my $file = $ARGV[3];
if (!open(FILE,$file)) {
    print STDERR "Can't open file '",$file,"'.\n";
    next;
}
my @blocks = ();
my $n = -1;
while (my $line = <FILE>) {
    if (substr($line,0,1) eq "#") { next; }
    my @tmp = split(/\s+/,$line);
    if ($n < 0) { $n = scalar(@tmp); }
    elsif ($n != scalar(@tmp)) {
	print $file,": different number (",$n,
	print " ",scalar(@tmp),") of haplotypes at:\n";
	print $line;
	last;
    }
    push(@blocks,\@tmp);
}
close(FILE);

my $nb = scalar(@blocks);
for (my $b = 0;$b < $nb;$b++) {
    my $curr = $blocks[$b];
    my ($delta,$ind) = (0,$b + 1);
    while ($delta == 0 && $ind < $nb) {
	$delta = getDelta($curr,$blocks[$ind],$n);
	$ind++;
    }
    push(@$curr,$delta);
}

for (my $b = 0;$b < $nb;$b++) {
    my $curr = $blocks[$b];
    my $len  = $$curr[$n];
    if ($$curr[0] > 0 && $$curr[1] > 0) { # RP
	$rpn += $len;
	$rps += count($$curr[0],$$curr[1],\$seqs[0],\$seqs[1],$len);
    }
    if ($$curr[0] > 0 && $$curr[2] > 0) { # RM
	$rmn += $len;
	$rms += count($$curr[0],$$curr[2],\$seqs[0],\$seqs[2],$len);
    }
    if ($$curr[1] > 0 && $$curr[2] > 0) { # PM
	$pmn += $len;
	$pms += count($$curr[1],$$curr[2],\$seqs[1],\$seqs[2],$len);
    }
#    print $rpn," ",$rps,"\n";
#    print $rmn," ",$rms,"\n";
#    print $pmn," ",$pms,"\n";
#    print "\n";
}

my $tmp = $blocks[$nb - 1];
if ($$tmp[0] - $rl != $$tmp[1] - $pl ||
    $$tmp[0] - $rl != $$tmp[2] - $ml ||
    $$tmp[1] - $pl != $$tmp[2] - $ml) {
    print "Error in sequence length.\n";
}

my ($rpv,$rmv,$pmv) = (0,0,0);
if ($rpn > 0) { $rpv = (int($rps/$rpn*10000))/100.; }
if ($rmn > 0) { $rmv = (int($rms/$rmn*10000))/100.; }
if ($pmn > 0) { $pmv = (int($pms/$pmn*10000))/100.; }

print $file," ",$rpv," (rp) ",$rmv," (rm) ",$pmv," (pm)\n";

if ($rpv < 99) {
    print "Low identity ".$rpv." between reference and paternal sequences.\n";
}
if ($rmv < 99) {
    print "Low identity ".$rmv." between reference and maternal sequences.\n";
}
if ($pmv < 99) {
    print "Low identity ".$pmv." between paternal and maternal sequences.\n";
}

exit;

sub getDelta
{
    my ($arr1,$arr2,$n) = @_;
    my $delta = 0;
    for (my $i = 0;$i < $n;$i++) {
	if ($$arr1[$i] == 0 || $$arr2[$i] == 0) { next; }
	my $d = $$arr2[$i] - $$arr1[$i];
	if ($d <= 0) {
	    print $file,": bad block size:\n";
	    printError($file,$arr1,$arr2);
	} elsif ($delta <= 0) {
	    $delta = $d;
	} elsif ($delta != $d) {
	    print $file,": inconsistency in block size:\n";
	    printError($file,$arr1,$arr2);
	}
    }
    return $delta;
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
	    if (length($seq) > 0) { push(@seqs,$seq); }
	    $header = $seq = "";
	} else {
	    $seq .= $line;
	}
    }
    close(FILE);
    if (length($seq) <= 0) { return 0; }
    push(@seqs,$seq);
    return 1;
}

sub count
{
    my ($i1,$i2,$seq1,$seq2,$len) = @_;
    my $ret = 0;
    if ($i1 > 0 && $i2 > 0) {
	my $s1 = substr($$seq1,$i1 - 1,$len); $s1 =~ tr/[a-z]/[A-Z]/;
	my $s2 = substr($$seq2,$i2 - 1,$len); $s2 =~ tr/[a-z]/[A-Z]/;
	for (my $i = 0;$i < $len;$i++) {
	    if (substr($s1,$i,1) eq substr($s2,$i,1)) { $ret++; }
	}
    }
    return $ret;
}
