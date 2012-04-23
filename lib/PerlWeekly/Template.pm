package PerlWeekly::Template;
use strict;
use warnings;
use base 'Template';

sub process {
	my ($self, $template, $params, $outfile) = @_;
	print "$outfile\n";
	my $result;
    $self->SUPER::process($template, $params, \$result) or return;
	$result =~ s/\x{D}\x{A}/\x{A}/g;
	open my $fh, '>:encoding(UTF-8)', $outfile or die $!;
	print $fh $result;
	close $fh;

	return 1;
}

1;
