#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use MIME::Lite::HTML;
use MIME::Lite;

my $to   = 'gabor@perl.org.il';  
my $from = 'gabor@szabgab.com';

my $issue = 'next';

my $subject = 'The current Perl Weekly News - Issue #' . $issue;
my $host = 'szabgab.com';
my $url  = "http://perlweekly.com/archive/$issue.html";

my $msg = MIME::Lite::HTML->new(
#my $msg = MIME::Lite->new(
	From     => $to,
	To       => $to,
	Url      => $url,
	Subject  => $subject,
#	Data     => 'Content',
);


#print "prepared\n";
#$msg->send('smtp', $host, Debug => 1, Timeout => 5);
#$msg->send;
