# Simple SVG Chart Generator

2020-apr-16 first edition

## Introduction

The SVG chart generater is a Perl script (draw.pl) for generating a very simple configuration-type chart like the one below with limited but simple instructions.

!draw!
box "PC" -; paper "File" -; box "Server" -; disk "Disk"
!end!

The generator allows you to draw a limited number of simple shapes (such as squares or circles) with a text description and connect them horizontally and vertically.

The generator reads a specially marked block of drawing instructions from a source txt and converts the block into an inline SVG element.

>SVG stands for Scalable Vector Graphics. It is a part of HTML5 specification and every major modern browser supports drawing of SVG graphics. An SVG element can directly be inserted in an HTML or stored in a separate file. The generator embeds an SVG element in the converted output. 

## Background

It is not a general purpose tool anyone with any purposes can use.
Rather it is for someone who wants to keep working with text while preparing just a simple chart rather than switching to a dedicated image drawing tool or drawing feature of an office product.

A good thing about this tool is that you don't have to carry image files together with a main source file if you only need small figures.

This tool is meant to add a simple visual cue to help a reader understand the surrounding body sentences well with minimum effort on the side of an author involving image drawing work.

## Drawing Block (Grid of Cells)

A block of drawing instructions in a source text is called a drawing block and enlcosed with begin and end markers.

The follwoing example is a chart describing what components appear when you use the generator:

```
 !draw!
 paper "Source" -; ball "draw.pl" -; paper "Output"
 !end!
```

This block will produce the following SVG drawing:

!draw!
paper "Source" -; ball "draw.pl" -; paper "Output"
!end!

A drawing block forms a grid structure.
A block can have one or more lines.
Each line draws a row of figures possibly connected with lines.
A row contains one or more columns (or cells) which include drawing instructions for one figure.

Syntax of a drawing block:

```
  !draw!
  cell; cell; ...
  cell; cell; ...
   ...
  !end!
```

A drawing marker is encosed in two exclamation marks (!...!).
The starting mark is '!draw!' on a line by itself.
The end mark is '!end!'.

A grid of two rows by three columns:

!draw!
box "Box 1.1" -; box "Box 1.2" +; box "Box 1.3"
~; box "Box 2.2"
!end!

was produced by a block:

```
 !draw!
 box "Box 1.1" -; box "Box 1.2" +; box "Box 1.3"
 ~; box "Box 2.2"
 !end!
```

The first row contains three figures.
The second row only contains a figure in the middle column.
Each row is terminated by a new line.
Columns are separated by a semicolon (;).
A column containing nothing or only a tilda (~) produces a blank cell, no figure in it.

As in the above example, the number of cells in a row may vary line by line.

## Cell (Shape with Text and Lines)

A cell portion contains an instruction to draw a figure (also called shape) with description text and/or lines to neighboring figures (called hands).

Syntax of a cell:

```
  shape "text" [hand]  hand is optional
  shape "" [hand]      no text
  ~                    blank cell
```

A shape is one of the following:

| Shape | Represents: | SVG element |
|--|--|--|
| box   | Hardware such as PC or server | Rounded-corner rectangle |
| ball  | software or process (shown as a rugby ball)| Ellipse |
| paper | File or resource | Rectangle (polygon) with upper right corner cut |
| disk  | File system or folder | Rectangle with double lines at top and bottom |
| ~     | Blank | - |

!draw!
box "Box"; ball "Ball"; paper "Paper"; disk "Disk"
!end!

A hand is a line drawn from the current cell to the neighbor cell.
The line can be drawn to the right-side and/or immediately lower figure.

!draw!
; box "" +; ~ "right"
; ~ "down"
!end!

A single-character symbol is used to denote a type of a hand:

| Hand | Direction |
|--|--|
| - | Line to the right |
| \| | Line going down |
| + | Lines going to the right and down |
| ~ | No line drawn |

Examples:

| Cell | Description |
|--|--|
| box "Box" | Just a box and a text |
| ball "Ball" - | A rugby ball with a line connecting to the right figure |
| paper "Paper" + | A paper with both the right and down lines | 
| disk "Disk" \| | A disk with a line connecting to the figure below |

How they look like in a horizontal order:

!draw!
box "Box"; ball "Ball" -; paper "Paper" + ; disk "Disk" |
!end!

## Command line

The perl script for the generator is named 'draw.pl'.
It can be run anywhere you can run Perl interpreter, for example in a Linux terminal:

```
 $./draw.pl < sample.md > sample-svg.md
```

The above command reads 'sample.md' which includes marked drawing blocks, replaces the blocks with SVG elements and produces the output in 'sample-svg.md'.

The next example shows a use of the generator together with the passage selector loader (rep.pl) and 'pandoc' used to convert a Markdown text to HTML in one-line command.

```
 $./draw.pl < sample.md | ./rep.pl -sja | pandoc -f gfm -t html5 ... > sample-ja.html
```
