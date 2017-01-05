#!/usr/bin/perl -T
use strict;
use warnings;

use CGI;
use Email::Valid;
use LWP::Simple qw(get);

my $q = CGI->new;
print $q->header;
my $email = $q->param('email');

if (not $email) {
	warn "No e-mail given";
} elsif (Email::Valid->address($email)) {
	get("https://mail.perlweekly.com/mailman/subscribe/perlweekly?email=$email");
} else {
	warn "Invalid e-mail '$email'";
}

print "OK";

