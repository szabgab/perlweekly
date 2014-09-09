#!/usr/bin/perl 

use 5.12.0;

use strict;
use warnings;

use JSON::Path;
use Path::Tiny qw/ path /;
use URI;
use XML::Feed;

my ( $feeds_file, $week_file ) = map { path($_) } @ARGV;

my $json = $week_file->slurp;

my $jpath = JSON::Path->new('$.chapters[*].entries[*].url');

my @urls = map { URI->new($_) } $jpath->values($json);

my %already_seen;

for ( $feeds_file->lines ) {
	chomp;
	s/\s*#//;
	s/\s.*$//;
	next if /^\s*$/;
	$already_seen{ URI->new($_)->host }++;
}

for my $url (@urls) {
	next if $already_seen{ $url->host };

	for my $feed ( XML::Feed->find_feeds($url) ) {
		warn "adding $feed\n";
		$feeds_file->append("$feed\n");
	}

	$already_seen{ $url->host }++;
}
