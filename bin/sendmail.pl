#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use MIME::Lite;
use Cwd qw(abs_path cwd);
use Data::Dumper qw(Dumper);
use Path::Tiny qw(path);
use JSON qw(from_json);
use Encode qw(decode encode);

my %opt = ( smtp => 'localhost', );
GetOptions( \%opt, 'to=s', 'issue=i', 'smtp=s' ) or die;
die "Usage: $0 --to mail\@address.com  --issue N [--smtp server]\n"
	if not $opt{to}
	or not $opt{issue};

my $subject = 'The current Perl Weekly News - Issue #' . $opt{issue};

my $host = 'szabgab.com';
my %content;
$content{html} = qx{$^X bin/generate.pl mail $opt{issue}};
$content{text} = qx{$^X bin/generate.pl text $opt{issue}};
my $data = from_json scalar( path("src/$opt{issue}.json")->slurp_utf8 );
if ( $data->{subject} ) {
	$subject = "#$opt{issue} - $data->{subject}";
}

my $editors = from_json scalar( path("src/editors.json")->slurp_utf8 );

#die $data->{editor};
#die Dumper $editors;

my $from
	= "$editors->{ $data->{editor} }{name} <$editors->{ $data->{editor} }{from}>";

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

$msg->send( 'smtp', $opt{smtp} );

