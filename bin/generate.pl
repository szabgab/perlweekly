#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Encode       qw(decode);
use File::Slurp  qw(read_file);
use JSON         qw(from_json);
use Template     qw();
use Text::Wrap   qw(wrap);
use XML::RSS     qw();


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
END_USAGE
	exit;
}


my $t = Template->new();

my $data = from_json scalar read_file "src/$issue.json";
$data->{$target} = 1;
$data->{issue} = $issue;

if ($target eq 'rss') {
   generate_rss($data);
} elsif ($target eq 'text') {
   foreach my $h (@{ $data->{header} }) {
     $h = wrap('', '', $h);
   }
   foreach my $ch (@{ $data->{chapters} }) {
      foreach my $e (@{ $ch->{entries} }) {
          $e->{text} = wrap('', '  ', $e->{text});
      }
   }
   $t->process('text.tt', $data);
} else {
   $t->process('page.tt', $data);
}
exit;


sub generate_rss {
    my ($data) = @_;

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
