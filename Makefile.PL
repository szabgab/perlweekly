use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'PerlWeekly',
	AUTHOR              => q{Gabor Szabo <szabgab@cpan.org>},
	VERSION             => '0.01',
#	VERSION_FROM        => 'lib/Perl/Maven.pm',
	ABSTRACT            => 'PerlWeekly generator',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	PREREQ_PM => {
		'Cwd'                    => 0,
		'Data::Dumper'           => 0,
		'Data::ICal'             => 0,
		'Data::Printer'          => 0,
		'DateTime::Format::ICal' => 0,
		'DateTime::Functions'    => 0,
		'Encode'                 => 0,
		'File::Basename'         => 0,
		'Gravatar::URL'          => 0,
		'JSON'                   => 0,
		'JSON::XS'               => 0,
		'JSON::Path'             => 0,
		'List::MoreUtils'        => 0,
		'List::Util'             => 0,
		'LWP::Simple'            => 0,
		'MIME::Lite'             => 0,
		'Net::Delicious'         => 0,
		'Path::Tiny'             => 0,
		'Template'               => 0,
		'Test::More'             => 0,
		'Perl::Tidy'             => '20140711',  # Apparently Test::Code::TidyAll does not explicitly depend on it
		'Test::Code::TidyAll'    => 0.20,
		'Test::Perl::Critic'     => 0,
		'Text::Wrap'             => 0,
		'WWW::Mailman'           => 0,
		'WWW::Shorten::Bitly'    => 0,
		'XML::RSS'               => 0,
		'XML::Feed'              => 0,
		'YAML'                   => 0,
	},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean               => { FILES => 'Perl-Maven-*' },
)
