use strict;
use warnings;

# This is a crazy test assuming that the PerlWeekly repo has been fully generated.
# generatting again should leave everything intact.

use Test::More;

my $git = qx{which git};

my $status_before = $git ? qx{git status} : '';
diag $status_before;

my $out = qx{$^X bin/generate.pl web all};

is $out, '', 'out is empty';

my $status_after = $git ? qx{git status} : '';
diag $status_after;

# Need git client and not to be a in Pull-Request where the content might change
if ( $git and not $ENV{TRAVIS_PULL_REQUEST_SHA} ) {
	is $status_after, $status_before, 'status remained the same';
	diag qx{git diff};
}
done_testing();
