#!/usr/bin/perl -w
use strict;

unless($ARGV[2]){
print <<EOF;
        perl 3.gencode.process.pl GENCODE_annotation(gtf format) version_number distance_to_define_promoter
	e.g. perl gencode.process.pl gencode.v16.annotation.gtf v16 2500
EOF
exit;	
}

$| =1 ;


my $gencode_file = $ARGV[0];
my $version =  $ARGV[1];
my $promoter_cut = $ARGV[2];
my $promoter_file = "gencode.$version.promoter.bed";
my $cds_file = "gencode.$version.cds.bed";
my $exon_file = "gencode.$version.exon.bed";
my $intron_file = "gencode.$version.intron.bed";
my $utr_file = "gencode.$version.utr.bed";

`awk '\$3 == "CDS"' $gencode_file | grep 'gene_type "protein_coding"' | grep 'transcript_type "protein_coding"' | awk '{OFS="\t"}{print \$1,\$4-1,\$5,\$18}'|sed 's/["|;]//g' > $cds_file`;

`awk '\$3 == "transcript"' $gencode_file | grep -e 'gene_type "protein_coding"' -e 'gene_type "polymorphic_pseudogene"' | grep -e 'transcript_type "protein_coding"' | awk '{OFS="\t"}{if (\$7 == "+") print \$1,\$4-$promoter_cut-1,\$4-1,\$18;else if (\$7 == "-") print \$1,\$5,\$5+$promoter_cut,\$18}'|sed 's/["|;]//g' > $promoter_file`;

`awk '\$3=="exon"' $gencode_file | grep 'gene_type "protein_coding"' | grep 'transcript_type "protein_coding"'| awk '{OFS="\t"}{print \$1,\$4-1,\$5}' > $exon_file`;

`awk '\$3 == "gene"' $gencode_file | grep 'gene_type "protein_coding"' | grep 'transcript_type "protein_coding"' | awk '{OFS="\t"}{print \$1,\$4-1,\$5,\$18}' |sed 's/["|;]//g'|subtractBed -a stdin -b $exon_file > $intron_file`;

`awk '\$3=="UTR"' $gencode_file | grep 'gene_type "protein_coding"' | grep 'transcript_type "protein_coding"'| awk '{OFS="\t"}{print \$1,\$4-1,\$5,\$18}'| sed 's/["|;]//g' > $utr_file`;

unlink($exon_file);
