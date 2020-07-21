#!/usr/bin/perl

# rep.pl - passage selector aka multi-lingal replcacer
# 2020-apr-06 started
# 2020-apr-07 single level selector
# 2020-apr-08 multi level selector
# 2020-apr-09 test run with mod_ext_filter and pandoc - see rep.sh
# 2020-apr-11 test run with mod_actions and pandoc - see rep.cgi
# 2020-apr-13 marker syntax change
# 2020-jun-22 loader available only if source directory specified
# this version marked as v0.1
# -----------
# 2020-jul-19 design change
#  - multiple target selectors
#  - available languages
#  - lang selectors and dot-prefixed version selectors
#  - tow-level selector stack
#  - no more loader
# 2020-jul-20 tested ok
#
# TODO: allow /en/ at the beginning of a line?

use strict;
use warnings;

use constant { true => 1, false => 0, DEFLANG => 'en' };

my $debug = 0; # -d option - intersperce debug text within the output

# fuctions

# warn_print($str)
# print warning to stderr but don't quit
# use die to print error and quit
sub warn_print {
    my $str = shift;
    print STDERR '[WARN] ' . $str . "\n";
}

# debug_print($str)
# print output intermixed into stdout if $debug is true
sub debug_print {
    my $str = shift;
    if ($debug) { print '[DEBUG] ' . $str . "\n"; }
}

# $bool = isLang($selector)
# true if the selector is language selector
# otherwise the selector is version selector which starts with dot '.'
sub isLang {
    my $s = shift;
    return not $s =~ /^\./;
}

# $bool = isSameType($sel1, $sel2)
# true if both selectors are the same type; both langs or both versions
sub isSameType {
    my ($s1, $s2) = @_;
    return (isLang($s1) && isLang($s2)) || (!isLang($s1) && !isLang($s2));
}

# $targetLanguage = selectLanguage($targetSelectors_ref, $availableLanguages_ref);
# find the first selector in target selectors that match any of available selectors.
# DEFLANG (en) if no match found
sub selectLanguage {
    my ($target_ref, $avail_ref) = @_;
    my @targetSelectors = @{$target_ref};
    my @availableLanguages = @{$avail_ref};
    if (@targetSelectors == 0) { return DEFLANG; } # fail-safe
    if (@availableLanguages == 0) { return $targetSelectors[0]; } # first one if no avail
    foreach my $s (@targetSelectors) {
        if (!isLang($s)) { next; } # skip version selector
        if (grep { $s eq $_ } @availableLanguages) { return $s; }
    }
    return DEFLANG; # fail-safe
}

# inclusiveEquals(intext-selector, target-selector)
# check if the first string is 'inclusively equals' to the second string.
#  inclusiveEquals('.foo.v2', '.foo') returns false
#  inclusiveEquals('.foo', '.foo.v2') returns true
#  inclusiveEquals('.foo.v2', '.foo.v2') returns true
# Note: this is used to compare version selectors,
#   not language selectors which requires just a simple string comparison
sub inclusiveEquals {
    my ($intext, $target) = @_;
    my $len1 = length($intext);
    my $len2 = length($target);
    #debug_print "inclusiveEquals: $len1, $len2";
    if ($len1 > $len2) {
        #debug_print "inclusiveEquals: shorter -> false";
        return 0;
    }
    my $cc = $intext eq substr($target, 0, $len1);
    #debug_print "inclusiveEquals: $cc";
    return $cc
}

# main code

sub run {
    # arguments
    my @targetSelectors = (); # -s option - selectors specified by the user
    my @availableLanguages = (); # -l option - language list supported by the document

    # Usage: rep.pl [-d] [-s<target-selectors>] [-l<available-languages>]
    foreach my $arg (@ARGV) {
        if ($arg =~ '^-d$') { $debug = 1; }
        elsif ($arg =~ '^-s([\w.,]+)$') { @targetSelectors = split(/,/, $1); }
        elsif ($arg =~ '^-l([\w.,]+)$') { @availableLanguages = split(/,/, $1); }
        elsif ($arg =~ '^-p.*$') { warn_print "The -p option not supported any more ... ignored"; }
        else { die "[ERROR] no such option: $arg"; }
    }

    debug_print "targetSelectors = @targetSelectors";
    debug_print "availableLanguages = @availableLanguages";

    # determine target language
    my $targetLanguage = selectLanguage(\@targetSelectors, \@availableLanguages);
    debug_print "targetLanguage = $targetLanguage";

    my @stack; # tow-level selector stack: lang over version or version over lang
    my $lineCount = 0;

    foreach my $line ( <STDIN> ) {
        $lineCount++;
        if ($line =~ /^\/end\/\s*$/) { # explicit end marker - /end/
            debug_print ">END @stack";
            pop @stack;
            debug_print "<END @stack";
        }
        elsif ($line =~ /^\/([\w.]+)\/$/) { # intext selector - /selector/
            my $selector = $1;
            debug_print ">SEL $selector -> @stack";
            my $top = $stack[-1];
            if (@stack == 2) {
                if (isSameType($selector, $top)) {
                    pop @stack;
                }
                else {
                    pop @stack;
                    pop @stack;
                }
            }
            elsif (@stack == 1) {
                if (isSameType($selector, $top)) {
                    pop @stack;
                }
            }
            push(@stack, $selector);
            debug_print "<SEL @stack";
        }
        else {
            my $langOK = true;
            my @lang = grep { isLang($_) } @stack; # only one
            #debug_print "LINE: lang = @lang";
            if (@lang > 0) {
                # if lang specified then check it
                $langOK = $lang[0] eq $targetLanguage;
            }
            my $verOK = true;
            my @ver = grep { !isLang($_) } @stack; # just one
            #debug_print "LINE: ver = @ver";
            if (@ver > 0) {
                # if version specified then at least one of target selectors must match
                $verOK = false;
                foreach my $t (@targetSelectors) {
                    if (isLang($t)) { next; }
                    if (inclusiveEquals($ver[0], $t)) { $verOK = true; last; }
                }
            }
            #debug_print "LINE: langOK = $langOK, verOK = $verOK";
            if ($langOK && $verOK) { print $line; }
        }
    }
}

run();
