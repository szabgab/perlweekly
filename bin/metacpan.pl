use strict;
use warnings;
use 5.010;
use MetaCPAN::Client ();
use DateTime         ();

use File::Spec           ();
use Log::Log4perl        ();
use Log::Log4perl::Level ();
use FindBin              ();
use Getopt::Long qw(GetOptions);

my $run;
my $days = 7;

GetOptions(
    "run"    => \$run,
    "days:i" => \$days,
) or usage();

# clone https://github.com/szabgab/cpan-digger-new
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'cpan-digger-new' );
use CPANDigger qw(get_data);

my $recent = 1000;

my $log_level = 'DEBUG';
Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority($log_level) );

my $dt = DateTime->now;

if (not $run) {
    $run = $dt->day_of_week == 1;
}
die "We are only supposed to run this on Monday! Override it by passing --run\n" if not $run;

my $today       = $dt->ymd;
my $last_monday = $dt->add( days => -$days )->ymd;

my $mcpan = MetaCPAN::Client->new();
my $rset  = $mcpan->recent($recent);
my $total = 0;
my %distros;
my %authors;
my $done      = 0;
my $vcs_count = 0;
my $ci_count  = 0;

while ( my $item = $rset->next ) {
	$done = $item->date le $last_monday;

	next if $item->date lt $last_monday;
	next if $today le $item->date;

	$total++;
	my $already_seen = $distros{ $item->distribution };
	$distros{ $item->distribution }++;
	say $item->author;
	$authors{ $item->author }++;
	next if $already_seen;

	my %data = get_data($item);
	if ( $data{vcs_url} ) {
		$vcs_count++;
	}
	if ( $data{has_ci} ) {
		$ci_count++;
	}
}

if ( not $done ) {
	die
		"We checked the $recent most recent uploads, but the earliest is less than a week old, so there might be more. Increase the \$recent variable in the code!\n";
}

printf
	"Last week there were a total of %s uploads to CPAN of %s distinct distributions by %s different authors. Number of distributions with link to VCS: %s. Number of distros with CI: %s.\n",
	$total, scalar( keys %distros ), scalar( keys %authors ), $vcs_count,
	$ci_count;


sub usage {
    print <<"END";
Usage: $0
       --run        To run on any day, not only on Sunday
       --days N     How many days to report. Defaults to 7 days.
END
    exit();
}

