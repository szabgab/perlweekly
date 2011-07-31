#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Template;
use JSON qw(from_json);
use File::Slurp qw(read_file);

my ($target, $issue) = @ARGV;
if (not $target
	or not $issue
	or $target !~ /^(mail|web)$/
	or $issue =~ /\D/) {
	warn <<"END_USAGE";
Usage: $0 
   web   ISSUE 
   mail  ISSUE
   
   ISSUE is a number
END_USAGE
	exit;
}


my $t = Template->new();

my $data = from_json scalar read_file "src/$issue.json";
$data->{$target} = 1;
$data->{issue} = $issue;

$t->process('page.tt', $data);
