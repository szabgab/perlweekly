package PerlWeekly::Template;
use strict;
use warnings;
use base 'Template';

use Carp;

sub process {
	my ( $self, $template, $params, $outfile ) = @_;

	#	Carp::confess('undef') if not defined $outfile;
	#	print "$outfile\n";
	my $result;
	$self->SUPER::process( $template, $params, \$result ) or return;
	$result =~ s/\x{D}\x{A}/\x{A}/g;
	if ($outfile) {
		open my $fh, '>:encoding(UTF-8)', $outfile or die $!;
		print $fh $result;
		close $fh;
	}
	else {
		print $result;
	}
	return 1;
}

1;
