#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use MIME::Lite::HTML;
use MIME::Lite;
use Cwd qw(abs_path cwd);

my %opt;
GetOptions(\%opt,
	'to=s',
	'issue=i',
	'subject=s',
) or die;
die "Usage: $0 --to mail\@address.com  --issue N --subject SUBJECT\n" if not $opt{to} or not $opt{issue};

my $from = 'Gabor Szabo <gabor@szabgab.com>';

my $subject = 'The current Perl Weekly News - Issue #' . $opt{issue};
if ($opt{subject}) {
	$subject .= " - $opt{subject}";
}

my $host = 'szabgab.com';
my $html = qx{$^X bin/generate.pl mail $opt{issue}};

my $msg = MIME::Lite->new(
	From     => $from,
	To       => $opt{to},
	Type     => 'text/html',
	Subject  => $subject,
	Data     => $html,
);

$msg->attr('content-type.charset' => 'UTF-8');

$msg->send;
