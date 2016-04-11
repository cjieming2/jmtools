#!/usr/bin/perl -w
#$Id: vcf_2_snp_not_phased.pl,v 1.1 2013/09/12 17:17:21 yk336 Exp $

#
# convert vcf format to file needed by alleleseq pipeline
#


use strict;

my $fn = shift;


my %iupac2code = (
                  'A' => 1,
                  'C' => 2,
                  'G' => 4,
                  'T' => 8,
                  'R' => 1|4,
                  'Y' => 2|8,
                  'S' => 2|4,
                  'W' => 1|8,
                  'K' => 4|8,
                  'M' => 1|2,
                  'B' => 2|4|8,
                  'D' => 1|4|8,
                  'H' => 1|2|8,
                  'V' => 1|2|4,
                  'N' => 1|2|4|8,
                  );


my %code2iupac = (
                  1 => 'A',
                  2 => 'C',
                  4 => 'G',
                  8 => 'T',
                  1|4 => 'R',
                  2|8 => 'Y',
                  2|4 => 'S',
                  1|8 => 'W',
                  4|8 => 'K',
                  1|2 => 'M',
                  2|4|8 => 'B',
                  1|4|8 => 'D',
                  1|2|8 => 'H',
                  1|2|4 => 'V',
                  1|2|4|8 => 'N',
    );




my $fh; 
open($fh, "<$fn") || die "cannot open the file $fn!";
while (my $l = <$fh>) {
    chomp($l);

    next if ($l =~ /^\#/);

    my @t = split(/\t/, $l);
    my $chr = $t[0];
    my $pos = $t[1];
    my $ref = $t[3];
    my $alt = $t[4];

    next if ($t[6] ne "PASS");

#    next if (length($ref) != length($alt));

    next if (length($ref) > 1);

    my @alts = split(/,/, $alt);
    
    my $long = 0;
    for my $al (@alts) {
	if (length($al) > 1) {
	    $long = 1;
	    last;
	}
    }
    next if ($long);



    ### now @alts 1st is ref
    unshift(@alts, $ref);

    my $fmt = $t[8];
    my $chd = $t[9];
    my $pat = $t[10];
    my $mat = $t[11];

    my @fmts = split(/:/, $fmt);
    my $idx = 0;
    for (@fmts) {
	last if ($_ eq "GT");
	$idx++;
    }

    my ($c1, $c2, $phased, $status) = &gt(\@alts, $chd, $idx, 1, $pat, $mat, );
    my ($p1, $p2)                   = &gt(\@alts, $pat, $idx, 0);
    my ($m1, $m2)                   = &gt(\@alts, $mat, $idx, 0);

    next if ($c1 eq "." || $c2 eq "."); # child unknown

    # mother first?
    my $ca = $c2 . $c1;
    my $pa = ($p2 eq "." ? "." : $p2) . ($p1 eq "." ? "." : $p1);
    my $ma = ($m2 eq "." ? "." : $m2) . ($m1 eq "." ? "." : $m1);

    $pa = &guess($ca, $ma) if ($pa =~ /\./);
    $ma = &guess($ca, $pa) if ($ma =~ /\./);
    if ($pa =~ /\./ || $ma =~ /\./) {
	print STDERR "$l\n";
	next;
    }


=pod
    if ($mutant) {
	$status = "MUTANT";
    } elsif ($c1 == $c2) {
	$status = "HOMO";
    } elsif ($phased) {
	$status = "PHASED";
    } elsif ($c1 != $c2) {
	$status = "HETERO";
    } else {
	$status = "UNKNOWN";
    }

    print join("\t",
	       $chr,
	       $pos,
	       $ref,
	       $alt,
	       $chd,
	       $pat,
	       $mat,
	       @alts,
	       $idx,
	       $c1, $c2,
	       $p1, $p2,
	       $m1, $m2,
	       $ca, $pa, $ma,
	       ">$mutant<",
	       $status,
	       ), "\n";
=cut

#=pod
    $chr =~ s/^chr//;
    print join("\t",
	       $chr,
	       $pos,
	       $ref,
	       $ma,
	       $pa,
	       $ca,
	       $status,
	       ), "\n";
#=cut

}


sub get_gt {
    my ($s, $idx, ) = @_;

    my @t = split(/:/, $s);
    my $gt = $t[$idx];
    my @gts = split(/[\|\/]/, $gt);

    return (\@gts, $gt);
}

sub gt {
    my ($alts, $s, $idx, $need_phase, $pat, $mat, ) = @_;

    my ($gts, $gt, ) = &get_gt($s, $idx, );
    return (".", ".", 0, "UNKNOWN") if ($gts->[0] eq "." || $gts->[1] eq ".");
    


    my $phased = 0;
    $phased = 1 if ($gt =~ /\|/);

    if ($phased || !$need_phase) {
	return ($alts->[$gts->[0]], $alts->[$gts->[1]], $phased, "PHASED");
    } else {
	return &calc_phase($alts, $s, $idx, $pat, $mat, );
    }
}


### use parents genotype to phase child gt
sub calc_phase {
    my ($allells, $cg, $idx, $pg, $mg, ) = @_;

    my ($cgts, $cgt, ) = &get_gt($cg, $idx, );
    my ($pgts, $pgt, ) = &get_gt($pg, $idx, );
    my ($mgts, $mgt, ) = &get_gt($mg, $idx, );

    
    my $c1 = $allells->[$cgts->[0]];
    my $c2 = $allells->[$cgts->[1]];

    my $m1 = $mgts->[0] eq "." ? "." : $allells->[$mgts->[0]];
    my $m2 = $mgts->[1] eq "." ? "." : $allells->[$mgts->[1]];

    my $p1 = $pgts->[0] eq "." ? "." : $allells->[$pgts->[0]];
    my $p2 = $pgts->[1] eq "." ? "." : $allells->[$pgts->[1]];

    my $ca = $c1 . $c2;
    my $pa = $p1 . $p2;
    my $ma = $m1 . $m2;


    if ($pa =~ /\./) {
#	print join("\t", "->", $ca, $pa, $ma), "\n";
	$pa = &guess($ca, $ma);	
	($p1, $p2) = split('', $pa);
    }
    
    if ($ma =~ /\./) {
#	print join("\t", "=>", $ca, $pa, $ma), "\n";
	$ma = &guess($ca, $pa);
	($m1, $m2) = split('', $ma);
    }


    # mutant
    my $mutant = &is_mutant($ca, $pa, $ma,);
    if ($mutant) {
	return ($c1, $c2, 0, "MUTANT");
    }

    # homo
    if ($cgts->[0] == $cgts->[1]) {
	return ($c1, $c2, 0, "HOMO");
    }

    # hetero
    if ($ca eq $ma && $ca eq $pa) {
	return ($c1, $c2, 0, "HETERO");
    }



    my $c = $code2iupac{ $iupac2code{$c1} | $iupac2code{$c2} };
    my $f = $code2iupac{ $iupac2code{$p1} | $iupac2code{$p2} };
    my $m = $code2iupac{ $iupac2code{$m1} | $iupac2code{$m2} };

    my ($fs, $ms);
    $fs = &a_and_b($f, $c);
    $ms = &a_and_b($m, $c);

    if (&homo2($fs) && &homo2($ms)) {
	return ($code2iupac{$fs}, $code2iupac{$ms}, 1, "PHASED");
    } else {
	my $tmp = $fs ^ $ms;
	if (&homo2($tmp)) {
	    if (&homo2($fs)) {
		return ($code2iupac{$fs}, $code2iupac{$tmp}, 1, "PHASED");
	    } elsif (&homo2($ms)) {
		return ($code2iupac{$tmp}, $code2iupac{$ms}, 1, "PHASED");
	    } else {
		return ("-", "-", 0, "AMBIGUOUS");
	    }
	} else {
	    return ("-", "-", 0, "AMBIGUOUS");
	}
    }

}



### use child and one parent to guess the other parent
sub guess {
    my ($ca, $pa, ) = @_;

    my $r;

    return $ca if ($pa =~ /\./);

    my ($c1, $c2) = split('', $ca);
    my ($p1, $p2) = split('', $pa);

    my $o1 = $iupac2code{$c1} ^ $iupac2code{$p1};
    my $o2 = $iupac2code{$c2} ^ $iupac2code{$p2};

    if ($o1 || $o2) {
	if ($o1) {
	    $r = $c1 . $p1;
	} else {
	    $r = $c2 . $p2;
	}
    } else {
	$r = $ca;
    }
    return $r;
}


sub is_mutant {
    my ($ca, $pa, $ma, ) = @_;

    my ($c1, $c2) = split('', $ca);
    my ($p1, $p2) = split('', $pa);
    my ($m1, $m2) = split('', $ma);

    my $c = $code2iupac{ $iupac2code{$c1} | $iupac2code{$c2} };
    my $p = $code2iupac{ $iupac2code{$p1} | $iupac2code{$p2} };
    my $m = $code2iupac{ $iupac2code{$m1} | $iupac2code{$m2} };

    return &mutant($p, $m, $c);
}

#
# for phasing
#

sub homo {
    my $ltr = shift;

    my $n = $iupac2code{$ltr};
    return $n==1 || $n==2 || $n==4 || $n==8;  
    # note: "or" does not work here
    # due to low precedence than "="
}
sub homo2 {
    my $n = shift;
    return $n==1 || $n==2 || $n==4 || $n==8;  
    # note: "or" does not work here
    # due to low precedence than "="
}


sub hetero {
    my $ltr = shift;

    return !homo($ltr);
}

sub comp {
    my ($a, $b) = @_;

    return $iupac2code{$a}^$iupac2code{$b};
}

sub mutant {
    my ($f, $m, $c) = @_;
    my ($m1, $m2);

    my ($fc, $mc, $cc);

    # check if child has any alleles not present in the parents, 
    # indicating
    # a mutation or sequencing error'''
    
    $fc = $iupac2code{$f};
    $mc = $iupac2code{$m};
    $cc = $iupac2code{$c};

    $m1 = $cc & ~($fc | $mc); # outside fc and mc

    $m2 = !( ($cc & $fc) && ($cc & $mc) ); # GA      AA      GG
   
#    print "==M>>$m1<\t>$m2<\n";

    return ($m1 || $m2);
}

sub a_and_b {
    my ($a, $b) = @_;

    return $iupac2code{$a} & $iupac2code{$b};
}
