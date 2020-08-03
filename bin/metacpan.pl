use strict;
use warnings;
use 5.010;
use MetaCPAN::Client ();
use DateTime         ();

my $recent = 1000;

my $dt = DateTime->now;
die "We are only supposed to run this on Monday!\n" if $dt->day_of_week != 1;
my $today       = $dt->ymd;
my $last_monday = $dt->add( days => -7 )->ymd;

my $mcpan = MetaCPAN::Client->new();
my $rset  = $mcpan->recent($recent);
my $total = 0;
my %distros;
my %authors;
my $done = 0;
while ( my $item = $rset->next ) {
	if ( $last_monday le $item->date and $item->date lt $today ) {
		$total++;
		$distros{ $item->distribution }++;
		say $item->author;
		$authors{ $item->author }++;
	}
	$done = $item->date le $last_monday;
}

if ( not $done ) {
	die
		"We checked the $recent most recent uploads, but the earliest is less than a week old, so there might be more. Increase the \$recent variable in the code!\n";
}

printf
	"Last week there were a total of %s uploads to CPAN of %s distinct distributions by %s different authors.\n",
	$total, scalar( keys %distros ), scalar( keys %authors ),

