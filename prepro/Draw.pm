#!/usr/bin/env perl

package Draw;

# Draw.pm - draw simple svg charts from simple instructions
#
# Copyright (c) 2020 Kobu.Com. Some Rights Reserved.
# Distributed under GNU General Public License 3.0.
# Contact Kobu.Com for other types of licenses.
#
# 2020-apr-14 started; box
# 2020-apr-15 ball, paper
# 2020-apr-16 text centering
# 2020-sep-28 draw.pl -> Draw.pm

use strict;
use warnings;

use POSIX; # floor
use Getopt::Long;

use lib "$ENV{PREPRO_AUTHOR}";
use Parser qw(debug_print warn_print trim);

# debug
use Data::Dumper qw(Dumper);

# constants
use constant { true => 1, false => 0 };

{
    # cell syntax:
    #  shape "text" [hand]  hand is optional
    #  shape "" [hand]      no text
    #  ~                    blank cell
    # shape:
    #  box    rounded-corner rectangle
    #  ball   ellipse
    #  paper  rectangle (polygon) with upper right corner cut
    #  disk   rectangle with double top/bottom lines
    #  ~      blank
    # hand:
    #   -  left line
    #   |  down line
    #   +  left and down lines
    #   ~  blank

    # drawing parameters (constants)
    my $CW = 150; # cell dimension
    my $CH = 100;
    my $SW = 100; # shape dimension (centered within cell)
    my $SH = 50;
    my $GX = 5;   # line gap at one side; zero touches the shape
    my $GY = 5;

    # <svg> style values (constants)
    my $SVG_STYLE="fill:gainsboro;stroke:gray;stroke-width:1"; # <svg style="...">
    my $TEXT_STYLE="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle"; # <text style=...>
    my $LINE_STYLE="opacity:0.75"; # <line style=...>
    my $SHAPE_STYLE="stroke-width:2;opacity:0.5"; # box, ball
    my $PAPER_STYLE="fill:white"; # paper, disk

    # drawShape($output, $cell, $curX, $curY)
    # draw a shape, text and hands (lines hanging left and/or down)
    sub drawShape {
        my ($output, $cell, $curX, $curY) = @_;
        my $shape;
        my $hand;
        my $text;

        # assumption: already trimed both ends
        if ($cell eq "" || $cell =~ /^~+$/) { # "" or "~" or "~~"
            return;
        }
        elsif ($cell =~ /^([^ ]+?)\s*["'](.*)["']\s*(.*)$/ ) { # shape "text" hand
            $shape = $1;
            $text = $2;
            $hand = $3;
        }
        else {
            warn_print("wrong shape syntax: '$cell'");
            return;
        }

        debug_print "drawshape: shape='$shape', text='$text', hand='$hand'";

        # useful dimensions
        my $cx = $curX + floor($CW / 2); # center
        my $cy = $curY + floor($CH / 2);
        my $mx = floor(($CW - $SW) / 2); # margins
        my $my = floor(($CH - $SH) / 2); 
        my $ux = $curX + $mx; # upper left
        my $uy = $curY + $my;
        my $lx = $curX + $CW - $mx; # lower right
        my $ly = $curY + $CH - $my;

        # shape
        if ($shape eq "box") {
            print $output "<rect x=\"$ux\" y=\"$uy\" rx=\"10\" ry=\"10\" width=\"$SW\" height=\"$SH\" style=\"$SHAPE_STYLE\" />\n";
        }
        elsif ($shape eq "ball") {
            my $rx = floor($SW / 2); # radius
            my $ry = floor($SH / 2);
            print $output "<ellipse cx=\"$cx\" cy=\"$cy\" rx=\"$rx\" ry=\"$ry\" style=\"$SHAPE_STYLE\" />";
        }
        elsif ($shape eq "paper") {
            my $points = $ux . ',' . $uy . ' ' . $ux . ',' . $ly . ' ' . $lx . ',' . $ly . ' ' .
                $lx . ',' . ($uy + 10) . ' ' . ($lx - 10) . ',' . $uy;
            print $output "<polygon points=\"$points\" style=\"$PAPER_STYLE\" />";
        }
        elsif ($shape eq "disk") {
            my $x = $ux;
            my $y = $uy;
            my $w = $SW;
            my $h = $SH;
            print $output "<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" style=\"$PAPER_STYLE\" />\n";
            my $capY = floor($SH / 10); # inner lines at the top and bottom of one tenth of height
            $y += $capY;
            $h -= $capY * 2;
            print $output "<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" style=\"$PAPER_STYLE\" />\n";
        }
        else {
            if ($shape !~ /^~+$/) { warn_print("no such shape: $shape"); }
            # no shape but allow text and hand to be drawn
        }

        # text
        if ($text) {
            print $output "<text x=\"$cx\" y=\"$cy\" style=\"$TEXT_STYLE\">$text</text>\n";
        }

        # lines to draw
        my $left = 0;
        my $down = 0;

        # hand
        if ($hand eq "-") { # line to left
            $left = 1;
        }
        elsif ($hand eq "|") { # down line
            $down = 1;
        }
        elsif ($hand eq "+") { # left and down
            $left = $down = 1;
        }
        else {
            if ($hand && $hand ne "~") { warn_print("no such hand: $hand"); }
            # no lines to draw
        }

        # draw line(s)
        if ($left) {
            my $lx1 = $curX + $CW - $mx + $GX;
            my $ly1 = $cy;
            my $lx2 = $curX + $CW + $mx - $GX;
            my $ly2 = $cy;
            print $output "<line x1=\"$lx1\" y1=\"$ly1\" x2=\"$lx2\" y2=\"$ly2\" style=\"$LINE_STYLE\" />\n";
        }
        if ($down) {
            my $lx1 = $cx;
            my $ly1 = $curY + $CH - $my + $GY;
            my $lx2 = $cx;
            my $ly2 = $curY + $CH + $my - $GY;
            print $output "<line x1=\"$lx1\" y1=\"$ly1\" x2=\"$lx2\" y2=\"$ly2\" style=\"$LINE_STYLE\" />\n";
        }
    }

    # block syntax
    #  !draw!
    #  cell; cell; ...
    #  cell; cell; ...
    #  ...
    #  !end!
    #
    # number of shapes per row can be variable
    # blank row allowed; space will be taken
    # blank cell allowed as:
    #  ;shape;;shape or ~;shape;~;shape

    # draw($output, \@rows, $maxColLen)
    # called when end mark is seen to produce <svg> element
    sub draw {
        my ($output, $rows_ref, $maxColLen) = @_;
        my @rows = @{$rows_ref};
        # determine canvas size
        my $rlen = @rows;
        debug_print("draw: rows = [$rlen x $maxColLen] " . Dumper(\@rows));
        my $width = $CW * $maxColLen;
        my $height = $CH * $rlen;
        # top left corner of the current cell; updated for each call to drawShape()
        my $curX = 0;
        my $curY = 0;
        # start tag
        print $output "<svg width=\"$width\" height=\"$height\" style=\"$SVG_STYLE\">\n";
        for my $cols (@rows) {
            my $clen = @{$cols};
            debug_print "draw: row = [$clen] @{$cols}";
            for my $col (@{$cols}) {
                debug_print "draw: col = $col\n";
                drawShape($output, $col, $curX, $curY);
                # advance x
                $curX += $CW;
            }
            # advance y; reset x
            $curY += $CH;
            $curX = 0;
        }
        # end tag
        print $output "Inline SVG not supported by your browser\n";
        print $output "</svg>\n";
    }
}

# processFile($input, $output)
sub processFile {
    my ($input, $output) = @_;
    my @rows = (); # rows of columns of shapes
    my $maxColLen = 0; # number of columns of the widest row
    my $collecting = false;

    while ( my $line = <$input> ) {
        if ($line =~ /^!draw!\s*$/) { # !draw!
            $collecting = true;
        }
        elsif ($line =~ /^!end!\s*$/) { # !end!
            draw($output, \@rows, $maxColLen);
            @rows = ();
            $maxColLen = 0;
            $collecting = false;
        }
        else {
            if ($collecting) {
                # drawings separated with semicolon turned into an array,
                # add it to array of rows
                $line = trim($line);
                my @cols= split /\s*;\s*/, $line; # ..; ..; ..
                my $len = @cols;
                debug_print("collect: [$len] @cols");
                push(@rows, \@cols);
                if ($len > $maxColLen) { $maxColLen = $len; }
            }
            else { print $output $line; }
        }
    }

    if ($collecting) { warn_print("Draw end mark missing."); }
}

# standalone startup code
if ($0 =~ /\bDraw.pm$/) {
    # Usage: Draw.pm [--debug]
    GetOptions ('debug' => sub { Parser::setDebug(true); });

    my $input = *STDIN;
    my $output = *STDOUT;
    processFile($input, $output);
}

true; # need to end with a true value
