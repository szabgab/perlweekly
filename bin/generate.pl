#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Template;
use YAML qw(LoadFile);
use JSON qw(from_json);
use File::Slurp qw(read_file);

my $target = shift;
if (not $target or $target !~ /^(mail|web)$/) {
	print <<"END_USAGE";
Usage: $0 
   web
   mail
END_USAGE
	exit;
}


my $t = Template->new();

my $data = from_json scalar read_file 'src/1.json';
#my $yaml = 'src/1.yml';
#my $data = LoadFile($yaml);
#print Dumper $data;
#print to_json $data, { utf8 => 1, pretty => 1 };
$data->{$target} = 1;

$t->process('page.tt', $data);
