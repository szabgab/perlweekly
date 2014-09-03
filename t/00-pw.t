use strict;
use warnings;

use Test::More;

# skipping one that needs 5.16 ?
# really?
my @exes = grep { ! /mkd2json.pl/ } glob "bin/*";

plan tests => 1 + @exes;
foreach my $exe (@exes) {
	my $T = Test::More->builder;
	if ($^V < 'v5.20.0') {
		if ($exe =~ /gen_mkd_from_feeds.pl/) {
			$T->skip("$exe needs 5.20.0 or higher", 1);
			next;
		}
	}
	is system("$^X -c $exe"), 0, $exe;
}
ok 1;

