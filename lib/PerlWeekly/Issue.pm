package PerlWeekly::Issue;
use strict;
use warnings;

use autodie;

use Data::Dumper   qw(Dumper);
use Encode         qw(decode encode);
use File::Slurp    qw(read_file);
use JSON           qw(from_json);
use PerlWeekly::Template       qw();
use Text::Wrap     qw(wrap);
use XML::RSS       qw();

sub new {
    my $class = shift;
    my ( $issue, $target ) = @_;

    my $self = from_json scalar read_file "src/$issue.json", binmode => 'utf8';
    bless $self, $class;

    $self->{$target} = 1;
    $self->{issue}  = $issue;
    $self->{number} = $issue;

    return $self;
}

sub generate {
    my $self = shift;
    my $target = shift;
    my @out = @_ ? shift : ();
    return (
        $target eq 'web'  ? $self                        ->process_tt('tt/page.tt', @out) :
        $target eq 'mail' ? $self->fixup_links           ->process_tt('tt/page.tt', @out) :
        $target eq 'text' ? $self->fixup_links->wrap_text->process_tt('tt/text.tt', @out) :
        $target eq 'rss'  ? $self->process_rss :
        die "Unknown target '$target'\n"
    );
}

sub fixup_links {
    my $self = shift;
    foreach my $ch (@{ $self->{chapters} }) {
       foreach my $e (@{ $ch->{entries} }) {
          $e->{url} = $e->{link} || $e->{url};
       }
    }
    return $self;
}

sub wrap_text {
    my $self = shift;
    foreach my $h (@{ $self->{header} }) {
        $h = html2text($h);
        $h = wrap('', '', $h);
    }
    foreach my $ch (@{ $self->{chapters} }) {
		foreach my $part (qw(header footer)) {
            $ch->{$part} = html2text($ch->{$part});
			$ch->{$part} = wrap('', '  ', $ch->{$part});
		}
        foreach my $e (@{ $ch->{entries} }) {
            $e->{text} = html2text($e->{text});
            $e->{text} = wrap('', '  ', $e->{text});
        }
    }
    foreach my $h (@{ $self->{footer} }) {
	    $h = html2text($h);
        $h = wrap('', '', $h);
    }
    return $self;
}

sub process_tt {
    my $self = shift;
    my $tmpl = shift;
    my $t = PerlWeekly::Template->new();

    $t->process($tmpl, $self, @_) or die $t->error;
}

sub process_rss {
    my $self = shift;

    my $url = 'http://perlweekly.com/';
    my $rss = XML::RSS->new( version => '1.0' );
    my $year = 1900 + (localtime)[5];
    $rss->channel(
        title       => 'Perl Weekly newsletter',
        link        => $url,
        description => 'A free, once a week e-mail round-up of hand-picked news and articles about Perl.',
        dc => {
            language  => 'en-us',
            publisher => 'szabgab@gmail.com',
            rights    => "Copyright 2011-$year, Gabor Szabo",
        },
        syn => {
            updatePeriod     => "weekly",
            updateFrequency  => "1",
            updateBase       => "2011-08-01T00:00+00:00",
        }
    );

    my $text = join "\n", map {"<p>$_</p>"} @{ $self->{header} };

    $rss->add_item(
        title => decode('utf-8', "#$self->{issue} - $self->{subject}"),
        link  => "${url}archive/$self->{issue}.html",
        description => encode('utf-8', $text),
        #dc => {
        #    creator => '???', # TODO should be the author of the original article
        #    date    => POSIX::strftime("%Y-%m-%dT%H:%M:%S+00:00", localtime $e->{timestamp},
        #    subject => 'list of tags?',
    );

#    $self->{header};
    foreach my $ch (@{ $self->{chapters} }) {
        #$ch->{title}
        foreach my $e (@{ $ch->{entries} }) {
			warn "Missing text " . Dumper $e if not exists $e->{text};
            my $text = $e->{text};
            $rss->add_item(
                title => decode('utf-8', $e->{title}),
                link  => $e->{url},
                description => decode('utf-8', $e->{text}),
                #dc => {
                #    creator => '???', # TODO should be the author of the original article
                #    date    => POSIX::strftime("%Y-%m-%dT%H:%M:%S+00:00", localtime $e->{timestamp},
                #    subject => 'list of tags?',
            );
        }
    }

    #rss_item_count();
    $rss->save( 'html/perlweekly.rss' );
    return;
    #return $rss->as_string;
}

# simple html to text converter
# can handle <a href=http://bla>text</a>
sub html2text {
	my ($html) = @_;

	return if not defined $html;

	$html =~ s{<a href=([^>]+)>([^<]+)</a>}{$2 ($1)}g;
	return $html;
}

1;

