use strict;
use warnings;
use WWW::Mailman;
use Data::Dumper qw(Dumper);

my $pw = shift;
if ( not $pw ) {
	print "Admin pw: ";
	chomp( $pw = <STDIN> );
}

my $m = WWW::Mailman->new(
	uri => 'https://mail.perlweekly.com/mailman/listinfo/perlweekly',
	admin_password => $pw,
);

#my @roster = $m->roster;
#print Dumper $roster[0];
#print scalar @roster;
#print Dumper $m->admin_general;
$m->list_members;

