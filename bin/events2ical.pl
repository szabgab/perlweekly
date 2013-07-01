#!/usr/bin/perl 

use strict;
use warnings;

use Data::Printer;
use Path::Tiny;
use Data::ICal;
use Data::ICal::Entry::Event;
use DateTime::Format::ICal;
use DateTime::Functions qw/ now /;

my ( undef, @events ) = 
    path( 'events/events.mkd' )->slurp =~ /^##(.*?)(?=##|\Z)/msg;

my $calendar = Data::ICal->new;

for my $e ( @events ) {
    my( $title, $url, $time, $location, undef, $desc ) = split /\n/, $e, 6;

    my( $begin, $end ) = split /\s+-\s+/, $time;
    for( $begin, $end ) {
        next unless $_;

        /(\d+)-(\d+)-(\d+)/ or die "$_ looks weird";

        my $date = DateTime->new( year => $1, month => $2, day => $3 );
        if( $date->compare( now() ) <= 0 ) {
            warn "$title already happened, skipping";
            next;
        }

        $_ = $date;
    }

    my $event = Data::ICal::Entry::Event->new;
    $event->add_properties(
        summary => $title,
        description => join( "\n\n", $url, $desc ),
        dtstart => DateTime::Format::ICal->format_datetime($begin),
        location => $location,
        $end ? ( dtend => DateTime::Format::ICal->format_datetime($end) ) : ( duration => 'PT24H0M0S' )
    );

    $calendar->add_entry($event);
}

print $calendar->as_string;

