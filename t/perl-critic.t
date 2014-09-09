use strict;
use warnings;

use Test::More;
use Perl::Critic;
use Test::Perl::Critic;

# NOTE: New files will be tested automatically.

# FIXME: Things should be removed (not added) to this list.
# Temporarily skip any files that existed before adding the tests.
# Eventually these should all be removed (once the files are cleaned up).
my %skip = map { ( $_ => 1 ) } qw(
);

my @files = grep { !$skip{$_} }
	( Perl::Critic::Utils::all_perl_files(qw( bin lib t )) );

foreach my $file (@files) {
	critic_ok( $file, $file );
}

done_testing();
