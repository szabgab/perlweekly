#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use autodie;

binmode( STDOUT, ":encoding(UTF-8)" );
binmode( STDERR, ":encoding(UTF-8)" );

use Carp::Always;
use Cwd qw(abs_path);
use Data::Dumper qw(Dumper);
use File::Basename qw(basename dirname);
use Path::Tiny qw(path);
use JSON qw(from_json);
use List::Util qw(max);
use Data::ICal                 ();
use Data::ICal::Entry::Event   ();
use DateTime::Format::Strptime ();
use DateTime::Format::ICal     ();
use DateTime::Format::W3CDTF   ();
use DateTime                   ();

use lib dirname( dirname abs_path($0) ) . '/lib';
use PerlWeekly qw(get_authors);
use PerlWeekly::Template qw();
use PerlWeekly::Issue;

my $dir = 'docs';
for my $name ( 'archive', 'a', 'tags' ) {
	mkdir "$dir/$name" if not -e "$dir/$name";
}

my ( $target, $issue ) = @ARGV;
if (   not $target
	or not $issue
	or $target !~ /^(mail|text|web|rss)$/
	or not $issue )
{
	warn <<"END_USAGE";
Usage: $0
   web   ISSUE
   mail  ISSUE          an html version to be sent by e-mail
   text  ISSUE          a text version to be sent by e-mail
   rss   ISSUE          (no output)

   ISSUE is a number or the word sources

   or we can also write

   web events           generate the events page only
   web all
   web latest

END_USAGE
	exit;
}

my $count = 0;
if ( open my $fh, '<', 'src/count.txt' ) {
	my $sub_row = <$fh>;
	chomp $sub_row;
	( undef, $count ) = split /\;/, $sub_row, 2;
	close $fh;
}

if ( $target ne 'web' ) {
	PerlWeekly::Issue->new( $issue, $target, $dir )->generate($target);
	exit;
}

if ( $issue eq 'events' ) {
	events_page();
	metacpan_page();
	stats_page();
	exit;
}

if ( $issue eq 'all' or $issue eq 'latest' ) {
	my ( @issues, $last, %editors );
	my ($max) = max grep {/^\d+$/}
		map { substr( basename($_), 0, -5 ) } glob 'src/*.json';
	foreach my $i ( 1 .. $max ) {
		my $pwissue = PerlWeekly::Issue->new( $i, $target, $dir );
		push @{ $editors{ $pwissue->{editor} } }, $i;
		$pwissue->{latest} = $max;
		if ( $issue eq 'all' or $i == $max ) {
			$pwissue->generate( $target, "$dir/archive/$i.html" );
		}
		push @issues, $pwissue;
		$last = $pwissue;
	}

	$last->generate('rss');

	$last->{latest_page} = $max;

	#$last->generate( $target, "$dir/latest.html" );
	open my $out, '>', "$dir/latest.html" or die;
	print $out <<"END_LATEST";
<script>
window.location = location.origin + "/archive/$max.html";
</script>
END_LATEST
	close $out;

	open my $out_reg, '>', "$dir/register.html" or die;
	print $out_reg <<"END_REGISTER";
<script>
window.location = "https://mail.perlweekly.com/cgi-bin/mailman/listinfo/perlweekly";
</script>
END_REGISTER
	close $out_reg;

	delete $last->{latest_page};

	my %articles_by;
	my $authors = get_authors();
	foreach my $issue (@issues) {

		#say "   Issue: $issue->{issue}";
		#die Dumper $issue;
		foreach my $ch ( @{ $issue->{chapters} } ) {

			#die Dumper $ch;
			foreach my $entry ( @{ $ch->{entries} } ) {
				if ( $entry->{title} =~ /^\s*$/ ) {
					die "Issue '$issue->{issue}' is missing a title\n";
				}
				if ( $entry->{author} ) {

					#print Dumper $entry;
					$entry->{issue} = $issue->{issue};
					push @{ $articles_by{ $entry->{author}{key} } }, $entry;
				}
			}
		}
	}

	#die Dumper \%articles_by;

	my $next = PerlWeekly::Issue->new( 'next', $target, $dir );
	my $t    = PerlWeekly::Template->new();

	foreach my $author ( keys %$authors ) {

		#die Dumper $authors->{$author};
		#die Dumper $articles_by{$author};
		$t->process(
			'tt/articles_by_author.tt',
			{
				author   => $authors->{$author},
				articles => [
					sort { $a->{ts} cmp $b->{ts} } @{ $articles_by{$author} }
				]
			},
			"$dir/a/$authors->{$author}{handler}.html"
		) or die $t->error;
	}

	$t->process(
		'tt/authors.tt',
		{
			authors => [
				sort {
						   $a->{name} cmp $b->{name}
						or $a->{handler} cmp $b->{handler}
				} values %$authors
			]
		},
		"$dir/authors.html"
	) or die $t->error;

	$t->process( 'tt/archive.tt', { issues => \@issues, reverse => 0 },
		"$dir/archive/reverse.html" )
		or die $t->error;

	$t->process( 'tt/all.tt', { issues => \@issues }, "$dir/all.html" )
		or die $t->error;

	collect_tags(@issues);
	collect_links(@issues);

	@issues = reverse @issues;
	$t->process( 'tt/archive.tt', { issues => \@issues, reverse => 1 },
		"$dir/archive/index.html" )
		or die $t->error;

	my %editors_count = map { $_ => scalar @{ $editors{$_} } } keys %editors;

	#print Dumper \%editors;
	#print Dumper \%editors_count;
	$t->process(
		'tt/index.tt',
		{
			latest              => $max,
			next_issue_date     => $next->{date},
			latest_issue_number => $max,
			count               => $count,
			editors             => \%editors_count,
		},
		"$dir/index.html"
	) or die $t->error;
	events_page();
	metacpan_page();
	stats_page();

	foreach my $f (
		qw(thankyou unsubscribe promotion sponsors promoting-perl-events editor)
		)
	{
		$t->process( "tt/$f.tt", {}, "$dir/$f.html" ) or die $t->error;
	}

	# Create sitemap.xml
	my $URL   = 'http://perlweekly.com';
	my @pages = { filename => "$URL/" };
	push @pages, map { { filename => "$URL/$_" } } qw(
		archive/
		archive/reverse.html
		all.html
		promotion.html
		events.html
		latest.html
		sponsors.html
		promoting-perl-events.html
	);
	push @pages, map { { filename => "$URL/archive/$_.html" } } 1 .. $max;
	$t->process( 'tt/sitemap.tt', { pages => \@pages }, "$dir/sitemap.xml" )
		or die $t->error;

}
else {
	PerlWeekly::Issue->new( $issue, $target, $dir )
		->generate( $target, "$dir/archive/$issue.html" );
	print "done\n";
}

exit;

sub collect_tags {
	my @issues = @_;
	my %links;
	my %tags;
	foreach my $issue (@issues) {
		foreach my $ch ( @{ $issue->{chapters} } ) {
			foreach my $e ( @{ $ch->{entries} } ) {
				next if not $e->{tags};
				die  if not ref $e->{tags};
				die  if 'ARRAY' ne ref $e->{tags};
				foreach my $tag ( @{ $e->{tags} } ) {
					my $url = lc $tag;
					$url =~ s/[^a-z0-9]+/_/g;
					$url =~ s/^_|_$//g;
					$tags{$url}{tag} = $tag;
					$tags{$url}{cnt}++;
					push @{ $tags{$url}{entries} }, $e;
				}
			}
		}
	}

	my $t = PerlWeekly::Template->new();
	$t->process( 'tt/tags.tt', { tags => \%tags }, "$dir/tags.html" )
		or die $t->error;

	foreach my $url ( keys %tags ) {
		$t->process(
			'tt/tag.tt',
			{
				tag     => $tags{$url}{tag},
				cnt     => $tags{$url}{cnt},
				entries => $tags{$url}{entries}
			},
			"$dir/tags/$url.html"
		) or die $t->error;
	}

	return;
}

sub collect_links {
	my @issues = @_;
	my %links;
	foreach my $issue (@issues) {
		foreach my $ch ( @{ $issue->{chapters} } ) {
			foreach my $e ( @{ $ch->{entries} } ) {
				$links{ $e->{url} } = $e;
			}
		}
	}
	my %count;
	foreach my $url ( keys %links ) {
		if ( $url =~ m{http://blogs.perl.org/users/[^/]+} ) {
			$count{$&}++;
		}
		elsif ( $url =~ m{https?://[^/]+} ) {
			$count{$&}++;
		}
		else {
			warn "Strange url '$url' " . Dumper $links{$url};
		}
	}
	my @sources = map { { url => $_, count => $count{$_} } }
		reverse sort { $count{$a} <=> $count{$b} or $a cmp $b } keys %count;
	my $t = PerlWeekly::Template->new();
	$t->process( 'tt/sources.tt', { sources => \@sources },
		"$dir/sources.html" )
		or die $t->error;

	#print Dumper \%links;
	#print Dumper \%count;
}

sub stats_page {
	my @stats;

	my $filename = path("src/stats.txt");
	my @lines    = $filename->lines_utf8( { chomp => 1 } );
	my @header   = split /\s*;\s*/, shift @lines;
	for my $line (@lines) {
		next if $line =~ /^\s*$/;
		my @line_data = split /\s*;\s*/, $line;
		$line_data[0] =~ s/\s*#//;
		my %h;
		@h{@header} = @line_data;
		push @stats, \%h;
	}

	shift @header;    # get rid of  "issue" for special treatment
	my $t = PerlWeekly::Template->new();
	$t->process(
		'tt/stats.tt',
		{
			header => \@header,
			stats  => \@stats,
		},
		"$dir/stats.html"
	) or die $t->error;

}

sub metacpan_page {
	my @metacpan;

	my $filename = path("src/metacpan.txt");
	my @lines    = $filename->lines_utf8( { chomp => 1 } );
	my @header   = split /\s*;\s*/, shift @lines;
	for my $line (@lines) {
		next if $line =~ /^\s*$/;
		my @line_data = split /\s*;\s*/, $line;
		$line_data[0] =~ s/\s*#//;
		my %h;
		@h{@header} = @line_data;
		if ( $h{has_vcs} ) {
			$h{missing_vcs}
				= int( 100 * ( $h{distros} - $h{has_vcs} ) / $h{distros} );
		}
		if ( $h{has_ci} ) {
			$h{missing_ci}
				= int( 100 * ( $h{has_vcs} - $h{has_ci} ) / $h{has_vcs} );
		}
		if ( $h{has_bugz} ) {
			$h{missing_bugz}
				= int( 100 * ( $h{has_vcs} - $h{has_bugz} ) / $h{has_bugz} );
		}
		push @metacpan, \%h;
	}

	my $t = PerlWeekly::Template->new();
	$t->process( 'tt/metacpan.tt', { metacpan => \@metacpan },
		"$dir/metacpan.html" )
		or die $t->error;

}

sub events_page {
	my $events;
	my $filepath = path("src/events.json");
	eval { $events = from_json scalar $filepath->slurp_utf8; };
	if ($@) {
		die "JSON exception in src/events.json\n\n$@";
	}
	my $modify_time = ( stat($filepath) )[9];
	my $changed     = DateTime->from_epoch( epoch => $modify_time );

	my $w3c      = DateTime::Format::W3CDTF->new( strict => 1 );
	my $calendar = Data::ICal->new;
	my $now      = DateTime->now;
	my @entries  = grep { $w3c->parse_datetime( $_->{begin} ) > $now }
		@{ $events->{entries} };
	my $t = PerlWeekly::Template->new();
	$t->process( 'tt/events.tt', { events => \@entries }, "$dir/events.html" )
		or die $t->error;

	for my $entry (@entries) {
		my $event = Data::ICal::Entry::Event->new;

		my $dstart = $w3c->parse_datetime( $entry->{begin} );
		my ( $end, $duration );
		if ( $entry->{end} ) {
			$end = DateTime::Format::ICal->format_datetime(
				$w3c->parse_datetime( $entry->{end} ) );
		}
		else {
			$duration = DateTime::Format::ICal->format_duration(
				DateTime::Duration->new( hours => 2, minutes => 0 ) );
		}

		$event->add_properties(
			summary     => $entry->{title},
			description => join( "\n\n", $entry->{url}, $entry->{text} ),
			dtstart     => DateTime::Format::ICal->format_datetime($dstart),
			location    => $entry->{url},
			dtstamp     => DateTime::Format::ICal->format_datetime($changed),
			uid         => DateTime::Format::ICal->format_datetime($dstart)
				. $entry->{url},
			( $end ? ( dtend => $end ) : ( duration => $duration ) ),
		);
		$calendar->add_entry($event);
	}
	open my $fh, '>', 'docs/perlweekly.ical' or die;
	print $fh $calendar->as_string;
}

