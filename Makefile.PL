use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PerlWeekly',
    AUTHOR              => q{Gabor Szabo <szabgab@cpan.org>},
    VERSION             => '0.01',
#    VERSION_FROM        => 'lib/Perl/Maven.pm',
    ABSTRACT            => 'PerlWeekly generator',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Cwd'                  => 0,
        'Data::Dumper'         => 0,
        'Encode'               => 0,
        'File::Basename'       => 0,
        'File::Slurp',         => 0,
        'Gravatar::URL'        => 0,
        'JSON'                 => 0,
        'List::MoreUtils'      => 0,
        'List::Util'           => 0,
        'LWP::Simple'          => 0,
        'Template'             => 0,
        'Test::More'           => 0,
        'Text::Wrap'           => 0,
        'WWW::Shorten::Bitly'  => 0,
        'XML::RSS'             => 0,
        'YAML'                 => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl-Maven-*' },
);
