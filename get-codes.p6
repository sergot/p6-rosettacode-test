#!/usr/bin/env perl6

use HTTP::UserAgent;

my $main_url = 'http://rosettacode.org/wiki/Category:Perl_6';

my $ua = HTTP::UserAgent.new(:user-agent<chrome_linux>);

my $response = $ua.get($main_url);

my $content = $response.content;

#say $content;
for get-tasks-urls($content) {
    get-codes("http://rosettacode.org$_[0]");
}

sub get-tasks-urls(Str $content) {
    $content.match(/ 'href="' ( <-[" :]>+ ) '" title="' ( <-["]>+ ) '"' /, :g).grep({ $_[0].substr(0, 5) eq '/wiki' });
}

sub get-codes($url) {
    # TODO : get Perl 6 codes
    say $url;
}
