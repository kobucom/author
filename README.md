# PREPRO - Markdown Preprocessors in Perl

## Introduction

The tools in this project, with a help of a Markdown-to-HTML converter, can produce an HTML file from a Markdown source text intermixed with specially-designed, value-added syntax.

You can author multi-language text, simple drawings, specify stylesheet classes, etc., using the syntax.

## Preprocessors

The preprocessing tools, written in perl, published here includes:

| Tool | File | Description |
|--|--|--|
| File Loader | Include.pm | Loads a local file or remote web content into the source file |
| Passage Selector | Selector.pm | Used for writing articles in more than one language at the same time in the same file |
| Style Marker | Style.pm | Adds an HTML DIV element with a specified stylesheet class name |
| HereDoc Emulator | HereDoc.pm | Allows you to write a reference to an environment variable in the source |
| Simple SVG Chart Generator | Draw.pm | Embeds a small inline SVG chart using a simple text instruction | 
| General-Purpose Parser | Parser.pm | Concatenates preprocessors with pipes |

## Configurations

The preprocessors can be used with any type of source text files: plain text or many variety of wikitext formats.

Also there are many ways the tools can be used.
A Markdown file can be converted to HTML on your local PC.
The preprocessors can be incorporated in a web server such as Apache on a server so that conversion occurs automatically and dynamically.

Here I introduce **local** or **command line** configuration.

>TODO: Update README-onweb.md and publish again.

## Local, command-line configuration

The preprocessors are written in Perl scripting language.
It runs anywhere you can run a Perl program.
The example below uses a Linux command line terminal.

>The `sample` directory contains a sample prepro-marked markdown file and a shell script to run the preprocessors and pandoc command. 

First set the `PREPRO_AUTHOR` environment variable so that it points to a directory you have placed the perl files:

```
$ export PREPRO_AUTHOR=~/author/prepro
```

To create a Markdown file with Japanese content (sample-ja.md) from passage-marked source (sample.md):

```
$ ./Selector.pm --select ja < sample.md > sample-ja.md
```

You need some tool to convert the resultant markdown file to produce a final representation format such as HTML or PDF.

Linux has some tools to do that: for example, **Pandoc** command can process a Github-flavoured Markdown file and generate HTML and other formats.

```
$ pandoc -f gfm sample-ja.md -o sample-ja.html
```

You can concatenate some or all preprocessors together to let them process their own syntax using UNIX pipe:

```
$ ./Include.pm < sample.md | .Selector.pm --select ja | ./Style.pm | ./Draw.pm | pandoc -f gfm -o sample-ja.html
```

## Additional Information

A brief introduction page describes what and how you can do with these tools:

- [English](https://kobu.com/author/index-en.html)
- [Japansese](https://kobu.com/author/index.html)

See the documentation of the tools:

- [English](https://kobu.com/author/guide.html)
- [Japansese](https://kobu.com/author/guide-en.html)

For a tool by tool syntax summary, see [syntax.html](https://kobu.com/author/syntax.html) (English).

For architecture and background behind the tools, see [arch.html](https://kobu.com/author/arch.html) (English).

## License

Copyright (c) 2020 Kobu.Com. Some Rights Reserved.
Distributed under GNU General Public License 3.0.
Contact Kobu.Com for other types of licenses.

## History

2020-apr-08 first edition  
2020-apr-20 second edition  
2020-aug-31 changes in marker placement rules  
2020-oct-08 third edition
