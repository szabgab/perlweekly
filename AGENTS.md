# The source of the Perl Weekly web site and the Perl Weekly newsletter

The website is hosted here: https://perlweekly.com/ it is a static web site.

The code generating the site and sending out the emails is written in Perl.

The command `perl bin/generate.pl web all` generates the static web site in the `docs` folder.

The command `perl bin/generate.pl web latest` generates the static web site only for the most recent edition in the `docs` folder.


* Aftere every change run `tidyall -a --refresh-cache` to make the Perl source code tidy.


