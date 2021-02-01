use strict;
use warnings;
use 5.010;
use DateTime  ();
use XML::Feed ();
use Data::Dumper qw(Dumper);

my $dt = DateTime->now;

#die "We are only supposed to run this on Monday!\n" if $dt->day_of_week != 1;
my $today       = $dt->ymd;
my $last_monday = $dt->add( days => -7 )->ymd;

# TODO: Shall I use this list as source of feeds? https://github.com/davorg/planetperl/blob/master/perlanetrc
my @sites = (
	{
		'name' => 'Perl.com',
		'url'  => 'https://www.perl.com/article/index.xml',
	},
	{
		'name' => 'TPF',
		'url'  => 'https://news.perlfoundation.org/rss.xml',
	},
	{
		'name' => 'BPO',
		'url'  => 'http://blogs.perl.org/atom.xml',
	},
	{
		'name' => 'PerlHacks',
		'url'  => 'https://perlhacks.com/feed/',
	},
	{
		'name' => 'PerlAcademy',
		'url'  => 'https://blog.perl-academy.de/rss',
	},
	{
		'name' => 'Reddit',
		'url'  => 'http://www.reddit.com/r/perl/.rss',
	},
	{
		'name' => 'DevTo',
		'url'  => 'https://dev.to/feed/tag/perl',
	},
	{
		'name' => 'PerlMaven',
		'url'  => 'https://perlmaven.com/atom',
	},
);
my %counter;

for my $site (@sites) {

	#say $site->{name};
	my $count = 0;
	eval {
		my $feed = XML::Feed->parse( URI->new( $site->{url} ) );
		for my $entry ( $feed->entries ) {
			my $date = $entry->issued || $entry->modified;
			next if not $date;

			#say $date;
			#say Dumper $entry;
			next if $date lt $last_monday;
			next if $today le $date;

			#say $entry->title;
			#say $entry->link;
			$count++;
		}
	};
	if ($@) {
		say "Error $@";
	}
	$counter{ $site->{name} } = $count;
}

#say '------------------';
my $str = "";
print "Number of posts last week:";
for my $site ( sort keys %counter ) {
	print " $site: $counter{$site};";
    $str .= "  $counter{$site};";
}
print "\n";
print "$str\n";
