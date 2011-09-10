#!/usr/bin/perl -T
use strict;
use warnings;

use lib '/home/gabor/perl5/local/lib/perl5',
        '/home/gabor/perl5/local/lib/perl5/x86_64-linux-gnu-thread-multi';

use CGI;
use Email::Valid;
use LWP::Simple qw(get);

my $q = CGI->new;
print $q->header;
my $email = $q->param('email');

if (not $email) {
	warn "No e-mail given" if not $email;
} elsif (Email::Valid->address($email)) {
	get("http://mail.perlweekly.com/mailman/subscribe/perlweekly?email=$email");
} else {
	warn "Invalid e-mail '$email'";
}

print "OK";

