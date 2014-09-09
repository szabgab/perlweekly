#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use MIME::Lite;
use Cwd qw(abs_path cwd);
use File::Slurp qw(read_file);
use JSON qw(from_json);
use Encode qw(decode encode);

my %opt;
GetOptions( \%opt, 'to=s', 'issue=i', ) or die;
die "Usage: $0 --to mail\@address.com  --issue N\n"
	if not $opt{to}
	or not $opt{issue};

my $from = 'Gabor Szabo <gabor@szabgab.com>';

#my $from = 'Yanick Champoux <yanick@babyl.ca>';

my $subject = 'The current Perl Weekly News - Issue #' . $opt{issue};

my $host = 'szabgab.com';
my %content;
$content{html} = qx{$^X bin/generate.pl mail $opt{issue}};
$content{text} = qx{$^X bin/generate.pl text $opt{issue}};
my $data = from_json scalar( read_file "src/$opt{issue}.json" ),
	binmode => 'utf8';
if ( $data->{subject} ) {
	$subject = "#$opt{issue} - $data->{subject}";
}

my $msg = MIME::Lite->new(
	From    => $from,
	To      => $opt{to},
	Type    => 'multipart/alternative',
	Subject => decode( 'utf-8', $subject ),    # worked on #118
	                                           #Data     => $text,
);

my %type = (
	text => 'text/plain',
	html => 'text/html',
);

foreach my $t (qw(text html)) {
	my $att = MIME::Lite->new(
		Type     => 'text',
		Data     => $content{$t},
		Encoding => 'quoted-printable',
	);
	$att->attr( "content-type" => "$type{$t}; charset=UTF-8" );
	$att->replace( "X-Mailer" => "" );
	$att->attr( 'mime-version'        => '' );
	$att->attr( 'Content-Disposition' => '' );

	$msg->attach($att);
}

$msg->send( 'smtp', 'localhost' );

