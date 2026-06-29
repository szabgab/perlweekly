# The source of the Perl Weekly web site and the Perl Weekly newsletter

The website is hosted here: https://perlweekly.com/ it is a static web site.

The code generating the site and sending out the emails is written in Perl.

The command `perl bin/generate.pl web all` generates the static web site in the `docs` folder.

The command `perl bin/generate.pl web latest` generates the static web site only for the most recent edition in the `docs` folder.

The source of each edition of the newsletter is in the `src/` folder in a JSON File numbered from `1.json`.


The Perl source code is in the `bin` and in the `lib` folders.

## Templates

The HTML templates are in the `tt/` folder using Template Toolkit https://template-toolkit.org/

* `tt/webpage.tt` is the template of the individual issue for the web site.
* `tt/mail.tt` is the template of the individual issue sent out as an email.
* `tt/md.tt` is the template of the individual issue converted to Markdown to be published elsewhere.


## Development instructions

* After every change run `tidyall -a --refresh-cache` to make the Perl source code tidy.

* Do NOT change the json files in the `src` folder unless explicitely asked to do it.

* Run the tests: `perl Makefile.PL && make && make test` and make sure they are passing.

