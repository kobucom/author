#!/usr/bin/perl

# rep.pl - passage selector loader in perl aka multi-lingal replcacer
# 2020-apr-06 started
# 2020-apr-07 single level selector
# 2020-apr-08 multi level selector
# 2020-apr-09 test run with mod_ext_filter and pandoc - see rep.sh
# 2020-apr-11 test run with mod_actions and pandoc - see rep.cgi
# 2020-apr-13 marker syntax change
#
# TODO: allow /en/ at the beginning of a line?

use strict;
use warnings;

my $targetSelector = 'en'; # -s option - selector specified by the user
my $sourceDirectory = '.'; # -p option - directory containing the source file(s)
my $debug = 0;             # -d option - output debug text within the output

# fuctions

# print warning to stderr but don't quit
# use die to print error and quit
sub warn_print {
    print STDERR '[WARN] ' . shift . "\n";
}

# print output intermixed into stdout if $debug is true
sub debug_print {
    if ($debug) { print '[DEBUG] ' . shift . "\n"; }
}

# load(load-marker, target-selector)
# try loading candidate files with different selector levels in turn
# and output the contents to standard output
#   for load marker of 'loaded' with target selector of "ja.v2":
#     "loaded-ja_v2.txt" then "loaded-ja.txt" are tried
# the loaded files should reside in the same directory as the source file: $sourceDirectory
sub load {
    my ($lm, $sel) = @_;
    $sel =~ tr/./_/; # convert dots to underscores
    while ($sel) {
        my $file = $sourceDirectory . '/' . $lm . '-' . $sel . '.txt'; # loaded-en_v2.txt
        debug_print "LOAD: $file";
        if (open my $input, '<', $file) {
            while (<$input>) {
                print $_;
            }
            close $input or die "[ERROR] can't close $file";
            return 1;
        }
        else {
            debug_print "[WARN] $file, not found ... try next one";
        }
        my $index = rindex($sel, '_');
        if ($index > 0) { $sel = substr($sel, 0, $index); }
        else { $sel = undef; }
    }
    debug_print "[WARN] no loading text ... use inline text";
    return 0;
}

# inclusiveEquals(in-text-selector, target-selector)
# check if the first string is 'inclusively equals' to the second string.
# inclusiveEquals('en', 'en.v2') returns true while
# inclusiveEquals('en.v2', 'en') returns false
sub inclusiveEquals {
    my ($shorter, $longer) = @_;
    my $len1 = length($shorter);
    my $len2 = length($longer);
    if ($len1 > $len2) { return 0; }
    return $shorter eq substr($longer, 0, $len1);
}

# main code

# Usage: rep.pl [-d] [-s<target-selector>] [-p<source-directory>]
foreach my $arg (@ARGV) {
    if ($arg =~ '^-s([\w.]+)$') { $targetSelector = $1; }
    elsif ($arg =~ '^-p(.+)$') { $sourceDirectory = $1; }
    elsif ($arg =~ '^-d$') { $debug = 1; }
    else { die "[ERROR] no such option: $arg"; }
}

debug_print "targetSelector = $targetSelector";
debug_print "sourceDirectory = $sourceDirectory";
debug_print "debug = $debug";

my $doOutput = 1;
my $lineCount = 0;

foreach my $line ( <STDIN> ) {
    $lineCount++;
    if ($line =~ /^\/end\/\s*$/) { # explicit end marker - /end/
        debug_print "END";
        $doOutput = 1;
    }
    elsif ($line =~ /^\/([\w.]+)\/\s*$/) { # in-text selector - /sel1.sel2.../
        my $selector = $1;
        debug_print "SEL: $selector";
        $doOutput = inclusiveEquals($selector, $targetSelector);
    }
    elsif ($line =~ /^\/@([\w_]+)\/\s*$/) { # load marker - /@load-marker/
        my $loadMarker = $1;
        debug_print "LOAD: $loadMarker";
        $doOutput = !load($loadMarker, $targetSelector);
    }
    else {
        if ($doOutput) { print $line; }
    }
}
