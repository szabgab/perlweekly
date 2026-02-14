package PerlWeekly::ChartUploads;
use 5.010;
use strict;
use warnings;
use utf8;

use Carp     qw( croak );
use English  qw( -no_match_vars );
use Exporter qw(import);

use GD::Graph::bars;
use GD::Graph::colour qw( :colours );
use List::Util        qw( max min );
use Math::Round       qw( nhimult );
use Path::Tiny        qw( path );
use Text::CSV         ();

our @EXPORT_OK = qw(chart_uploads);

sub chart_uploads {
	my ( $filepath_in, $filepath_out ) = @_;

	my @headers = qw(issue uploads distros authors has_vcs has_ci has_bugz);

	my $csv = Text::CSV->new(
		{
			binary           => 1,
			sep_char         => q{;},
			strict           => 0,
			decode_utf8      => 1,
			auto_diag        => 1,
			diag_verbose     => 1,
			blank_is_undef   => 0,
			empty_is_undef   => 0,
			allow_whitespace => 1,
			skip_empty_rows  => 1,      # The last row!
		}
	);
	$csv->column_names(@headers);

	my @rows;
	open my $fh, '<', $filepath_in or croak "Error opening file: $OS_ERROR";
	while ( my $row = $csv->getline($fh) ) {
		push @rows, $row;
	}
	close $fh or croak "Error closing file: $OS_ERROR";

	my $i = 0;
	my ( @issues, @uploads );
	foreach ( grep { defined $_->[1] } reverse @rows[ 1 .. $#rows ] ) {
		push @issues,  $_->[0];
		push @uploads, $_->[1];
	}
	my @x_values = ( \@issues, \@uploads );

	my $x_value_high = max map {$_} @{ $x_values[1] };

	my @gd_values = @x_values;
	my $graph     = GD::Graph::bars->new( 3.33 * @{ $x_values[1] }, 400 );
	$graph->set(
		x_label      => 'X Label',
		y_label      => 'Y label',
		title        => 'UPLOADS',
		y_min_value  => 0,
		y_max_value  => nhimult( 100, $x_value_high ) * 1.2,
		transparent  => 0,
		cycle_clrs   => 0,
		dclrs        => [qw(black)],
		x_ticks      => 0,
		x_label_skip => 50,
	);
	my $gd = $graph->plot( \@gd_values ) or croak $graph->error;
	path($filepath_out)->spew_raw( $gd->png );
}

1;
