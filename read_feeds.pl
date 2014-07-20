#!/usr/bin/env perl

use 5.12.0;

use strict;
use warnings;

use XML::Feed;
use URI;

use DateTime::Functions qw/ now /;

my @feeds = grep { /^[^#]/ and not /^\s*$/ } <>;
chomp @feeds;

my $aggregate = XML::Feed->new;

for my $url ( @feeds ) {
    my $feed = XML::Feed->parse( URI->new($url) );
    $aggregate->splice($feed);
}

my $cutout_date = now();
$cutout_date->subtract( days => 1) until $cutout_date->day_of_week == 1;

my @entries = grep { $_->issued >= $cutout_date } sort { $a->issued <=> $b->issued } $aggregate->entries;

for my $entry ( @entries ) {
    say '### ', $entry->title;
    say $entry->link;
    say eval { $entry->issued->ymd } || '????-??-??';
    say "\n", $entry->author, "\n";
}






