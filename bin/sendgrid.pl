#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Encode;

use Getopt::Long qw(GetOptions);
use Email::SendGrid::V3;
use JSON qw(from_json);
use Path::Tiny qw(path);
use Data::Dumper qw(Dumper);

my $sent_file = 'sent.json';

main();

sub get_sent {
    return {} if not -e $sent_file;

    open my $fh, '<', $sent_file or die "Could not open '$sent_file' for reading $!";
    local $/ = undef;
    return from_json scalar <$fh>;
}

sub save {
    my ($sent) = @_;

    open my $fh, '>', $sent_file or die "Could not open '$sent_file' for writing $!";
    my $json = JSON->new->allow_nonref;
    print $fh $json->pretty->encode($sent);
}

sub main {
    binmode( STDOUT, ":encoding(UTF-8)" );
    binmode( STDERR, ":encoding(UTF-8)" );
    my $sent = get_sent();

    my %opt;
    GetOptions( \%opt, 'to=s', 'tofile=s', 'issue=i', 'limit=i') or die;
    die "Usage: $0 --to mail\@address.com --tofile addresses.txt  --issue N --limit N\n"
	if ((not $opt{to} and not $opt{tofile}) or not $opt{issue});

    my $html = Encode::decode_utf8 qx{$^X bin/generate.pl mail $opt{issue}};
    my $text = Encode::decode_utf8 qx{$^X bin/generate.pl text $opt{issue}};

    my $data = from_json scalar( path("src/$opt{issue}.json")->slurp_utf8 );
    my $subject = "[Perlweekly] #$opt{issue} - $data->{subject}";

    my $editors = from_json scalar( path("src/authors.json")->slurp_utf8 );

    #die $data->{editor};
    #die Dumper $editors;
    die "Editor '$data->{editor}' not found.\n"
    	if not $editors->{ $data->{editor} };

    my $from = "$editors->{gabor_szabo}{name} <$editors->{gabor_szabo}{from}>";

    my $api_key = get_api_key();

    #print($html);
    #print($text);
    #exit();
    if ($opt{to}) {
        my $result = sendmail($api_key, $opt{to}, $from, $subject, $html, $text);
	    say $result->{success}
		? "It worked"
		: "It failed: " . $result->{reason};
        return
    }
    if ($opt{tofile}) {
        # read file and send email to each address
        open my $fh, '<', $opt{tofile} or die "Could not open '$opt{tofile}' $!";
        while (my $row = <$fh>) {
            chomp $row;
            next if $row =~ /^\s*(#.*)?$/;
            my ($name, $to) = split_row($row);
            next if $sent->{$to};

            if (defined $opt{limit}) {
                $opt{limit}--;
                if ($opt{limit} < 0) {
                    last;
                }
            }

            # returns a plain hash
            my $result = sendmail($api_key, $name, $to, $from, $subject, $html, $text);
            #say Dumper $result;
            $sent->{$to} = {
                success => $result->{success},
                reason  => $result->{reason},
                content => $result->{content},
                status => $result->{status},
            };

            save($sent);
	        say $result->{success}
		    ? "  It worked"
		    : "  It failed: $result->{reason}";
        }
    }
}

sub split_row {
    my ($row) = @_;
    if ($row =~ /</) {
        if ($row =~ /^\s*(.*?)\s*<([^<>]+)>\s*$/) {
            return $1, $2;
        } else {
            warn "No matching in $row";
            return;
        }
    }
    return "", $row;
}

sub get_api_key {
	my $config_file = 'config.txt';
	open my $fh, '<', $config_file or die;
	my $row = <$fh>;
	chomp $row;
	close $fh;
    my ($var, $api_key) = split /=/, $row;
	return $api_key;
}

sub sendmail {
	my ($api_key, $name, $to, $from, $subject, $html, $text) = @_;
    say "Sending to '$to'     ($name)";
    #return;

    # ->reply_to
	my $sg = Email::SendGrid::V3->new( api_key => $api_key );
	my $result
		= $sg->from($from)
        ->subject($subject)
		->add_content( 'text/plain', $text )
		->add_content( 'text/html', $html )
		->add_envelope( to => [$to] )
        ->send;
	return $result;
}

# This is how the sendmail code works:
# perl bin/sendmail.pl --issue 560 --to gabor@szabgab.com
# perl bin/sendmail.pl --issue 560 --to perlweekly@perlweekly.com


# This is the plan:
# perl bin/sendgrid.pl --issue 560 --to gabor@szabgab.com
# perl bin/sendgrid.pl --issue 560 --tofile emails.txt

