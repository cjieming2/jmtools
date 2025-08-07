#!/usr/bin/perl -w
use strict;
use List::Util qw[min max];

unless($ARGV[3]){
print <<EOF;
	Usage: perl xxx.pl snp_file pwm_file mode [optional]encode_motif [optional]reference_genome [optional]score_file [Optional]p.value
			
		   mode : 0 - Jasmine's cal. Only consider motifs discovered in ENCODE peaks
		   		  1 - consider all possible motifs. pwm scores changes are reported for significant motifs (either reference or alternative).
		   encode_motif : This is required when mode = 0 !
		   reference_genome : This is required when mode =1 !
		   score_file : This is required when mode = 1 !

EOF
exit;
}
my $snp_file = $ARGV[0];
my $pwm_file = $ARGV[1];
my $mode = $ARGV[2];
if ($mode ==0){
	my $encode_bound_motif = $ARGV[3];
	&motif_fixed($snp_file,$pwm_file,$encode_bound_motif);
}else{
	my $reference_genome = $ARGV[3];
	my $score_file = $ARGV[4];
	my $p_value = $ARGV[5];
	&motif_unfixed($snp_file,$pwm_file,$reference_genome,$score_file,$p_value);
}


# 1. Motif Breaking (bound motifs under ENCODE peak regions)
sub motif_fixed{
	$| = 1;
	
	my ($input_file,$pfm,$bound_motif) = @_;
	
	my $input_file_new;
	my $id;
	my $chr;
	my $pos;
	my $line;
	my @info;
	my $temp;
	my $prev_name;
	my %motif;
	my $A = 1;
	my $C = 2;
	my $G = 3;
	my $T = 4;
	my $ref;
	my $alt;
	my $AA;
	my $der_al;
	my $motif_len;
	my $factor;
	my $pos_in_motif;
	my $motif_name;
	my $derived_allele_freq;
	my $AA_freq;
	my $interval;

# Read in PFM file 
	open MOTIF, $pfm or die;
	while(<MOTIF>){
		chomp $_;
		if(/^>/){
			$prev_name = (split/>|\s+/,$_)[1];
		}else{
			@info = split/\s+/,$_;
			if(not exists $motif{$prev_name}){
				$motif{$prev_name}->[0] = {(A=>$info[$A], T=>$info[$T], C=>$info[$C], G=>$info[$G])};
			}else{
				$temp = $motif{$prev_name};
				$motif{$prev_name}->[scalar(@$temp)] = {(A=>$info[$A], T=>$info[$T], C=>$info[$C], G=>$info[$G])};			
			}
		}
	}
	close MOTIF;


	$input_file_new = `intersectBed -a $input_file -b $bound_motif -wo | sort -k 1,1 -k 2,2n |uniq`;
	
	foreach my $input_line (split /\n+/,$input_file_new){
		chomp $input_line;
		@info = split /\t+/,$input_line;
		$ref = uc($info[3]); $alt = uc($info[4]);
			
		$AA = $ref;
		$der_al = $alt;
		
		$motif_len = $info[7]-$info[6];
		$factor = $info[11];
		if($info[10] eq "+"){
			$pos_in_motif = ($info[1]-$info[6]+1);
		}elsif($info[10] eq "-"){
			$pos_in_motif = $info[7]-$info[1];
			$AA =~ tr/ACGTacgt/TGCAtgca/;
			$der_al =~ tr/ACGTacgt/TGCAtgca/;
		}
		
		$motif_name = (split/_\d+mer/,$info[8])[0];
		if(not exists $motif{$motif_name}){
			print "Motif_Name_Not_Found\t$line\n";
			next;
		}
		
		my $ref = $motif{$motif_name};
		if($motif_len != scalar(@$ref)){
			print "Motif_Len_Not_Matched\t$line\n";
			next;
		}
		
		$derived_allele_freq = $motif{$motif_name}->[$pos_in_motif-1]->{$der_al};
		$AA_freq = $motif{$motif_name}->[$pos_in_motif-1]->{$AA};
		
		print join("\t",@info[0..4]),"\t", $AA_freq,"\t",$derived_allele_freq, "\t", "$factor#$info[8]#$info[6]#$info[7]#$info[10]#$pos_in_motif\n"; 
		}		
}

# 2. Motif gain   
sub motif_unfixed{
	my ($input,$pfm_file,$reference_file,$score_file,$p_cut) = @_; 

	my $line;
	my $snp_file = "";
	my @des;
	my @alt;
	my @ref;
	my @id;
	my @start;
	my %motif = ();
	my %motif_pfm=();
	my %score_lower;
        my %score;
        my %score_upper;

	my @info;
	my %ref = ();
	my $prev_name;
	my $A = 1;
	my $C = 2;
	my $G = 3;
	my $T = 4;
	my $temp;
	my $extract_seq;
	my @extract_seq;
	my $chr;
	my $start; 
	my $end;
	my $alt;
	my $ref;
	my $i;
	my $id;
	
	$|++;
	
		
	# Read in PFM and transform it to PWM using 20 sequences. 

	open MOTIF, "$pfm_file" or die;
	while($line = <MOTIF>){
		chomp($line);
		if($line =~ /^>/){
			$prev_name = (split/>|\s+/,$line)[1];
		}else{
			@info = split/\s+/,$line;
			if(not exists $motif{$prev_name}){
				$motif_pfm{$prev_name}->[0] = {(A=>$info[$A], T=>$info[$T], C=>$info[$C], G=>$info[$G])};
				$motif{$prev_name}->[0] = {(A=>log(($info[$A]*20+0.25)/21)-log(0.25), T=>log(($info[$T]*20+0.25)/21)-log(0.25), C=>log(($info[$C]*20+0.25)/21)-log(0.25), G=>log(($info[$G]*20+0.25)/21)-log(0.25))};
			}else{
				$temp = $motif{$prev_name};
				$motif_pfm{$prev_name}->[scalar(@$temp)] = {(A=>$info[$A], T=>$info[$T], C=>$info[$C], G=>$info[$G])};
				$motif{$prev_name}->[scalar(@$temp)] = {(A=>log(($info[$A]*20+0.25)/21)-log(0.25), T=>log(($info[$T]*20+0.25)/21)-log(0.25), C=>log(($info[$C]*20+0.25)/21)-log(0.25), G=>log(($info[$G]*20+0.25)/21)-log(0.25))};			
			}
		}
	}
	close MOTIF;

	# Read in Score file corresponding to 4e-8.

        open SCORE,"$score_file";
        while(<SCORE>){
                my ($prev_name,$cut_off,$p) = (split /\s+/,$_)[0..2];
		if ($p < $p_cut){
                        $score_upper{$prev_name} = $cut_off;
                }elsif ($p == $p_cut){
                        $score{$prev_name} = $cut_off;
                }elsif($p > $p_cut){
                        $score_lower{$prev_name} = $cut_off;
                }
        }
        close SCORE;
	

	
	# retrieve + & - 29bp around the SNP; 
	
	open(IN,$input)||die;
	while(<IN>){
		chomp $_;
		@des = split /\s+/,$_;
		push @id,$_;
		$chr = $des[0];
		$chr =~ s/chr//g;
		$start = $des[1];
		$snp_file .= join("",$chr,"\t",$start-29,"\t",$start+30,"\n");
		push @ref,uc($des[3]);
		push @alt,uc($des[4]);
		push @start,$start;
	}
	open(O,">motif_tmp")||die;
	print O $snp_file;
	close O;
	
	@des = split /\n/, `fastaFromBed -fi $reference_file -bed motif_tmp -fo stdout`;
	
	unlink("motif_tmp");
	
	
	if (scalar @des >0){
		for $i (0 .. (scalar @des/2)-1){
			$ref = $ref[$i]; $alt = $alt[$i];
			$id = $id[$i]; $start = $start[$i];
			$extract_seq=uc($des[$i*2+1]);
			@extract_seq = split //,$extract_seq;
			$extract_seq[29] = $alt;	
			
		#positive strand
			&seq_scan(\@extract_seq,"+",$start,$alt,$ref,\%motif,\%motif_pfm,\%score,$id,\%score_upper,\%score_lower,$p_cut);
		
		#negative strand
			$extract_seq =~ tr/ATCGatcg/TAGCTAGC/;
			@extract_seq = reverse(split //,$extract_seq);
			$ref =~ tr/ATCGatcg/TAGCTAGC/; 
			$alt =~ tr/ATCGatcg/TAGCTAGC/;
			$extract_seq[29] = $alt;
			&seq_scan(\@extract_seq,"-",$start,$alt,$ref,\%motif,\%motif_pfm,\%score,$id,\%score_upper,\%score_lower,$p_cut);
		}
	}
	
	
# sub-routine for the sequence scanning ... 
	
	sub seq_scan{
		
		my ($seq, $strand,$start,$alt,$ref,$motif,$motif_pfm,$score,$id,$score_upper,$score_lower,$p_cut) = @_;
		my @seq;
		my $alt_pwm_score;
		my $ref_pwm_score;
		my $ref_pfm;
		my $alt_pfm;
		my $motif_length;
		my $pwm;
		my $i;
		my $j;
		my $alt_p;
		my $ref_p;
		my %motif = %{$motif};
		my %motif_pfm = %{$motif_pfm};
		my %score = %{$score};
		my %score_upper=%{$score_upper};
		my %score_lower=%{$score_lower};
		@seq = @{$seq};
		
		foreach my $prev_name(sort keys %motif){
			$motif_length = scalar @{$motif{$prev_name}};
	
			unless (-d "pwm"){
				mkdir "pwm";
			}
			
			if (-e "pwm/$prev_name"){
			}else{
				open(TMP,">pwm/$prev_name")||die;
				$pwm = "";
				for $i(0 .. $motif_length-2){
					$pwm .= join("",$motif{$prev_name}->[$i]->{"A"},"\t");
				}
				$pwm .= join("",$motif{$prev_name}->[$motif_length-1]->{"A"},"\n");
				for $i(0 .. $motif_length-2){
					$pwm .= join("",$motif{$prev_name}->[$i]->{"C"},"\t");
				}
				$pwm .= join("",$motif{$prev_name}->[$motif_length-1]->{"C"},"\n");
				for $i(0 .. $motif_length-2){
					$pwm .= join("",$motif{$prev_name}->[$i]->{"G"},"\t");
				}
				$pwm .= join("",$motif{$prev_name}->[$motif_length-1]->{"G"},"\n");
				for $i(0 .. $motif_length-2){
					$pwm .= join("",$motif{$prev_name}->[$i]->{"T"},"\t");
				}
				$pwm .= join("",$motif{$prev_name}->[$motif_length-1]->{"T"},"\n");	
				print TMP $pwm;
				close TMP;
			}			
					
			# sequence scanning ....
			
			for ($i=30 - $motif_length; $i < 30; $i ++){
				$alt_pwm_score = 0;
				$ref_pwm_score = 0;
				
				# calculate reference & alternative PWM score;
				for ($j = 0; $j < $motif_length; $j++){
					$alt_pwm_score += $motif{$prev_name}->[$j]->{$seq[$i+$j]};
				}
				$ref_pwm_score = $alt_pwm_score - $motif{$prev_name}->[29-$i]->{$alt} + $motif{$prev_name}->[29-$i]->{$ref};
				$ref_pfm = $motif_pfm{$prev_name}->[29-$i]->{$ref};
				$alt_pfm = $motif_pfm{$prev_name}->[29-$i]->{$alt};
				next if $alt_pwm_score <= $ref_pwm_score;
				next if (defined $score_upper{$prev_name} && $ref_pwm_score >= $score_upper{$prev_name}) || (defined $score_lower{$prev_name} && $alt_pwm_score <= $score_lower{$prev_name});
				
                if ((defined $score{$prev_name} && $alt_pwm_score >= $score{$prev_name} && $ref_pwm_score < $score{$prev_name}) || (defined $score_upper{$prev_name} && defined $score_lower{$prev_name} && $alt_pwm_score >= $score_upper{$prev_name} && $ref_pwm_score <= $score_lower{$prev_name})){
						&out_print($prev_name,$i,$motif_length,$alt_pwm_score,$ref_pwm_score,$alt_pfm,$ref_pfm,$strand,$id,$start);	
				 }else{
						if (defined $score_upper{$prev_name} && $alt_pwm_score >= $score_upper{$prev_name}){
                             $ref_p = (split /\s+/,`TFMpvalue-sc2pv -a 0.25 -c 0.25 -g 0.25 -t 0.25 -s $ref_pwm_score -m pwm/$prev_name -w`)[2];
                             if ($ref_p > $p_cut){
                                   &out_print($prev_name,$i,$motif_length,$alt_pwm_score,$ref_pwm_score,$alt_pfm,$ref_pfm,$strand,$id,$start);
							}
                        }else{
                             $alt_p = (split /\s+/,`TFMpvalue-sc2pv -a 0.25 -c 0.25 -g 0.25 -t 0.25 -s $alt_pwm_score -m pwm/$prev_name -w`)[2];
                             $ref_p = (split /\s+/,`TFMpvalue-sc2pv -a 0.25 -c 0.25 -g 0.25 -t 0.25 -s $ref_pwm_score -m pwm/$prev_name -w`)[2];
                             if ($alt_p <= $p_cut && $ref_p > $p_cut){
								&out_print($prev_name,$i,$motif_length,$alt_pwm_score,$ref_pwm_score,$alt_pfm,$ref_pfm,$strand,$id,$start);	
							 }
					  }	
				}
			}					
		}		
	}

#end of routine	

sub out_print{
	my ($name,$i,$motif_length,$alt_pwm_score,$ref_pwm_score,$alt_pfm,$ref_pfm,,$strand,$id,$start) = @_;
	if ($strand eq "+"){
		my $tmp = join("","$name#",$start-29+$i,"#",$start+$i+$motif_length-29, "#$strand#",30-$i);
		print $id,"\t",sprintf('%.3f', $ref_pwm_score),"\t",sprintf('%.3f', $alt_pwm_score),"\t",$ref_pfm,"\t",$alt_pfm,"\t",$tmp,"\n";
	}else{
		my $tmp = join("", "$name#",$start-$motif_length-$i+30,"#",$start-$i+30, "#$strand#",30-$i);
		print $id,"\t",sprintf('%.3f', $ref_pwm_score),"\t",sprintf('%.3f', $alt_pwm_score),"\t",$ref_pfm,"\t",$alt_pfm,"\t",$tmp,"\n";
	}
}
}
	
