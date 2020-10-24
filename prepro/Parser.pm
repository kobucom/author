#!/usr/bin/perl

package Parser;

# general-purpose span-level parser - parseLine()
#
# Copyright (c) 2020 Kobu.Com. Some Rights Reserved.
# Distributed under GNU General Public License 3.0.
# Contact Kobu.Com for other types of licenses.
#
# currently only provides parseLine()
# 20-sep-24 parseBlock - not any more
# 20-sep-29 parseLine <- Embedder::handleMacros
# 20-sep-29 parseLine tested
# 20-oct-06 merged with ParserUtil

use strict;
use warnings;

require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(parseLine debug_print warn_print trim flatten);

use IO::Pipely qw(pipely);

# debug
use Data::Dumper qw(Dumper);

# constants
use constant { true => 1, false => 0 };

# [cf. Util:removeCRLF]
# $line = flatten($lines)
# convert newlines to a space
sub flatten {
    my $str = shift;
    $str =~ s/\s+/ /g;
    return $str;
}

# $str = trim($str)
# removes leading and trailing white spaces
# chomp only removes trailing spaces
sub trim {
	my $str = shift;
	$str =~ s/^\s+|\s+$//g;
	return $str;
}

{
    my $debug = 0; # output debug text to stderr

    # setDebug($flag)
    sub setDebug {
        $debug = $_[0];
    }

    # debug_print($str)
    # print debug output to stderr if $debug is true
    sub debug_print {
        my $str = shift;
        if ($debug) { print STDERR '[DEBUG] ' . $str . "\n"; }
    }

    # warn_print($str)
    # print warning to stderr but don't quit
    # use die to print error and quit
    sub warn_print {
        my $str = shift;
        print STDERR '[WARN] ' . $str . "\n";
    }
}

# span handlers table for parseLine()
# - testpat (optional)
#   can be defined if the pattern is very complicate and time-consuming
# - pattern (mandatory) full pattern
#   may include a single (...) to extract further inner part 
# - flags (optional) list of flags
#   not defined yet
# - code (mandatory)
#   $replaced = callback($span, [\%gstate, [\%lstate]])
#   span - $1 (first capture match) if it is defined otherwise $& (entire match).
#   * if you insert capture paren in the pattern $1 is always defined ('' if no match)
#     if you don't use capture paren then $1 is undefined
#     you can reference $&, $1, $2 ... regardless what $span holds
#   gstate - optional state
#   lstate - extra optional state
#   * reason why two sets of states can be passed: Embedder's older handleMacros()
#     accepted two hashes as parameters: $context and $row; in general, these are
#     considered 'global' state kept across multiple calls and per-call 'local' state.
#
# my @sampleHandlers = ( # array of hash references
#     {
#         testpat => '\$\(',
#         pattern => '\$\((\w+)\)',
#         flags => [],
#         code => sub {
#             # $callback->($span, [\%gstate, [\%lstate]]);
#             my ($span, $gstate, $lstate) = @_;
#             return uc $span;
#         }
#     }
# );

# $replaced_line = parseLine($line, \@handlers, [\%gstate, [\%lstate]])
# matches 'pattern' in 'handlers' and call 'code' for each occurrence of the line.
# each pattern is tested against the line, result of the previous search and replace,
# one by one in the order specified in the handlers table.
sub parseLine {
    my ($line, $handlers, $gstate, $lstate) = @_;
    for my $handler (@{$handlers}) {
        if ($handler->{testpat} && $line !~ $handler->{testpat}) { next; }
        my $pattern = $handler->{pattern};
        my $outstr = '';
        while (true) {
            # Note about pattern extraction:
            # ${^MATCH} etc. are available only if modifier 'p' specified while
            # $& / $` / $' are always available but generated even when unnecessary
            if ($line =~ /$pattern/p) {
                # trace("parseLine: '${^PREMATCH}' << '${^MATCH}' >> '${^POSTMATCH}'");

                # preserve matched portions (to avoid accidental destruction in further re use)
                my $prematch = ${^PREMATCH};
                my $span = $1 // ${^MATCH}; # 'abc' if /abc/ or 'b' if /a(b)c/
                my $postmatch = ${^POSTMATCH};

                # output fragment prior to matched part
                $outstr .= $prematch;

                # call sub and get replacement as return value
                my $replaced = $handler->{code}($span, $gstate, $lstate);
                $outstr .= ($replaced // '');

                # handle fragment following matched part in next loop
                $line = $postmatch;
            }
            else {
                $outstr .= $line; # rest of the line
                last;
            }
        }
        $line = $outstr; # pass replaced line to next handler
    }
    return $line;
}

true; # need to end with a true value
