# Passage Selector in Perl

2020-apr-8 first edition  
2020-apr-20 second edition  
2020-aug-31 changes in marker placement rules

This program is formerly called 'Replacer' so the text below contains this name.

This document has two parts: a guide to get familiar with passage marking and a reference describing acceptable source syntax.

The last section of the guide describes configurations where Replacer can be used.
The section also describes one such configuration where you keep files locally and generate final outputs in your PC.

A separate document, [README-onweb](README-onweb.md), describes another configuration where you keep source files on a web server and conversion is automatically done on the web server when a file is requested.

## Changes

Changes in Marker Placement Rules (2020-aug-31)

- A marker can be placed at the beginning of a line.
- A new `/any/` can be used as a synonym of `/end/`.

Changes in Second Edition (2020-apr-20)

- Multiple target selectors can be specified (-s option changed)
- Available languages can be specified (-l option added)
- Language selectors and dot-prefixed version selectors are separated
- tow-level selector stack (language and version selection can be nested each other)
- Loader function removed (no more -p option)

# Part One: Guide

## Introduction

The Replacer reads souce text mixed with passages for different purposes and writes the output containing only the selected passages.

!draw!
paper "Source" -; ball "Replacer" -; paper "Output"
!end!

For example, Replacer can select text written in a specified language and for a specific version.

## Passage and Selector

Let me introduce some important words:

A **passage** is a part of text such as one or more sentences, one or more paragraphs, sections or chapters of a web page or document.

A source text passed to Replacer can cocntain passages for differnt purposes.
For example, a single source file can contain passages for multiple languages and/or multiple versions.
A **selector** is used to specify which passages should be output for a final output to meet a specific purpose.

To create a Japanese document, only Japanese passages are taken:

| | Source | | Output | |
|--|--|--|--|--|
|  | English |  |  |  |
|  | Japanese | -> | Japanese |  |
|  | English |  |  |  |
|  | Japanese | -> | Japanese |  |

Command line arguments to Replacer for selecting passages that are included on each conversion is called **target selector** while selectors in the source text is called **in-text selectors**.

## Passage-Marked Text Examples

A source text intermixed with in-text selectors is called **passage-marked** text.

Here is a simple source text with selectable passages for two languages.

```
 This is a common part for any languages.
 /en/
 This text is included when the request language is English.
 /ja/
 This text is for Japanese only.
 /end/
 This again included for every output.
```
A marker enclosed in two slasshes (/.../) is called a selector (precisely in-text selector).
In this case, a passage following `/en/` is in English and `/ja/` in Japanese.
A passage continues until a new selector appears or `/end/` marker appears.
The end marker resets a passage selection.
[2020-aug-31] A selector of `/any/` is a synonym of `/end/`.

If you want to produce a document in English, you tell Replacer the target selector is `en`.
The replacer output will be:

```
 This is a common part for any languages.
 This text is included when the request language is English.
 This again included for every output.
```

In addition to language selectors, you can use version selectors to deepen your selection:

```
 /ja/
 Text for all Japanese versions.
 /.v2/
 This is only for version 2 of the document.
 /end/
 This is again for all Japanese versions.
 /end/
 End of Japanese passages.
```

If you specify the target selector of `ja` you will get:

```
 Text for all Japanese versions.
 This is again for all Japanese versions.
 End of Japanese passages.
```

while you get the following if you specify `ja` and `.v2`:

```
 Text for all Japanese versions.
 This is again for all Japanese versions.
 This is again for all Japanese versions. <-- added
 End of Japanese passages.
```

[2020-aug-31] For convenience, a marker can appear at the beginning of line.
A newline can be omitted.
You can insert a space between the marker and the following text.
Or the text can follow immediately after the marker.
A newly-introduced marker of `/any/` can be used in place of `/end/`.
The first example can be written as below.

```
 This is a common part for any languages.
 /en/ This text is included when the request language is English.
 /ja/This text is for Japanese only.
 /any/ This again included for every output.
```

> Note that a marker cannot appear at the end of a line.
This rule is for readability (you can easily miss a marker at the end of a paragraph).



## Configurations

The Replacer can be used with any type of source text files: plain text or many variety of wikitext formats.
Also there are many ways the Replacer can be used.

In this secion, let me explain how Replacer can be used using a bare minimum configuration, called **local** or **command line** configuration.
This configuration does not suit to non-technical users.
However, I recommend to read through this section in order to understand steps for processing passage-marked text.

> See [README-onweb](README-onweb.md) to do all conversion automatically online.

You have three steps to do to make a final document available to readers from a passage-marked source text using the Replacer.

- passage selection for a specific purpose (work of Replacer)
- conversion to final presentation format (work of a converter)
- publishing (uploading to web server or sending via email)

The next section describes how to create a web page from a passage-marked markdown file all on your local PC by using command line programs.

## Local, command-line configuration

The Replacer program is written in Perl scripting language.
It runs anywhere you can run a Perl program.
Most Unix-based environments, such as Linux and MacOS, come with a perl interpreter already installed.
Windows users have two choices: install Windows version of perl interprepter such as ActivePerl or install a Unix environment such as Windows Subsystem for Windows.

To create a Markdown file with Japanese content (sample-ja.md) from passage-marked source (sample.md):

```
$ perl rep.pl -sja <sample.md >sample-ja.md
```

!draw!
paper "sample.md" -; ball "Replacer" -; paper "sample-ja.md"
!end!

You need some tool to convert the resultant markdown file to produce a final representation format such as HTML or PDF.

!draw!
paper "sample-ja.md" -; ball "Converter" -; paper "sample-ja.html"
!end!

Linux has some tools to do that: for example, 'pandoc' command can process a Github-flavoured Markdown file and generate HTML and other formats.

```
$ pandoc -f gfm sample-ja.md -o sample-ja.html
```

For your infomation, I use Visual Stduio Code (vscode) to edit and preview Markdown text and one of many Markdown extentions to produce HTML or PDF file output.
I beleive Visual Stduio is useful not only for programmers like me and also for writers, editors and translators.

Finally, you need some file transfer tool such as secure ftp to upload local files to your web server.

```
$sftp author@www.example.com
Password: .....
>cd /var/www/html
>put sample-ja.html
>put sample-en.html
>quit
```

!draw!
paper "sample-ja.html" -; ball "sftp" -; box "Server"
!end!

Now a browser user can access this file via URL of 'http://www.example.com/sample-ja.html'.

## Apache configuration

In a more advanced configuration, you don't need to do all of these steps manually.
All you have to do is to create and edit source files and everything else can be done automatically.

[README-onweb](README-onweb.md) describes how to incorporate Replacer into an Apache web server environment where storage of source files and all conversion works are done automatically on the server.

&nbsp;

# Part Two: Reference

## Command Line Arguments

Usage: rep.pl [-s<i>target-selectors</i>] [-l<i>available-languages</i>] < <i>input</i> > <i>output</i>
- -s<i>target-selectors</i> - one or more target language or version selectors
- -l<i>available-languages</i> - list of languages the document supports
- <i>input</i> - source file  
- <i>output</i> - output file

## Source text

A source text file processed by Replacer is called passage-marked text.
Text in the source is intermixed with passage markers enclosed in two slashes (/.../)

A source file without passage markers can be passed to Replacer.
Output is the same as the source file.

## Marker Syntax

Markers are inserted in a source file.
A marker is surrounded by a starting and ending slash (/) and occupies a line.
[2020-aug-31] Or it can appear exactly at the beginning of a line.

Markers in Replacer can have Roman alphabets in upper case (A-Z) and lower case (a-z), numbers (0-9) and some symbols (depending on the type of string or name).

List of markers:

| Marker | Syntax | Examples |
|--|--|--|
| Language selector | Language code (without regional code) | /en/, /ja/ |
| Version selector | Dot-delimited version selector; the first character must be a dot (.) | /.v2/, /.v2.r1/ |
| End marker | Ends the current selection of a language or version | /end/ or /any/ |

## Types of Selectors

There are two types of selectors: **language selectors** and **version selectors**.
A language selector selects a passage written in a certain language.
A language selector is a language code without regional code.
'en' is usable but 'en-us' is not.

Examples of language selectors:

- en
- ja
- kr
- fr

A version selector is used to select any kind of passages based on non-language criteria.
It can be used to specify selection of a product, target customer as well as versions.
It is called *version* selector assuming it is the most typical case.

A version selector is prefixed by a dot (.) in order to distinguish it from a language selector.
It has one or more *levels* and levels are delimited by a dot.

Examples of version selectors:
- .v2 (version 2)
- .v2.r1 (revision 1 of version 2)
- .debian vs .centos
- .centos.v8 (version 8 of centos)
- .technical vs .general

One note about difference between language and version selectors.
Only one target language is selected from a list of candidate languages.
More than one version selectors can be effective and all are used to select passages.
For example, either 'ja' or 'kr' is effective even if you specify both.
You can have '.v2' and '.debian' at the same time.

## Levels of Version Selectors

A language selector has no level.

A version selector can have multiple levels with delimiting dots.
A passage is selected if it is *inclusively equals* to the target version selector.

| | | | | |
|--|--|--|--|--|
| Target selector   | .v2  | .v2    | .v2.r1 | .v2.r1 |
| In-text selector  | .v2  | .v2.r1 | .v2    | .v2.r1 |
| Selected?         | Yes | No     | Yes    | Yes    |

## Nesting of Selectors

[2020-apr-20]

The second version of the Replacer supports two levels of nested passage selection: passages for a certain version within passages of a certain language or passages written in a certain language within passages of a certain version.

Example (languages then versions)
- en
  - .v2
  - .v2.r1
- ja
  - .v2
  - .v2.r1

Example (versions then languages)
- .v2
  - ja
  - en
- .v2.r1
  - ja
  - -en

## End marker

[2020-aug-31]

A new language or version marker resets passages for language and version respectively.

```
 /ja/
 Japanese
 /en/
 English
 /ja/
 Japanese again
 ...
```

You can explicitely end passages for a language or version using an end marker.
The end marker is `/end/` or `/any/`.
You can use either of them.

```
 /ja/
 Japanese
 /end/
 A passage for both English and Japanese
 /ja/
 Japanese again
 ...
```

## Specifyinig Target selector

Target selectors are passed to Replacer through a command line argument of the form -s<i>selectors</i> (hyhpen, lower case S, no space, followed by comma separated list of selectors).

You have to specify at least one language selector.
The replacer selects only one target language by matching the specified target languages with available languages (see below).

You can specify zero or more version selectors.
All the specified version selectors are in effect and used to match passages for a specific version.

Examples:
- '-sja' for Japanese text
- '-sja,.v2' for Japanese text and passages for the second version
- '-sja,kr,.v2,.v2.r2' specifies target languages `ja` and `kr` and versions `.v2` and `.v2.r2`

In the last case, an either `ja` or `kr` will finally be selected depending on the available languages described in the next section.

## Available Languages

[2020-apr-20]

There was a flaw in the first version of Replacer.
There is no mechanism to specify what languages a document is written.
Thus there is no way to tell whether you can get a version of the document in a certain language.

Version 2 of rep.pl supports specification of available languages with `-l` option.
If this option is specified, the Replacer matches the list of target language selectors one by one against a list of available languages and determines a the best target language to present the document in.
If it can't, a default language (a perl constant of DEFLANG in rep.pl) is used.

For example the target languages are (kr, ja, en) and available languages are (en, ja), `ja` is selected. `ja` is selected because it comes before `en` in the target selectors list.
