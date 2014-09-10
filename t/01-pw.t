use strict;
use warnings;

use Test::More tests => 2;

use PerlWeekly::Issue;

subtest one => sub {
	my $issue  = '1';
	my $target = 'web';

	my $pw = PerlWeekly::Issue->new( $issue, $target );
	isa_ok $pw, 'PerlWeekly::Issue';

	#->generate($target);
};

subtest bad => sub {
	eval { PerlWeekly::Issue->new( 1000, 'web' ); };
	my $err = $@;
	is $err, qq{File 'src/1000.json' does not exist.\n};

	#diag $err;
};

