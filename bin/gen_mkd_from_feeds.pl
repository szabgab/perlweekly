#!/usr/bin/env perl

use 5.20.0;

use strict;
use warnings;

use XML::Feed;
use URI;

use DateTime::Functions qw/ now /;
use Path::Tiny;
use File::Serialize;

use experimental 'postderef', 'smartmatch';

my @feeds = map { s/\s.*$//r; }
	grep { /^[^#]/ and not /^\s*$/ } path(shift)->lines( { chomp => 1 } );

my $cutout_date = now();
$cutout_date->subtract( days => 1 ) until $cutout_date->day_of_week == 1;

my $target = path(shift);

my @in_archive;
# read all the past entries and collect the urls
for my $archive ( grep { $_->basename =~ /^\d+\.json/ } path('src')->children ) {
    my $pw = deserialize_file $archive;
    push @in_archive, map { $_->{url} } map { $_->{entries}->@* } $pw->{chapters}->@*;
}

my %seen;

%seen = map { $_ => 1 } grep {/^http/} $target->lines( { chomp => 1 } );

my @entries = sort { $a->issued <=> $b->issued }
    grep { !( $_->link ~~ @in_archive ) or do { warn $_->link, " seen in archive"; 0 } }
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
