use strict;
use warnings;

use Test::More;

my @exes = glob "bin/*";

plan tests => 1 + @exes;
foreach my $exe (@exes) {
	my $T = Test::More->builder;
	if ($^V < 'v5.20.0') {
		if ($exe =~ /gen_mkd_from_feeds.pl/) {
			$T->skip("$exe needs 5.20.0 or higher", 1);
			next;
		}
	}

	if ($^V < 'v5.16.0') {
		if ($exe =~ /mkd2json.pl/) {
			$T->skip("$exe needs 5.20.0 or higher", 1);
			next;
		}
	}

	if ($^V < 'v5.12.0') {
		if ($exe =~ /discover_from_week.pl/) {
			$T->skip("$exe needs 5.20.0 or higher", 1);
			next;
		}
	}

	is system("$^X -c $exe"), 0, $exe;
}
ok 1;

