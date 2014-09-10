use strict;
use warnings;

# This is a crazy test assuming that the PerlWeekly repo has been fully generated.
# generatting again should leave everything intact.

use Test::More;

my $git = `which git`;
plan skip_all => 'Need git client' if not $git;

plan tests => 2;

my $status_before = `git status`;
diag $status_before;

my $out = `$^X bin/generate.pl web all`;

is $out, '', 'out is empty';

my $status_after = `git status`;
diag $status_after;

is $status_after, $status_before, 'status remained the same';

