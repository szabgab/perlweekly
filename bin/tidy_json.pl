#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use JSON qw/ from_json to_json /;
use Path::Tiny qw/ path /;
use Encode qw/ encode decode /;

main();

sub main {
	foreach my $file ( glob "src/*.json" ) {
		next if $file !~ m{/\d+.json$};
		tidy($file);
	}
	foreach my $file ( "src/authors.json" ) {
		tidy($file);
	}
}

sub tidy {
	my ($file) = @_;
	say $file;

	my $src_json = encode( 'utf-8', scalar path($file)->slurp_utf8 );
	my $data = from_json( $src_json, { utf8 => 1 } );
	path($file)->spew_utf8(
		decode(
			'utf-8',
			to_json( $data, { utf8 => 1, pretty => 1, canonical => 1 } )
		)
	);
}
