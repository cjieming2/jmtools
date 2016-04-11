#!/usr/bin/perl -w
use strict;
use POSIX qw(ceil floor);
use List::Util qw[min max];
use List::Util qw(sum);

# This program is for the FIG Phase I paper for gill, the motif gain and loss. This prgram just outputs annotated vdf file

#/net/gerstein/xm24/ncVEP/ncVARII/Diversity/Original
#/net/gerstein/xm24/ENCODE.companion/Pgene/May2012/pgeneExonWithExpEvidence.0518.bed


# * Gerp>2 filter
# * Different populations (14) differently
# * Different delta frequency in the PWM
# * SNPSOURCE=LOWCOV only
# * SNPs go redundantly to different categories
# * Same SNPs are counted once in each category

unless ($ARGV[2]) {
print <<EOF;
	perl XXX.pl elm.file outfile tagInVcf
		
	e.g.: infile: /net/gerstein/xm24/ENCODE.companion/Pouya.Motif/TF_bound/peakSeq/Union_All_Cell_Lines/ATF3.bound
	e.g.: MOTIF
EOF
exit;
}

# unless ($ARGV[0]) {
# print <<EOF;
# 	perl XXX.pl infile <-m>
# 	
# 	options:
# 	-m	use mask files
# 	
# 	e.g.: infile: /net/gerstein/xm24/ENCODE.companion/Pgene/May2012/pgeneExonWithoutExpEvidence.0518.bed
# EOF
# exit;
# }


my $BED = 0;
my $elm_line;
my $elm_tag;
my @elm;
my $ELM_CHR = 0;
my $ELM_START = 1;
my $ELM_END = 2;
my @info;
my $line;
my $path = "/net/gerstein/xm24/1000Genomes/release/20110521/ALL.chr";
my $path2 = ".phase1_release_v3.20101123.snps_indels_svs.genotypes.vcf.gz";
my $file;
my $region;
my $maskfile;
my $maskseq;
my $maskline;
my %ref=();
my $temp;
my $key;
my $val;
my $i;
my $j;
my $k;

my $POS = 1;
my $REF = 3;
my $ALT = 4;
my $INFO = 7;
my $AC;
my $AN;
my $AA;
my $VT;
my %diversity;
my %diversity_mask;
my @freq;
my $freq;
my $daf;
my $SNPSOURCE;
my $Ref_al;
my $tag_mask;
my $elm_len;
my $elm_len_mask;
my $sub_seq;

my $out_var;
my $out_prefix = (split/\//,$ARGV[0])[-1];
my $count_tot = 0;

open OUT, ">$ARGV[1]" or die;


# open DIV, ">$outpath_div/Original/$out_prefix.diversity" or die;
# print DIV "SNP\tINDEL\tSV\t[Element]\n";
# open DAF, ">$outpath_daf/Original/$out_prefix.daf" or die;
# print DAF "DAF\tVariant\tVar_Pos\t[Element]\n";


open ELM, "<$ARGV[0]" or die;
if($ARGV[0] =~ m/\.bed$/){          #Check whether file is in BED format
	$BED = 1;
}
while($elm_line = <ELM>){
	chomp($elm_line);
	@elm = split/\s+/,$elm_line;
	$elm[$ELM_CHR] = (split/chr/,$elm[$ELM_CHR])[-1];
	$elm[$ELM_START] += $BED;
	$elm_tag = $elm[1];
	foreach $i (2..(scalar(@elm)-1)){
		$elm_tag = $elm_tag."#".$elm[$i];
	}
	
	if(not exists $ref{$elm[$ELM_CHR]}){
		$ref{$elm[$ELM_CHR]}->[0] = {(start=>$elm[$ELM_START], end=>$elm[$ELM_END], line=>$elm_tag)};
	}else{
		$temp = $ref{$elm[$ELM_CHR]};
		$ref{$elm[$ELM_CHR]}->[scalar(@$temp)] = {(start=>$elm[$ELM_START], end=>$elm[$ELM_END], line=>$elm_tag)};		
	}
}
close ELM;

while(($key,$val) = each(%ref)){
	$file = $path.$key.$path2;
	next if(!(-e $file));

	foreach $i (@$val){
# 		%diversity = (SNP=>0,INDEL=>0,SV=>0);
# 		%diversity_mask = (SNP=>0,INDEL=>0,SV=>0);
		$region = $key.":".$i->{start}."-".$i->{end};
		open IN, "/home/xm24/bin/tabix $file $region |" or die;
		while($line = <IN>){
			@info = split/\s+/,$line;
			foreach $j (0..($INFO-1)){
				print OUT "$info[$j]\t";
			}
			print OUT "$info[$INFO];$ARGV[2]=$i->{line}";
			foreach $j (($INFO+1)..(scalar(@info)-1)){
				print OUT "\t$info[$j]";
			}
			print OUT "\n";
		}
		close IN;
	}
}

close OUT;




