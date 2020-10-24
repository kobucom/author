#!/usr/bin/env perl

# emulator for shell's here document feature
# supports conversion of ${envvar} and $(command)
# also $envvar and `backtic` syntax can be used
# this is convinient use in perl to convert text read from a file.
# you don't need this if you paste the text within a shell script.
# 20-sep-29 tested

package HereDoc;

use strict;
use warnings;

use Getopt::Long;

use lib "$ENV{PREPRO_AUTHOR}";
use Parser qw(debug_print flatten trim parseLine);

# debug
use Data::Dumper qw(Dumper);

# constants
use constant { true => 1, false => 0 };

# $output = backtick($cmd)
sub backtick {
    my $cmd = shift;
    my $s = qx($cmd);
    return trim(flatten($s));
}

{
    # originally designed to replace variables in HTML header prepended to and
    # HTML trailer appended to pandoc conversion output of a markdown body source.
    # made general-purpose here-doc like feature for perl scripts
    my @hereDocHandlers = (
        {
            # ${env}
            testpat => '\$\{',
            pattern => '\$\{(\w+)\}',
            code => sub {
                my ($span, $gstate, $lstate) = @_;
                debug_print('$span: ' . $span);
                debug_print('$&: ' . $&);
                debug_print('$1: ' . Dumper($1));
                return $ENV{$span};
            }
        },
        {
            # $env
            pattern => '\$(\w+)\b',
            code => sub {
                return $ENV{$1};
            }
        },
        {
            # $(command)
            testpat => '\$\(',
            pattern => '\$\((\w+)\)',
            code => sub {
                my ($span) = @_;
                return backtick($span);
            }
        },
        {
            # backtick `...`
            pattern => '`(\w+)`',
            code => sub {
                my ($span) = @_;
                return backtick($span);
            }
        }
    );

    # processFile($input, $output)
    sub processFile {
        my ($input, $output) = @_;
        while ( my $line = <$input> ) {
            print $output parseLine($line, \@hereDocHandlers);
        }
    }
}

# standalone startup code
if ($0 =~ /\bHereDoc.pm$/) {
    # Usage: Draw.pm [--debug]
    GetOptions ('debug' => sub { Parser::setDebug(true); });

    my $input = *STDIN;
    my $output = *STDOUT;
    processFile($input, $output);
}

true; # need to end with a true value
