#!/usr/bin/perl
use strict;
use warnings;

use autodie;

use Cwd            qw(abs_path);
use File::Basename qw(basename dirname);
use File::Slurp    qw(read_file);
use JSON           qw(from_json);
use List::Util     qw(max);

use lib dirname(dirname abs_path($0)) . '/lib';
use PerlWeekly::Template       qw();
use PerlWeekly::Issue;

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
        my $issue = PerlWeekly::Issue->new($i, $target);
        $issue->{latest} = $max;
        $issue->generate($target, "html/archive/$i.html");
        push @issues, $issue;
        $last = $issue;
    }
    $last->generate('rss');

    $last->generate($target, "html/latest.html");

    my $next = PerlWeekly::Issue->new('next', $target);
    my $t = PerlWeekly::Template->new();
    $t->process('tt/archive.tt', {issues => \@issues}, 'html/archive/index.html') or die $t->error;

    $t->process('tt/all.tt', {issues => \@issues}, 'html/all.html') or die $t->error;

    @issues = reverse @issues;
    $t->process('tt/archive.tt', {issues => \@issues, reverse => 1}, 'html/archive/reverse.html') or die $t->error;


    $t->process('tt/index.tt',  { latest => $max, next_issue => $next->{date}, count => $count }, 'html/index.html') or die $t->error;
    my $events = from_json scalar read_file "src/events.json", binmode => 'utf8';
    $t->process('tt/events.tt', { events => $events->{entries} }, 'html/events.html') or die $t->error;
    foreach my $f (qw(thankyou unsubscribe promotion)) {
          $t->process("tt/$f.tt", {}, "html/$f.html") or die $t->error;
    }
} else {
    PerlWeekly::Issue->new($issue, $target)->generate($target, "html/archive/$issue.html");
	print "done\n";
}

exit;


