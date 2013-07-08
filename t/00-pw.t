use strict;
use warnings;

use Test::More;

# skipping one that needs 5.16 ?
# really?
my @exes = grep { ! /mkd2json.pl/ } glob "bin/*";

plan tests => 1 + @exes;
foreach my $exe (@exes) {
	is system("$^X -c $exe"), 0, $exe;
}
ok 1;

