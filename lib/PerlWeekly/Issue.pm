package PerlWeekly::Issue;
use 5.010;
use strict;
use warnings;

use autodie;

use Carp qw(croak);
use Data::Dumper qw(Dumper);
use Encode qw(decode encode);
use Path::Tiny qw(path);
use JSON qw(from_json);
use PerlWeekly::Template qw();
use Text::Wrap qw(wrap);
use XML::RSS qw();
use DateTime qw();
use DateTime::Format::W3CDTF  ();
use DateTime::Format::ISO8601 ();
use URL::Encode qw(url_encode_utf8);

use PerlWeekly qw(get_authors);

#use POSIX          qw();

sub new {
	my $class = shift;
	my ( $issue, $target, $dir ) = @_;

	my $self;
	my $filename = "src/$issue.json";
	die "File '$filename' does not exist.\n" if not -e $filename;
	my $content       = scalar path($filename)->slurp_utf8;
	my @blogspot_urls = grep { $_ ne 'com' }
		$content =~ m{https?://.*\.blogspot\.([\w.]*)/};
	die "Issue $issue has a blogspot URL that is not .com: "
		. Dumper \@blogspot_urls
		if @blogspot_urls;

	eval { $self = from_json $content };
	if ($@) {
		die "JSON exception in '$filename' $@";
	}
	bless $self, $class;
	$self->{dir} = $dir;

	die "No date in $issue" if not $self->{date};
	die
		"Invalid date format in $issue received '$self->{date}' (expected YYYY-MM-DD)"
		if $self->{date} !~ /^\d\d\d\d-\d\d-\d\d$/;
	DateTime::Format::ISO8601->parse_datetime( $self->{date} )
		;    # just verify it
	if ( $issue ne 'next' ) {
		die "The 'editor' is missing from issue $issue.\n"
			if not $self->{editor};
		die "The 'subject' is missing from issue $issue.\n"
			if not $self->{subject};
		die "The 'header' is empty for issue $issue.\n"
			if not @{ $self->{header} };
	}

	for my $ch ( @{ $self->{chapters} } ) {
		my $id = lc $ch->{title};
		$id =~ s/\W+/_/g;
		$ch->{id} = $id;
		next if $issue eq 'next';
		foreach my $e ( @{ $ch->{entries} } ) {
			die "url field is mising in issue $issue for " . Dumper $e
				if not $e->{url};

			#die "ts field missing for url $e->{url} in issue $issue.\n"
			#	if not $e->{ts};

#print "Invalid ts format for url $e->{url} in issue $issue: '$e->{ts}'.\n" if $e->{ts} !~ /^\d\d\d\d\.\d\d\.\d\d$/;
		}
	}

	$self->{$target} = 1;
	$self->{issue}   = $issue;
	$self->{number}  = $issue;

	return $self;
}

sub generate {
	my $self   = shift;
	my $target = shift;
	my @out    = @_ ? shift : ();

	$self->add_author_info;
	$self->add_twitter;

	return (
		  $target eq 'web' ? $self->process_tt( 'tt/webpage.tt', @out )
		: $target eq 'mail'
		? $self->fixup_links->process_tt( 'tt/mail.tt', @out )
		: $target eq 'text'
		? $self->fixup_links->wrap_text->process_tt( 'tt/text.tt', @out )
		: $target eq 'rss' ? $self->process_rss
		:                    die "Unknown target '$target'\n"
	);
}

sub add_twitter {
	my $self = shift;

	foreach my $ch ( @{ $self->{chapters} } ) {
		foreach my $e ( @{ $ch->{entries} } ) {
			$e->{twitter} = url_encode_utf8("$e->{title} $e->{url}");
			if ( $e->{author} and $e->{author}{twitter} ) {
				$e->{twitter} .= " by \@$e->{author}{twitter}";
			}
			$e->{twitter} .= " via \@perlweekly";
		}
	}
	return;
}

sub add_author_info {
	my $self = shift;

	my $authors = get_authors();

# TODO: this funciton is called twice and this function replaces the editor entry with the hash so
# the checking should only be done when it is not a hash reference yet
# but ultimately this should probably run only once.
	if ( not ref $self->{editor} ) {
		die "Editor '$self->{editor}' not found in src/authors.json"
			if not $authors->{ $self->{editor} };
	}
	$self->{editor} = $authors->{ $self->{editor} };

	foreach my $ch ( @{ $self->{chapters} } ) {
		foreach my $e ( @{ $ch->{entries} } ) {
			if ( $e->{author} ) {
				next
					if ref $e->{author}
					; # TODO: remove this. (the current issue runs twice so we are skipping it the second time)
				die
					"Could not fine author '$e->{author}' in issue $self->{issue} ($e->{title})"
					if not $authors->{ $e->{author} };
				my $author = $authors->{ $e->{author} };
				if ($author) {
					$e->{author}    = $author;
					$e->{img}       = $author->{img};
					$e->{img_title} = $author->{name};
				}
				else {

					#warn "Author $e->{author} not found in authors.json\n";
					#delete $e->{author};
					next;
				}
			}
		}
	}
	return;
}

# In e-mail (both html and text) we prefer to use the shortened URL
# that, if exists, is stored in the "link" field.
sub fixup_links {
	my $self = shift;
	foreach my $ch ( @{ $self->{chapters} } ) {
		foreach my $e ( @{ $ch->{entries} } ) {
			$e->{url} = $e->{link} || $e->{url};
			my (@urls) = $e->{text} =~ m{<a href=(https?://[^>]*)>}g;
			push @urls, $e->{text} =~ m{<a href="(https?://[^>]*)">}g;

			#warn Dumper \@urls;
			foreach my $url (@urls) {
				if ( $e->{map}{$url} ) {
					$e->{text} =~ s{\Q$url}{$e->{map}{$url}};
				}
			}
		}
	}

# In email the internal links don't seem to work. So let's remove them. At least from the header.
	foreach my $h ( @{ $self->{header} } ) {
		$h =~ s{<a href="#\w+">([^<]+)</a>}{$1}g;
	}
	return $self;
}

sub wrap_text {
	my $self = shift;
	foreach my $h ( @{ $self->{header} } ) {
		$h = html2text($h);
		$h = wrap( '', '', $h );
	}
	foreach my $ch ( @{ $self->{chapters} } ) {
		foreach my $part (qw(header footer)) {
			$ch->{$part} = html2text( $ch->{$part} );
			$ch->{$part} = wrap( '', '  ', $ch->{$part} );
		}
		foreach my $e ( @{ $ch->{entries} } ) {
			$e->{text} = html2text( $e->{text} );
			$e->{text} = wrap( '', '  ', $e->{text} );
		}
	}
	foreach my $h ( @{ $self->{footer} } ) {
		$h = html2text($h);
		$h = wrap( '', '', $h );
	}
	return $self;
}

sub process_tt {
	my $self = shift;
	my $tmpl = shift;
	my $t    = PerlWeekly::Template->new();

	$t->process( $tmpl, $self, @_ ) or die $t->error;
}

sub process_rss_header {
	my $self = shift;

	my $url  = 'https://perlweekly.com/';
	my $rss  = XML::RSS->new( version => '1.0' );
	my $year = 1900 + (localtime)[5];

	#die $dt;
	$rss->channel(
		title => 'Perl Weekly newsletter',
		link  => $url,
		description =>
			'A free, once a week e-mail round-up of hand-picked news and articles about Perl.',
		dc => {
			language  => 'en-us',
			publisher => 'szabgab@gmail.com',
			rights    => "Copyright 2011-$year, Gabor Szabo",
		},
		syn => {
			updatePeriod    => "weekly",
			updateFrequency => "1",
			updateBase      => "2011-08-01T00:00+00:00",
		}
	);

	return $rss;
}

sub process_rss_header_item {
	my $self = shift;
	my ($rss) = @_;

	my $dateparser = DateTime::Format::W3CDTF->new;
	my $dt = $dateparser->parse_datetime("$self->{date}T10:00:00+00:00");

	my $text = join "\n", map {"<p>$_</p>"} @{ $self->{header} };

	return {
		title       => "#$self->{issue} - $self->{subject}",
		link        => "$rss->{channel}{link}archive/$self->{issue}.html",
		description => $text,
		dc          => {
			date    => $dateparser->format_datetime($dt),
			subject => 'list of tags?',
		}
	};
}

sub process_rss {
	my $self = shift;

	my $rss = $self->process_rss_header;

	my $text = join "\n", map {"<p>$_</p>"} @{ $self->{header} };

	my @items;
	push @items, $self->process_rss_header_item($rss);

	my $dateparser = DateTime::Format::W3CDTF->new;
	my $dt = $dateparser->parse_datetime("$self->{date}T10:00:00+00:00");

	#    $self->{header};
	foreach my $ch ( @{ $self->{chapters} } ) {

		#$ch->{title}
		foreach my $e ( @{ $ch->{entries} } ) {
			warn "Missing text " . Dumper $e if not exists $e->{text};
			my $text = $e->{text};

			#die Dumper $e;
			#my $ts = join '-', split /\./, $e->{ts};
			$dt->add( seconds => 1 );
			push @items, {
				title       => $e->{title},
				link        => $e->{url},
				description => $e->{text},
				dc          => {
					date    => $dateparser->format_datetime($dt),
				},
			};
		}
	}

	# Add items so the latest comes first, as is convention on blogs/in rss:
	foreach my $item ( reverse @items ) {
		$rss->add_item(%$item);
	}

	#rss_item_count();
	$rss->save("$self->{dir}/perlweekly.rss");
	return;

	#return $rss->as_string;
}

# simple html to text converter
# can handle <a href=http://bla>text</a>
sub html2text {
	my ($html) = @_;

	return if not defined $html;

	$html =~ s{<a href=["']([^>]+)["']>([^<]+)</a>}{$2 ( $1 )}g;
	$html =~ s{<br>}{\n}g;
	return $html;
}

1;
