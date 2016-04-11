#!/usr/bin/perl

=head1 NAME

jmlib

=head1 SYNOPSIS
   
=head1 DESCRIPTION

This modules contains some generic functions used across jmtools.

=head2 Methods
=over 12

#=item C<getDBConnectionString>
#=cut
#sub getDBConnectionString
#{
#	return 'DBI:mysql:fratools:10.217.28.55';
#}
#
#=item C<getDBUser>
#=cut
#sub getDBUser
#{
#	return 'fratools';
#}
#
#=item C<getDBUserPassword>
#=cut
#sub getDBUserPassword
#{
#	return '4r15707l3';
#}

=item C<isFasta>
Arguments: file-name
Returns true if file is a fasta file
=cut
sub isFasta
{
	my $file = shift;
	
	my($name, $path, $ext) = fileparse($file, '\..*');
	
	if($ext eq 'fa')
	{
		return 0;
	}
	
	open(INPUT, $file) || die "Cannot open $file";
	$_ = <INPUT>;
	close(INPUT);
	
	s/\r?\n?$//;
	
	my @line = split(//,$_);
	if($line[0] eq '>')
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

return 1;
