#!/usr/bin/perl
use strict;
use warnings;

use autodie;

use Encode         qw(decode);
use File::Basename qw(basename);
use File::Slurp    qw(read_file);
use JSON           qw(from_json);
use List::Util     qw(max);
use Template       qw();
use Text::Wrap     qw(wrap);
use XML::RSS       qw();


my ($target, $issue) = @ARGV;
if (not $target
    or not $issue
    or $target !~ /^(mail|text|web|rss)$/
    or not $issue) {
    warn <<"END_USAGE";
Usage: $0
   web   ISSUE
   mail  ISSUE          an html version to be sent by e-mail
   text  ISSUE          a text version to be sent by e-mail
   rss   ISSUE          (no output)

   ISSUE is a number or the word sources

   or we can also write

   web all

END_USAGE
    exit;
}

my $count = 0;
if (open my $fh, '<', 'src/count.txt') {
	$count = <$fh>;
	close $fh;
}


if ($target eq 'web' and $issue eq 'all') {
    my (@issues, $last);
    my ($max) = max grep { /^\d+$/ } map {substr(basename($_), 0, -5)} glob 'src/*.json';
    foreach my $i (1 .. $max) {
        my $issue = PerlWeekly::Issue->new($i);
        open my $fh, '>', "html/archive/$i.html";
        $issue->generate($target, $fh);
        push @issues, $issue;
        $last = $issue;
    }
    $last->generate('rss');

    my $next = PerlWeekly::Issue->new('next');
    my $t = Template->new();
    $t->process('tt/archive.tt', {issues => \@issues}, 'html/archive/index.html') or die $t->error;
    $t->process('tt/index.tt',  { latest => $max, next_issue => $next->{date}, count => $count }, 'html/index.html') or die $t->error;
    my $events = from_json scalar read_file "src/events.json";
    $t->process('tt/events.tt', { events => $events->{entries} }, 'html/events.html') or die $t->error;
    foreach my $f (qw(thankyou unsubscribe promotion)) {
          $t->process("tt/$f.tt", {}, "html/$f.html") or die $t->error;
    }
} else {
    PerlWeekly::Issue->new($issue)->generate($target);
}

exit;

package PerlWeekly::Issue;

sub new {
    my $class = shift;
    my ( $issue ) = @_;

    my $self = from_json scalar read_file "src/$issue.json";
    bless $self, $class;

    $self->{$target} = 1;
    $self->{issue}  = $issue;
    $self->{number} = $issue;
    my $sep = $self->{title} ? ' - ' : '';
    $self->{title} = "Issue #$issue - $self->{date}$sep$self->{title}";

    return $self;
}

sub generate {
    my $self = shift;
    my $target = shift;
    my @out = @_ ? shift : ();
    return (
        $target eq 'web'  ? $self                        ->process_tt('tt/page.tt', @out) :
        $target eq 'mail' ? $self->fixup_links           ->process_tt('tt/page.tt', @out) :
        $target eq 'text' ? $self->fixup_links->wrap_text->process_tt('tt/text.tt', @out) :
        $target eq 'rss'  ? $self->process_rss :
        die "Unknown target '$target'\n";
    );
}

sub fixup_links {
    my $self = shift;
    foreach my $ch (@{ $self->{chapters} }) {
       foreach my $e (@{ $ch->{entries} }) {
          $e->{url} = $e->{link} || $e->{url};
       }
    }
    return $self;
}

sub wrap_text {
    my $self = shift;
    foreach my $h (@{ $self->{header} }) {
        $h = wrap('', '', $h);
    }
    foreach my $ch (@{ $self->{chapters} }) {
        foreach my $e (@{ $ch->{entries} }) {
            $e->{text} = wrap('', '  ', $e->{text});
        }
    }
    return $self;
}

sub process_tt {
    my $self = shift;
    my $tmpl = shift;
    my $t = Template->new();
    $t->process($tmpl, $self, @_) or die $t->error;
}

sub process_rss {
    my $self = shift;

    my $url = 'http://perlweekly.com/';
    my $rss = XML::RSS->new( version => '1.0' );
    my $year = 1900 + (localtime)[5];
    $rss->channel(
        title       => 'Perl Weekly newsletter',
        link        => $url,
        description => 'A free, once a week e-mail round-up of hand-picked news and articles about Perl.',
        dc => {
            language  => 'en-us',
            publisher => 'szabgab@gmail.com',
            rights    => "Copyright 2011-$year, Gabor Szabo",
        },
        syn => {
            updatePeriod     => "weekly",
            updateFrequency  => "1",
            updateBase       => "2011-08-01T00:00+00:00",
        }
    );

#    $self->{title};
#    $self->{header};
    foreach my $ch (@{ $self->{chapters} }) {
        #$ch->{title}
        foreach my $e (@{ $ch->{entries} }) {
            my $text = $e->{text};
            $rss->add_item(
                title => decode('utf-8', $e->{title}),
                link  => $e->{url},
                description => decode('utf-8', $e->{text}),
                #dc => {
                #    creator => '???', # TODO should be the author of the original article
                #    date    => POSIX::strftime("%Y-%m-%dT%H:%M:%S+00:00", localtime $e->{timestamp},
                #    subject => 'list of tags?',
            );
        }
    }

    #rss_item_count();
    $rss->save( 'html/perlweekly.rss' );
    return;
    #return $rss->as_string;
}
