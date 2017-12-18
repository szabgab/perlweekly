#!perl

use strict;
use warnings;
use autodie qw/ :all /;
use 5.010;

use JSON qw/ from_json to_json /;
use Path::Tiny qw/ path /;
use FindBin qw/ $Bin $Script /;
use Encode qw/ encode decode /;

use Getopt::Long;

my %options;

GetOptions( \%options, 'src|s=s', 'replace|r', 'verbose|v', 'try-harder|t', )
	|| die
	"Usage: $Script [ -s /path/to/src/dir -r (replaces authors in json) -v ]";

my $src_dir = $options{src} // "$Bin/../src";
my $src_json
	= encode( 'utf-8', scalar path("$src_dir/authors.json")->slurp_utf8 );
my $authors = from_json( $src_json, { utf8 => 1 } );

foreach my $weekly_file ( grep {/\d+\.json$/} path($src_dir)->children ) {
	say "Processing $weekly_file" if $options{verbose};
	$src_json = encode( 'utf-8', scalar( path($weekly_file)->slurp_utf8 ) );
	my $data = from_json( $src_json, { utf8 => 1 } );

	for my $ch ( @{ $data->{chapters} } ) {
		for my $e ( @{ $ch->{entries} } ) {

			if ( !$e->{author} ) {

				# try to find the author amongst the entry text
				my $title = $e->{title};
				my $text  = lc( $e->{text} // '' );
				$text =~ s/ /_/g;

				if ( my @candidates
					= find_candidates( $e, $authors, $options{'try-harder'} )
					)
				{
					say "Found @{[ join( ', ',@candidates ) ]} for $title"
						if $options{verbose};

					if ( scalar(@candidates) == 1 ) {
						$e->{author} = shift(@candidates)
							if $options{replace};
					}
					else {
						say "Too many candidates for $title in $weekly_file"
							if $options{verbose};
					}
				}
				else {
					#say "No luck with $title in $weekly_file"
					#	if $options{verbose};
				}
			}
		}
	}

	if ( $options{replace} ) {
		path($weekly_file)->spew_utf8(
			decode(
				'utf-8',
				to_json( $data, { utf8 => 1, pretty => 1, canonical => 1 } )
			)
		);
	}
}

sub find_candidates {
	my ( $entry, $authors, $try_harder ) = @_;

	my @authors = keys( %{$authors} );

	my $text = lc( $entry->{text} // '' );
	$text =~ s/ /_/g;

	my @candidates = grep { $text =~ /$_/ } @authors;

	return @candidates if @candidates;
	return () if !$try_harder;

	# try harder - try to find author bassed on real (?) name and blog url
	foreach my $author ( sort keys( %{$authors} ) ) {
		foreach my $identifier (qw/ name url /) {
			foreach my $entry_key (qw/ text url title link /) {

				if ( my $author_str = $authors->{$author}{$identifier} ) {
					if ( my $entry_str = $entry->{$entry_key} ) {
						push( @candidates, $author )
							if $entry_str =~ /\Q$author_str\E/;
					}
				}
			}
		}
	}

	return @candidates;
}
