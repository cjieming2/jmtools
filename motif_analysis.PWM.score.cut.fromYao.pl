#!/usr/bin/perl -w 
use strict;

unless($ARGV[1]){
print <<EOF;
	Usage: perl  5.PWM.score.cut.pl PFM_file output_file [optional]p.value.threshold 
	       p.value.threshold : default is 4e-8
EOF
exit;
}

my $pfm_file = $ARGV[0];
my $output_file = $ARGV[1];
my $threshold = 4e-8;
if ($ARGV[2]){
	$threshold = $ARGV[2];
}

open(OUT,">$output_file")||die;

open(A,$pfm_file)||die;
my @IN = <A>; 
close A;
my @matrix= ();
my $motif_tag;
my $col;

for my $i (0 .. $#IN){
	my $line = $IN[$i];
	if ($line =~ /^>/){
		$line =~ s/^>//;
		$col = 0;
		if (scalar @matrix > 0){
			open(TMP,">tmp")||die;
			for my $nuc (0 .. 3){
                                print TMP join("\t",@{$matrix[$nuc]}),"\n";
                        }
                	close TMP;
                        my $value = `TFMpvalue-pv2sc -a 0.25 -c 0.25 -g 0.25 -t 0.25 -p $threshold -m tmp -w`;
                        print OUT $motif_tag,"\t",(split /\s+/,$value)[1],"\t",(split /\s+/,$value)[2],"\n";
                }
                $motif_tag = (split /\s+/,$line)[0];
                @matrix= ();
               	unlink("tmp");
	}elsif($i == $#IN){
		my @tmp = split /\s+/,$line;
		for my $j (1 ..4){
			$matrix[$j-1][$col] = log(($tmp[$j]*20+0.25)/21)-log(0.25);
		}
		open(TMP,">tmp")||die;
                for my $nuc (0 .. 3){
                	print TMP join("\t",@{$matrix[$nuc]}),"\n";
                }
                close TMP;
                my $value = `TFMpvalue-pv2sc -a 0.25 -c 0.25 -g 0.25 -t 0.25 -p $threshold -m tmp -w`;
                print OUT $motif_tag,"\t",(split /\s+/,$value)[1],"\t",(split /\s+/,$value)[2],"\n";
                unlink("tmp");

	}else{
		my @tmp = split /\s+/,$line;
		for my $j (1 ..4){
			$matrix[$j-1][$col] = log(($tmp[$j]*20+0.25)/21)-log(0.25);
		}
                $col ++;

       	}
}
close OUT;
