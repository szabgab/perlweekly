#!/usr/bin/env perl

use 5.16.0;

use strict;
use warnings;
use Path::Tiny qw(path);
use List::AllUtils qw(before);
use PerlX::Maybe;

my $in_file = shift or die "Usage: $0 src/NNN.mkd\n";
( my $out_file = $in_file ) =~ s/mkd$/json/;

chomp( my @file = path($in_file)->lines );

my $newsletter = {};

$newsletter->{subject} = ( shift @file ) =~ s/^#\s*//r;
$newsletter->{date}    = shift @file;
$newsletter->{editor}  = 'yanick_champoux';

## header stuff
my @headers;

push @headers, shift @file until $file[0] =~ /^##/ or not @file;

$newsletter->{header}
	= [ map {s/\s*\n\s*/ /gr} split "\n\n", join "\n", @headers ];

while (@file) {

	shift @file while $file[0] =~ /^\s*$/;
	my $title = ( shift @file ) =~ s/^##\s*//r;

	# no entry? skip
	my @entries = slurp_entries( \@file )
		or next;

	warn "adding $title\n";

	push @{ $newsletter->{chapters} },
		{
		title   => $title,
		header  => '',
		footer  => '',
		entries => \@entries,
		};

}

sub slurp_entries {
	my $file = shift;

	my @entries;

	while (@$file) {

		shift @$file while @$file and $file->[0] =~ /^\s*$/;

		last if $file->[0] =~ /^##\s+/m;

		my $title = ( shift @$file ) =~ s/^###\s*//r;
		my @meta;
		push @meta, shift @$file until $file->[0] =~ /^\s*$/;

		my ( $link, $date, $author ) = @meta;
		my $date =~ y/-/./;
		$author =~ y/ /_/;
		$author = lc $author;

		shift @$file while @$file and $file->[0] =~ /^\s*$/;

		my $text = '';
		$text .= ' ' . shift @$file
			while @$file
			and $file->[0] !~ /^(?:#|\s*$)/;
		$text =~ s/^\s+|\s+$//g;

		push @entries,
			{
			title        => $title,
			text         => $text,
			url          => $link,
			ts           => $date,
			link         => '',
			tags         => [],
			maybe author => $author,
			};
	}

	my @res = sort { $a->{ts} cmp $b->{ts} } @entries;
	return @res;
}

use JSON::XS;
my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

path($out_file)->spew_utf8( $coder->encode($newsletter) );

__END__



say $coder->encode($x);


