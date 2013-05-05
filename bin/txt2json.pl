#!/usr/bin/perl 

use 5.16.0;

use strict;
use warnings;
use Path::Tiny;

chomp(my @file = path(shift)->lines);

my $newsletter = {};

$newsletter->{subject} = (shift @file) =~ s/^#\s*//r;
$newsletter->{date} = shift @file;

while( @file ) {

    shift @file while $file[0] =~ /^\s*$/;
    my $title = (shift @file) =~ s/^##\s*//r;

    # no entry? skip
    my @entries = slurp_entries(\@file)
        or next;

    push @{$newsletter->{chapters}}, {
        title => $title,
        header => '',
        footer => '',
        entries => \@entries,
    };


}

sub slurp_entries {
    my $file = shift;

    my @entries;

    while( @$file ) {
        $DB::single = $file->[0] =~ /#/;

        shift @$file while @$file and $file->[0] =~ /^\s*$/;

        last if $file->[0] =~ /^##\s+/m;

        my $title = (shift @$file) =~ s/^###\s*//r;
        my $link = shift @$file;
        my $date = shift @$file;
        shift @$file;

        my $text;
        $text .= shift @$file while $file->[0] !~ /^\s*$/;

        push @entries, {
            title => $title,
            text => $text,
            url => $link,
            ts => $date,
            link => '',
            tags => [],
        };
    }

    return sort { $a->{ts} cmp $b->{ts} } @entries;
}

use JSON::XS;
my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

say $coder->encode($newsletter);

__END__



say $coder->encode($x);


