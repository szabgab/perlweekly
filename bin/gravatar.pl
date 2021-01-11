use strict;
use warnings;
use 5.010;

use Gravatar::URL qw(gravatar_id gravatar_url);
use LWP::Simple qw(getstore);

my ( $email, $file ) = @ARGV;

die "Usage: $0 email file\n" if not $email or not $file;

#my $gravatar_id  = gravatar_id($email);
#say $gravatar_id;

#my $size = 128;    # Perl Maven

my $size         = 80;    # Perl weekly
my $gravatar_url = gravatar_url( email => $email, size => $size );
die if not $gravatar_url;

#say $gravatar_url;
getstore( $gravatar_url, $file );
