#!/usr/bin/env perl
use strict;
use warnings;

use Email::SendGrid::V3;

my $api_key = get_api_key();
sendmail($api_key);

sub get_api_key {
    my $config_file = 'config.txt';
    open my $fh, '<', $config_file or die;
    my $api_key = <$fh>;
    chomp $api_key;
    close $fh;
    return $api_key;
}

sub sendmail {
    my ($api_key) = @_;

    my $sg = Email::SendGrid::V3->new(api_key => $api_key);
    my $result = $sg->from('gabor@szabgab.com')
                    ->subject('A test message for you')
                    ->add_content('text/plain', 'This is a test message sent with SendGrid')
                    ->add_envelope( to => [ 'szabgab@gmail.com' ] )
                    ->send;
    print $result->{success} ? "It worked" : "It failed: " . $result->{reason};
}

