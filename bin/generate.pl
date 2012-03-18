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
   rss   ISSUE

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


if ($target eq 'rss') {
    generate_rss(get_data($issue));
} else {
    if ($target eq 'web' and $issue eq 'all') {
        my (@issues, $last);
        my ($max) = max grep { /^\d+$/ } map {substr(basename($_), 0, -5)} glob 'src/*.json';
        foreach my $i (1 .. $max) {
            my $data = get_data($i);
            open my $fh, '>', "html/archive/$i.html";
            print $fh generate($data);
            push @issues, {
                number => $i,
                date   => $data->{date},
            };
            $last = $data;
        }
        generate_rss($last);

        my $next = get_data('next');
        my $t = Template->new();
        $t->process('tt/archive.tt', {issues => \@issues}, 'html/archive/index.html') or die $t->error;
        $t->process('tt/index.tt',  { latest => $max, next_issue => $next->{date}, count => $count }, 'html/index.html') or die $t->error;
        my $events = from_json scalar read_file "src/events.json";
        $t->process('tt/events.tt', { events => $events->{entries} }, 'html/events.html') or die $t->error;
        foreach my $f (qw(thankyou unsubscribe promotion)) {
              $t->process("tt/$f.tt", {}, "html/$f.html") or die $t->error;
        }
    } else {
        print generate($issue);
    }
}

exit;

sub get_data {
    my $issue = shift;

    my $data = from_json scalar read_file "src/$issue.json";
    $data->{$target} = 1;
    $data->{issue} = $issue;
    my $sep = $data->{title} ? ' - ' : '';
    $data->{title} = "Issue #$issue - $data->{date}$sep$data->{title}";


    return $data;
}

sub generate {
    my $data = shift;

    my $t = Template->new();

    if ($target eq 'mail' or $target eq 'text') {
        foreach my $ch (@{ $data->{chapters} }) {
           foreach my $e (@{ $ch->{entries} }) {
              $e->{url} = $e->{link} || $e->{url};
           }
        }
    }

    if ($target eq 'text') {
       foreach my $h (@{ $data->{header} }) {
         $h = wrap('', '', $h);
       }
       foreach my $ch (@{ $data->{chapters} }) {
          foreach my $e (@{ $ch->{entries} }) {
              $e->{text} = wrap('', '  ', $e->{text});
          }
       }
    }

    my $tmpl = $target eq 'text' ? 'tt/text.tt' : 'tt/page.tt';
    $t->process($tmpl, $data, \my $out) or die $t->error;
    return $out;
}



sub generate_rss {
    my $data = shift;

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

#    $data->{title};
#    $data->{header};
    foreach my $ch (@{ $data->{chapters} }) {
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
