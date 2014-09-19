use v6;
use HTTP::UserAgent :simple;
use IO::Capture::Simple;

class Task {
    has Int $.id;
    has $.title;
    has @.codes;
    has $.url;

    method dump {
        return { :$.id, :$.title, :$.url, codes => @.codes>>.dump };
    }
}

class P6Code {
    has $.code;
    has $.result is rw;
    has $.time is rw;

    method dump {
        return { :$.code, :$.result, :$.time }
    }
}

my @tasks;
my $json;
my $url = 'http://rosettacode.org/mw/api.php?action=query&list=categorymembers&cmtitle=Category:Perl_6&cmlimit=500&cmtype=page&format=json';

repeat {
    $url ~= "&cmcontinue=$json<query-continue><categorymembers><cmcontinue>"
        if $json<query-continue><categorymembers><cmcontinue>.defined;
    my $content = get($url);
    $json = from-json($content);

    for $json<query><categorymembers>.list {
        my $code;

        my $task_url = 'http://rosettacode.org/mw/api.php?action=query&prop=revisions&rvprop=content&format=json&titles=' ~ clearify($_<title>);
        $code = get($task_url);

        my @codes = $code.match(/'<lang ' ['perl6' | 'Perl6'] '>' (.*?) '<\/lang>'/, :i, :g).map({ P6Code.new(:code(codify(~$_[0]))) });

        for @codes -> $p6code {
            my $start = time;
            $p6code.result = capture_stdout { try EVAL $p6code.code };
            my $end = time;
            $p6code.time = $end - $start;
            $p6code.result = "FAIL: $!" if $!;
        }
        my $task = Task.new(:id($_<pageid>), :title($_<title>), :@codes, :url($task_url));

        my $file = open "result.json", :a;
        $file.say: to-json($task.dump);
        $file.close;

        @tasks.push: $task;
    }
} while $json<query-continue><categorymembers><cmcontinue>;

say to-json @tasks>>.dump;

sub clearify(Str $s is copy) {
    $s ~~ s:g/\s+/_/;
    $s;
}

sub codify(Str $s is copy) {
    $s ~~ s:g/\\n/\n/;
    $s ~~ s:g/\\t/\t/;
    $s ~~ s:g/\\\"/\"/;
    $s;
}

#Get all pages in the "Perl 6" category:
#
#http://rosettacode.org/mw/api.php?action=query&list=categorymembers&cmtitle=Category:Perl_6&cmlimit=500&cmtype=page&format=json
#
#You can only fetch 500 titles at a time, this tells you there are more pages:
#
#"query-continue":{"categorymembers":{"cmcontinue":"page|52414e47452045585452414354494f4e|7772"}
#
#To get more append &cmcontinue={$json<query-continue><categorymembers><cmcontinue>}
#
#eg. http://rosettacode.org/mw/api.php?action=query&list=categorymembers&cmtitle=Category:Perl_6&cmlimit=500&cmtype=page&format=json&cmcontinue=page|52414e47452045585452414354494f4e|7772
#
#
#Get the content of a page:
#
#http://rosettacode.org/mw/api.php?action=query&prop=revisions&titles=Forest_fire&rvprop=content&format=json
#
#The Perl 6 section of the page starts with =={{header|Perl 6}}==
#
#The code should be enclosed within <lang perl6>...</lang> tags.
#
# carlin++

