package PerlWeekly;
use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Exporter     qw(import);
use JSON         qw(from_json);
use Path::Tiny   qw(path);

our @EXPORT_OK = qw(get_authors);

my %VALID = map { $_ => 1 }
	qw(comment from img linkedin name nick pause support twitter url url2);

sub get_authors {
	my $filename = "src/authors.json";

	my $authors
		= eval { from_json scalar( path($filename)->slurp_utf8 ) };
	die "Could not read src/authors.json\n\n$@" if $@;
	foreach my $author ( keys %$authors ) {
		die "Name missing from author '$author' in the $filename file\n"
			if not exists $authors->{$author}{name};

		for my $field ( keys %{ $authors->{$author} } ) {
			if ( not $VALID{$field} ) {
				print
					"Invalid field '$field' for author $author in $filename\n";
				exit 1;
			}
		}

		$authors->{$author}{key} = $author;
		( $authors->{$author}{handler} = $author ) =~ s/_/-/g;
	}
	return $authors;
}

1;

