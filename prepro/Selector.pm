#!/usr/bin/env perl

package Selector;

# Selector.pm - passage selector aka multi-lingal replcacer
#
# Copyright (c) 2020 Kobu.Com. Some Rights Reserved.
# Distributed under GNU General Public License 3.0.
# Contact Kobu.Com for other types of licenses.
#
# 2020-apr-06 started as rep.pl
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
# 2020-jul-21 reverted to less restrict syntax; space after selector: '/en/ '
# 2020-aug-31 marker at the beginning of a line; /any/ == /end/
# this version marked as v0.2
# -----------
# 2020-sep-28 rep.pl -> Selector.pm
# 2020-oct-05 \%state parameter

use strict;
use warnings;

use Getopt::Long;

use lib "$ENV{PREPRO_AUTHOR}";
use Parser qw(debug_print);

# debug
use Data::Dumper qw(Dumper);

use constant { true => 1, false => 0, DEFLANG => 'en' };

# constructor($state)
sub new {
    my ($class, $state) = @_;
    return bless {
        stack => [], # array reference to the internal selectors stack
            # two-level selector stack: lang over version or version over lang

        # call parameters
        lang => $state->{lang} || DEFLANG, # target language
        selectors => $state->{selectors},   # version selectors

        # internal states kept for debug output
        dbg_prev => '',
        dbg_chgd => true
    }, $class;
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
    #debug_print("inclusiveEquals: $len1, $len2");
    if ($len1 > $len2) {
        #debug_print("inclusiveEquals: shorter -> false");
        return 0;
    }
    my $cc = $intext eq substr($target, 0, $len1);
    #debug_print("inclusiveEquals: $cc");
    return $cc;
}

# $bool = isLang($selector)
# true if the selector is language selector (language code)
# otherwise the selector is version selector which starts with dot '.'
sub isLang {
    my $s = shift;
    return not $s =~ /\./;
}

# $bool = isSameType($sel1, $sel2)
# true if both selectors are the same type; both langs or both versions
sub isSameType {
    my ($s1, $s2) = @_;
    return (isLang($s1) && isLang($s2)) || (!isLang($s1) && !isLang($s2));
}

# $self->handleLine($output, $line)
sub handleLine {
    my ($self, $output, $line) = @_;

    # explicit end marker - /end/ or /any/
    if ($line =~ /^\/(end|any)\/\s*$/) {
        $self->{dbg_prev} = "[@{$self->{stack}}]";
        pop @{$self->{stack}};
        debug_print("END: $self->{dbg_prev} > [@{$self->{stack}}]");
        $self->{dbg_chgd} = true;
    }
    # in-text selector - /selector/
    elsif ($line =~ /^\/([\w.]+)\/\s*$/) {
        my $selector = $1;
        $self->{dbg_prev} = "[@{$self->{stack}}] > \"" . ($selector // '') . '"';
        my $top = $self->{stack}->[-1];
        if (@{$self->{stack}} == 2) {
            if (isSameType($selector, $top)) {
                pop @{$self->{stack}};
            }
            else {
                pop @{$self->{stack}};
                pop @{$self->{stack}};
            }
        }
        elsif (@{$self->{stack}} == 1) {
            if (isSameType($selector, $top)) {
                pop @{$self->{stack}};
            }
        }
        push(@{$self->{stack}}, $selector);
        debug_print("SEL: $self->{dbg_prev} > [@{$self->{stack}}]");
        $self->{dbg_chgd} = true;
    }
    else {
        # check language selector
        my $langOK = true;
        my @lang = grep { isLang($_) } @{$self->{stack}}; # only one
        # print STDERR "intext: " . Dumper($lang[0]);
        # print STDERR "target: " . Dumper($self->{lang});
        if (@lang > 0) {
            # if lang specified then check it
            $langOK = $lang[0] eq $self->{lang};
        }
        # check version selector
        my $verOK = true;
        my @ver = grep { !isLang($_) } @{$self->{stack}}; # just one
        if (@ver > 0) {
            # if version specified then at least one of target selectors must match
            $verOK = false;
            foreach my $t (@{$self->{selectors}}) {
                if (isLang($t)) { next; } # ignore language if exists
                if (inclusiveEquals($ver[0], $t)) { $verOK = true; last; }
            }
        }
        if ($self->{dbg_chgd}) {
            debug_print(
                'LANG "' . ($lang[0] || '') . '" ' . ($langOK ? '+' : '-') .
                ' | VER "' . ($ver[0] || '') . '" ' . ($verOK ? '+' : '-') );
            $self->{dbg_chgd} = false;
        }
        if ($langOK && $verOK) { print $output $line; }
    }
}

# processFile($input, $output, \%state)
# see handleLine() for parameters passed through \%state
sub processFile {
    my ($input, $output, $state) = @_;
    my $sel = new Selector($state);
    foreach my $line ( <$input> ) {
        if ($line =~ /^(\/[\w.]+\/)\s*([^\s].*)$/) { # allow /marker/ text...
            my $marker = $1;
            $line = $2 . "\n";
            $sel->handleLine($output, $marker); # pass marker alone then the rest
        }
        $sel->handleLine($output, $line);
    }
}

# (cf. PreproContext::selectTargetLanguage)
# $targetLanguage = selectLanguage(\@specifiedLanguages, \@availableLanguages)
# find the first selector in supplied languages that matches one of supported languages.
# DEFLANG (en) if no match found
sub selectLanguage {
    my ($spec_ref, $avail_ref) = @_;
    my @spec = @{$spec_ref};
    if (@spec == 0) { return DEFLANG; } # fail-safe
    my @avail = @{$avail_ref};
    if (@avail == 0) { return $spec[0]; } # first one if no avail
    foreach my $s (@spec) {
        if (grep { $s eq $_ } @avail) { return $s; }
    }
    return DEFLANG; # fail-safe
}

# standalone startup code
if ($0 =~ /\bSelector.pm$/) {
    my @slangs = (); # selected, specified or accepted languages
    my @alangs = (); # available or supported languages
    my @selectors = (); # version selectors

    # Usage: Selector.pm [--debug] [--select <langs>] [--available <langs>] [--versions <selectors>] 
    GetOptions (
        'debug' => sub { Parser::setDebug(true); },
        'select|s=s' => sub { @slangs = split(/,/, $_[1]); },
        'available|a|l=s' => sub { @alangs = split(/,/, $_[1]); },
        'versions|v=s' => sub { @selectors = split(/,/, $_[1]); }
    )
    or die "Usage: Selector.pm --select langs --available langs --versions selectors";

    debug_print("slangs = " . Dumper(\@slangs));
    debug_print("alangs = " . Dumper(\@alangs));
    debug_print("selectors = " . Dumper(\@selectors));

    # determine target language
    my $lang = selectLanguage(\@slangs, \@alangs);
    debug_print("selectedLanguage: $lang");

    my $input = \*STDIN;
    my $output = \*STDOUT;
    my $state = { lang => $lang };
    if (@selectors > 0) { $state->{selectors} = \@selectors; }
    processFile($input, $output, $state);
}

true; # need to end with a true value
