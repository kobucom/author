# Passage Selector Loader in Perl

2020-apr-8 first edition

This program is formerly called 'Replacer' so the text below contains this name.

This document has two parts: a guide to get familiar with passage marking and a reference describing acceptable source syntax.

The last section of the guide describes configurations where Replacer can be used.
The section also describes one such configuration where you keep files and generate final outputs all in your local PC.

A separate document, [README-onweb](README-onweb.md), describes another configuration where you keep source files on a web server and conversion is automatically done on the web server when a file is requested.

# Part One: Guide

## Introduction

The Replacer reads a souce test mixed with passages for different purposes and writes the output only with the selected passages.

!draw!
paper "Source" -; ball "Replacer" -; paper "Output"
!end!

For example, Replacer can select or load text written in a specified language and/or for a specific version.

## Passage and selector

Let me introduce some important words:

A **passage** is a part of text such as one or more sentences, one or more paragraphs, sections or chapters of a web page or document.

A source text passed to Replacer can cocntain passages for differnt purposes.
For example, a single source file can contain passages for multiple languages and/or multiple versions.
A **selector** is used to specify which passages should be output for a final output to meet a specific purpose.

To create a Japanese document, only Japanese passages are taken:

| | | | | |
|--|--|--|--|--|
|  | English |  |  |  |
|  | Japanese | -> | Japanese |  |
|  | English |  |  |  |
|  | Japanese | -> | Japanese |  |
|  |  |  |  |  |

In addition to a main source text file, you can prepare a passage of text as a separate file written for a specific purpose, such as a specific language or version.
This kind of files are called **loaded files** or just load files.
A location marker that specifies where a specific load file is loaded is called **load marker**.

!draw!
~;paper "Load file" |
paper "Source" -; ball "Replacer" -; paper "Output"
!end!

A criteria for selecting passages that are included on each conversion is called **target selector** while selectors in the source text is called **in-text selectors**.

## Passage-Marked Text Examples

A source text intermixed with in-text selectors (and load markers) is called **passage-marked** text.

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
In this case, a passage following '/en/' is in English and '/ja/' in Japanese.
A passage continues until a new selector appears or '/end/' marker appears.
The end marker resets a passage selection.

If you want to produce a document in English, you tell the Replacer the target selector is 'en'.
The replacer output will be:

```
 This is a common part for any languages.
 This text is included when the request language is English.
 This again included for every output.
```

You can specify multiple levels of selection of passages as follows:

```
 /ja/
 Text for all Japanese versions.
 /ja.v2/
 This is only for version 2 of the Japanese document.
 /end/
```

If you specify the target selector of 'ja' you will only get:

```
 Text for all Japanese versions.
```

while you get the following if you specify 'ja.v2':

```
 Text for all Japanese versions.
 This is only for version 2 of the Japanese document.
```

If you want to prepare a part of a document separately from the main source, prepare a load file for some or all selections.

```
 /@loaded/
 This text is used when the target load file is missing.
 /end/
```

A 'loaded' above, enclosed with '/@' and '/', is called **load marker**.
The load marker specifies a special passage that can be replaced with a content of a separate file called load file.
It spans until the next marker or '/end/' marker.

If you prepare a file named 'loaded-ja.txt' and 'loaded-ja_v2.txt' as follows:

| Filename | Content | Loaded for: |
|--|--|--|
| loaded-ja.txt | This is loaded for any Japanese document. | 'ja' 'ja.v2' 'ja.v2.r1' 'ja.v3' |
| loaded-ja_v2.txt | This is loaded only for version 2 of Japanese documents. | 'ja.v2' 'ja.v2.r1' |

And if you specify target selector of 'ja' you get:

```
 This is loaded for any Japanese document.
```
Or if you specify 'ja.v2' you will get:

```
 This is loaded only for version 2 of Japanese documents.
```
Finally if you specify 'en' and a load file for 'en' ie., loaded-en.txt' does not exist, you will get the default in-line text instead of content from a file:

```
 This text is used when the target load file is missing.
```

Please note a period (.) is used to separate an in-text selector into levels while an underscores (_) is used in a load file name in the same purpose.

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
$perl -sja <sample.md >sample-ja.md
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
$pandoc sample-ja.md -o sample-ja.html
```

For your infomation, I use Visual Stduio Code (vscode) to edit and preview Markdown text and one of many Markdown extentions to produce HTML or PDF file output.
I beleive Visual Stduio is useful not only for programmers like me and also for writers, editors and translators.

Finally, you need some file transfer tool such as secure ftp to upload local files to your web server.

```
$sftp author@www.example.com
Password: .....
>cd /var/www/html
>put sample-ja.html
>quit
```

!draw!
paper "sample-ja.html" -; ball "sftp" -; box "Server"
!end!

Now a browser user can access this file via URL of 'http://www.example.com/sample-ja.html'.

## Apache configuration

In a more advanced configuration, you don't need to do all of these steps manually.
In a more automated environment, all you have to do is to create and edit source files and everything else can be done automatically.

[README-onweb](README-onweb.md) describes how to incorporate the Replacer into Apache web server environment where storage of source files and all conversion works are done automatically on the server.

---

# Part Two: Reference

## Command line arguments

Usage: rep.pl [-s<i>selector</i>] [-p<i>directory</i>] < <i>input</i> > <i>output</i>
- -s<i>selector</i> - target selector (mandatory option)
- -p<i>directory</i> - source file location (defaults to current folder)
- <i>input</i> - source file  
- <i>output</i> - output file

If you use loaded files they must be in the same folder as the source file.
You must specify -p option if the source file is not in the current directory.

## Source text

Source text processed by Replacer is called passage-marked text.
It is a source text intermixed with passage markers enclosed in two slashes (/.../)

A source file without passage markers can be passed to Replacer.
Output is the same as the source file.

## Marker Syntax

Markers are inserted in a source file.
A marker is surrounded by a starting and ending slash (/) and occupies a line.

Markers and other names used in Replacer can have Roman alphabets in upper case (A-Z) and lower case (a-z), numbers (0-9) and some symbols (depending on the type of string or name).
Alphabets and numbers are called 'alphanumeric' in the following table.

List of markers:

| Marker | Syntax | Examples |
|--|--|--|
| Selector | Alphanumeric and period (.) as a level separator | /en/, /en.v2/ |
| Load marker | Alphanumeric and underscore (_) prefixed with at mark (@) | /@intro/, /@sec_note_1/ |

## Specifyinig Target selector

/en/
The target selector will be passed to the Replacer through a command line argument of the form -s<i>selector</i> (hyhpen, lower case S, no space, followed by selector). Examples are '-sja' for Japanese text, '-sja.v2' for the second version of the Japanese text.

## Load file

A passage marked with the load marker will be replaced with a selected load file if it exists.
If no load file exists that matches the selector, the original content will remain.

The load file name has the following format:

_load-marker_ - _selector_ . txt

The _load-marker_ specifies a matching load marker in a source file.
The _selector_ indicates what kind of content the load file contains.
_load-marker_ and _selector_ are separated by a single hyphen (-).

An underscore (_) is used to separate levels of a selector in a load file name unlike period (.) used in a target or in-text selector.

A file extension of a load file must always be '.txt' regardless of the content it contains (just text or some wikitext).

>An extension of '.txt' is used just to distinguish load files from the main source file whose extension  will be '.md' in case of Markdown file.

Examples:

- intro-en.txt
- intro-ja.txt
- sec_note_1-en.txt
- sec_note_1-en_v2.txt

Note that 'en_v2' in the last example matches against a selector of 'en.v2'.

## Selector levels

An in-text selector or loaded file will be selected if it is _inclusively equals_ to the target selector.

| | | | | |
|--|--|--|--|--|
| Target selector   | en  | en    | en.v2 | en.v2 |
| In-text selector  | en  | en.v2 | en    | en.v2 |
| Selected?         | Yes | No    | Yes   | Yes   |
