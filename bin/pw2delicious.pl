#!/usr/bin/perl -s
use strict;
use warnings;

use Net::Delicious;
use Path::Tiny;
use JSON qw/ decode_json /;

my ( $w, $p );
my $weekly = decode_json path('src')
	->child( ( $w || die "weekly, dude" ) . '.json' )->slurp;

my $del = Net::Delicious->new(
	{
		user => 'yenzie',
		( pswd => $p || die "password, dude!" ),
		debug => 0,
	}
);

for my $section ( @{ $weekly->{chapters} } ) {
	for my $entry ( @{ $section->{entries} } ) {
		warn "adding ", $entry->{title}, "\n";
		my $post = {
			url         => $entry->{url},
			description => $entry->{title},
			extended    => $entry->{text},
			tags        => join( ',',
				'perlweekly',      "pw$w",
				$section->{title}, @{ $entry->{tags} } ),
			shared  => 1,
			replace => 0,
		};
		$del->add_post($post);
	}
}

