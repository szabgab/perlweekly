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

sub _exit {
	my ($msg) = @_;
	print "$msg\n";
	exit 1;
}

sub get_authors {
	my $filename = "src/authors.json";

	my $authors
		= eval { from_json scalar( path($filename)->slurp_utf8 ) };
	die "Could not read src/authors.json\n\n$@" if $@;
	foreach my $author ( keys %$authors ) {
		_exit("Name missing from author '$author' in the $filename file")
			if not exists $authors->{$author}{name};

		my $img = $authors->{$author}{img};
		if ( defined $img ) {
			if ( $img !~ m{^/img/[a-z_-]+\.(png|jpg|jpeg|gif)$} ) {
				_exit("Incorrectly formatted image path: `$img`");
			}
			my $path = "static$img";
			_exit("Image '$path' does not exist") if not -e $path;
		}

		# Check if there are no extra fields
		for my $field ( keys %{ $authors->{$author} } ) {
			if ( not $VALID{$field} ) {
				_exit(
					"Invalid field '$field' for author $author in $filename");
			}
		}

		$authors->{$author}{key} = $author;
		( $authors->{$author}{handler} = $author ) =~ s/_/-/g;
	}
	return $authors;
}

1;

