use strict;
use warnings;

# checking the format of the jobs.json file
use Test::More tests => 1;
use JSON qw(from_json);
use Path::Tiny qw(path);

eval { my $jobs = from_json scalar path("src/jobs.json")->slurp_utf8; };
is $@, '', 'jobs.json';

