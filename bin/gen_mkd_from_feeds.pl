#!/usr/bin/env perl

use 5.20.0;

use strict;
use warnings;

use XML::Feed;
use URI;

use DateTime::Functions qw/ now /;

my @feeds = map { s/\s.*$//r; } grep { /^[^#]/ and not /^\s*$/ } <>;
chomp @feeds;

my $cutout_date = now();
$cutout_date->subtract( days => 1) until $cutout_date->day_of_week == 1;

my %seen;
my @entries = sort { $a->issued <=> $b->issued } 
              grep { not $seen{ $_->link }++ }
              grep { $_->issued >= $cutout_date } 
              map { $_->entries } 
              map { XML::Feed->parse( URI->new($_) ) }
              @feeds; 

for my $entry ( @entries ) {
    say '### ', $entry->title;
    say $entry->link;
    say eval { $entry->issued->ymd } || '????-??-??';
    say "\n", $entry->author, "\n";
}
