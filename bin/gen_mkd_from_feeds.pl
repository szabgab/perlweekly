#!/usr/bin/env perl

use 5.20.0;

use strict;
use warnings;

use XML::Feed;
use URI;

use DateTime::Functions qw/ now /;
use Path::Tiny;

my @feeds = map { s/\s.*$//r; }
	grep { /^[^#]/ and not /^\s*$/ } path(shift)->lines( { chomp => 1 } );

my $cutout_date = now();
$cutout_date->subtract( days => 1 ) until $cutout_date->day_of_week == 1;

my $target = path(shift);

my %seen;

%seen = map { $_ => 1 } grep {/^http/} $target->lines( { chomp => 1 } );

my @entries = sort { $a->issued <=> $b->issued }
	grep { not $seen{ $_->link }++ }
	grep { $_->issued >= $cutout_date }
	map  { $_->entries }
	map  { XML::Feed->parse( URI->new($_) ) } @feeds;

for my $entry (@entries) {
	$target->append(
		join "\n", '### ' . $entry->title,
		$entry->link, eval { $entry->issued->ymd } || '????-??-??',
		$entry->author, "\n\n",
	);
}
