#!/usr/bin/env perl

package Include;

# file includer 
# 20-oct-07 written and tested

# !@path! - includes local path optionally appending DOCUMENT_ROOT
# !%path! - includes remote content

use strict;
use warnings;

use Getopt::Long;

use lib "$ENV{PREPRO_AUTHOR}";
use Parser qw(debug_print warn_print);

# debug
use Data::Dumper qw(Dumper);

# constants
use constant { true => 1, false => 0 };

# getLocalFile($output, $path, [\%state])
# state: root => optional DOCUMENT_ROOT for local path
sub getLocalFile {
    my ($output, $path, $state) = @_;
    debug_print("path: $path");
    if ($state && $state->{root}) {
        if ($path !~ '^/') { $path = '/' . $path; } # add slash if missing
        $path = $state->{root} . $path;
        debug_print("path: $path");
    }
    if (open my $fh, "<", $path) {
        while (<$fh>) { print $output $_; }
        close $fh;
    }
    else {
        warn_print("$path: not found");
        print $output "\n !\@$path! - include file not found\n\n";
    }
}

# getRemoteContent($output, $url)
sub getRemoteContent {
    my ($output, $url) = @_;
    debug_print("url: $url");
    if (open my $fh, "|-", "curl -s $url") {
        while (<$fh>) { print $output $_; }
        close $fh;
    }
    else {
        warn_print("$url: url unavailable");
        print $output "\n !%$url! - include url unavailable\n\n";
    }
}

# processFile($input, $output, [\%state])
# state: see getLocalFile()
sub processFile {
    my ($input, $output, $state) = @_;
    while ( my $line = <$input> ) {
        if ($line =~ /^!@([^!]+)!\s*$/) { # !@path!
            my $path = $1;
            getLocalFile($output, $path, $state);
        }
        elsif ($line =~ /^!%([^!]+)!\s*$/) { # !%url!
            my $url = $1;
            getRemoteContent($output, $url);
        }
        else {
            print $output $line;
        }
    }
}

# standalone startup code
if ($0 =~ /\bInclude.pm$/) {
    my $root = undef;

    # Usage: Include.pm [--debug]
    GetOptions ('debug' => sub { Parser::setDebug(true); }, 'root=s' => \$root);

    my $input = *STDIN;
    my $output = *STDOUT;
    processFile($input, $output, $root ? { root => $root } : undef);
}

true; # need to end with a true value
