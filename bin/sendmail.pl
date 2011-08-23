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
my $text = qx{$^X bin/generate.pl text $opt{issue}};

my $msg = MIME::Lite->new(
	From     => $from,
	To       => $opt{to},
	Type     => 'multipart/alternative',
	Subject  => $subject,
	#Data     => $text,
);

my $text_msg = MIME::Lite->new(
	Type     => 'text',
	Data     => $text,
	Encoding => 'quoted-printable',
);
$text_msg->attr("content-type" => "text/plain; charset=UTF-8");
#$text_msg->replace("MIME-Version" => "");
$text_msg->replace("X-Mailer" => "");
#$text_msg->replace("Content-Disposition" => "");
$text_msg->attr('mime-version' => '');
$text_msg->attr('Content-Disposition' => '');
#$text_msg->attr('content-type.charset' => 'UTF-8');

my $html_msg = MIME::Lite->new(
	Type     => 'text',
	Data     => $html,
	Encoding => 'quoted-printable',
);
$html_msg->attr("content-type" => "text/html; charset=UTF-8");
#$html_msg->replace("MIME-Version" => "");
$html_msg->replace("X-Mailer" => "");
#$html_msg->replace("Content-Disposition" => "");
$html_msg->attr('mime-version' => '');
$html_msg->attr('Content-Disposition' => '');




$msg->attach($text_msg);
$msg->attach($html_msg);


$msg->send;

