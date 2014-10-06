###Status
[![Build Status](https://travis-ci.org/szabgab/perlweekly.png)](https://travis-ci.org/szabgab/perlweekly)

Website of the Perl Weekly newsletter

http://perlweekly.com/



The 'editorial' process
========================


Gabor: I follow a bunch of RSS/Atom feeds of blogs. Look at some other resource such as http://blogs.perl.org  http://www.reddit.com/r/perl
and probably a few others. Sometimes people send me e-mails.
When I want to start preparing the next edition (and this can happen the day after the previous edition, or if I am too busy, then
the day before the next edition is due) I copy  src/next.json to the appropriate src/###.json and manually update it.
I update the 'title', 'text', 'url', and 'ts' fields. I have not touched the 'tags' for quite some time, though it would be nice to use
that too and then display the values. At least on the web site. The 'link' field is going to be update by the bitly script. So I leave
that empty.

Yanick: ??

At the end Yanick sends a pull-request. Usually with a correctly formatted json file :)


The final touch
-----------------

* Update src/next.json to have the next date (this is used on the front page)
* Update src/count.txt from http://mail.perlweekly.com/mailman/admin/perlweekly/members
* add sponsors, if there are any
* Update the src/events.json maybe moving some old items to src/old_events.json
* Run ispell on the source file and try not to "fix" British English with American English
* Run  bin/bitly.pl to add the bitly links
* Run bin/generate.pl web all
* I commit, push
* Then run my own 'up.pl' script that will ssh to the production server and pull this repository from github.
* Look at the web page. If things need to be fixed, I go back to one of the previous steps.
* Once I am satisfied I ssh to the perlweekly.com server.
* run perl bin/sendmail.pl --issue --to my@email.address   
* look at the received e-mail to see if it looks ok.
* If it does, run the sendmail script again but this time to the address of the perlweekly.com mailing list.
* If I don't make a typo there, then Mailman soon sends me two e-mails. One because I sent an e-mail
  that was held for approval and the other one as I am the list administrator. I follow the link in this
  second e-mail and approve the message to go out to the mailing list.

* Then I go and past the link of the latest editon in the Perl Developers group on Facebook, the Perl Weekly page on Google+,
  LinkedIN, Twitter.


