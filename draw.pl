#!/usr/bin/perl

# draw.pl - draw simple svg charts from simple instructions
# 2020-apr-14 started; box
# 2020-apr-15 ball, paper
# 2020-apr-16 text centering

use strict;
use warnings;
use POSIX; # floor

my $debug = 0; # -d option - output debug text within the output
my $lineCount = 0;

# fuctions

# print warning to stderr but don't quit
# use die to print error and quit
sub warn_print {
    print STDERR '[WARN] ' . shift . " at line $lineCount\n";
}

# print output intermixed into stdout if $debug is true
sub debug_print {
    if ($debug) { print '[DEBUG] ' . shift . "\n"; }
}

# trim() removes leading and trailing spaces
# chomp only removes trailing spaces
sub trim {
	my $str = shift;
	$str =~ s/^\s+|\s+$//g;
	return $str;
}

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

# drawing parameters
my $CW = 150; # cell dimension
my $CH = 100;
my $SW = 100; # shape dimension (centered within cell)
my $SH = 50;
my $GX = 5;   # line gap at one side; zero touches the shape
my $GY = 5;

# <svg> style values
my $SVG_STYLE="fill:gainsboro;stroke:gray;stroke-width:1"; # <svg style="...">
my $TEXT_STYLE="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle"; # <text style=...>
my $LINE_STYLE="opacity:0.75"; # <line style=...>
my $SHAPE_STYLE="stroke-width:2;opacity:0.5"; # box, ball
my $PAPER_STYLE="fill:white"; # paper, disk

# top left corner of the current cell; set by draw()
my $curX = 0;
my $curY = 0;

# draw a shape, text and hands (lines hanging left and/or down)
sub drawShape {
    my $cell = shift;
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
        print "<rect x=\"$ux\" y=\"$uy\" rx=\"10\" ry=\"10\" width=\"$SW\" height=\"$SH\" style=\"$SHAPE_STYLE\" />\n";
    }
    elsif ($shape eq "ball") {
        my $rx = floor($SW / 2); # radius
        my $ry = floor($SH / 2);
        print "<ellipse cx=\"$cx\" cy=\"$cy\" rx=\"$rx\" ry=\"$ry\" style=\"$SHAPE_STYLE\" />";
    }
    elsif ($shape eq "paper") {
        my $points = $ux . ',' . $uy . ' ' . $ux . ',' . $ly . ' ' . $lx . ',' . $ly . ' ' .
            $lx . ',' . ($uy + 10) . ' ' . ($lx - 10) . ',' . $uy;
        print "<polygon points=\"$points\" style=\"$PAPER_STYLE\" />";
    }
    elsif ($shape eq "disk") {
        my $x = $ux;
        my $y = $uy;
        my $w = $SW;
        my $h = $SH;
        print "<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" style=\"$PAPER_STYLE\" />\n";
        my $capY = floor($SH / 10); # inner lines at the top and bottom of one tenth of height
        $y += $capY;
        $h -= $capY * 2;
        print "<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" style=\"$PAPER_STYLE\" />\n";
    }

    else {
        if ($shape !~ /^~+$/) { warn_print("no such shape: $shape"); }
        # no shape but allow text and hand to be drawn
    }

    # text
    if ($text) {
        print "<text x=\"$cx\" y=\"$cy\" style=\"$TEXT_STYLE\">$text</text>\n";
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
        print "<line x1=\"$lx1\" y1=\"$ly1\" x2=\"$lx2\" y2=\"$ly2\" style=\"$LINE_STYLE\" />\n";
    }
    if ($down) {
        my $lx1 = $cx;
        my $ly1 = $curY + $CH - $my + $GY;
        my $lx2 = $cx;
        my $ly2 = $curY + $CH + $my - $GY;
        print "<line x1=\"$lx1\" y1=\"$ly1\" x2=\"$lx2\" y2=\"$ly2\" style=\"$LINE_STYLE\" />\n";
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

my @rows = (); # rows of columns of shapes
my $maxColLen = 0; # number of columns of the widest row

# called when end mark is seen to produce <svg> element
sub draw {
    # reset coords
    $curX = $curY = 0;
    # determine canvas size
    my $rlen = @rows;
    debug_print "draw: rows = [$rlen x $maxColLen] @rows";
    my $width = $CW * $maxColLen;
    my $height = $CH * $rlen;
    # start tag
    print "<svg width=\"$width\" height=\"$height\" style=\"$SVG_STYLE\">\n";
    for my $cols (@rows) {
        my $clen = @{$cols};
        debug_print "draw: row = [$clen] @{$cols}";
        for my $col (@{$cols}) {
            debug_print "draw: col = $col\n";
            drawShape($col);
            # advance x
            $curX += $CW;
        }
        # advance y; reset x
        $curY += $CH;
        $curX = 0;
    }
    # end tag
    print "Inline SVG not supported by your browser\n";
    print "</svg>\n";
    # reset collection
    @rows = ();
}

# collect a row of drawings separated with semicolon
# into an array and add it to array of rows
sub collect {
    my $line = shift;
    $line = trim($line);
    #debug_print "collect: trimmed: '$line'\n";
	my @cols= split /\s*;\s*/, $line; # ..; ..; ..
    my $len = @cols;
    debug_print "collect: [$len] @cols";
    push(@rows, \@cols);
    if ($len > $maxColLen) { $maxColLen = $len; }
}

# main code

# Usage: draw.pl [-d]
foreach my $arg (@ARGV) {
    if ($arg =~ '^-d$') { $debug = 1; }
    else { die "[ERROR] Usage: draw.pl [-d]... no such option: $arg"; }
}

my $collecting = 0;

foreach my $line ( <STDIN> ) {
    $lineCount++;
    if ($line =~ /^!draw!\s*$/) { # !draw!
        $collecting = 1;
    }
    elsif ($line =~ /^!end!\s*$/) { # !end!
        draw();
        $collecting = 0;
    }
    else {
        if ($collecting) { collect($line); }
        else { print $line; }
    }
}

if ($collecting) { warn_print "Draw end mark missing."; }
