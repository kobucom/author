# Preprocessor-based Authoring and Publishing with Apache-only Web Site

<!-- run ./draw.pl < draw-README.md > README.md -->

## About this Project

The purpose of this project is to enable:

- Authoring and publishing multi-language articles and documents using Markdown or other wikitext source,
- Content management system (CMS) built only with Apache, and
- Extra small preprocessors each for tiny task that can be concatenated through piping.

## Published Tools

The tools published here includes:

- Passage Selector Loader (rep.pl)  
A tool for writing articles in more than one language at the same time in the same file.  
See [README-rep](README-rep.md)
- Apache add-on (rep.cgi) for publishing Markdown content  
Apache action handler for automatic extraction, conversion and publishing of a particular language content.  
See [README-onweb](README-onweb.md)
- Simple SVG Chart Generator (draw.pl)  
As a bonus, tool for embedding small inline SVG charts using a simple text instruction.  
See [README-draw](README-draw.md)

A brief summary describes what you can do and how you can do with these tools.

- [English](https://www.kobu.com/author/index-en.html)
- [Japansese](https://www.kobu.com/author/index.html)

## Architecture

Let me show you a basic architecture of how these tools are combined and connected to perform a desired authoring and publishing work.

A text passes in three conversion phases.
The final output is HTML (or possibly PDF).
An intermediate Markdown or other wikitext source is converted to the HTML output.
The first written Markdown text contains specially designed markings.
These markings are processed by one or more authoring tools to produce a pure Markdown text.
The first-written manuscript text is called a **passage-marked** text.

<svg width="450" height="100" style="fill:gainsboro;stroke:gray;stroke-width:1">
<polygon points="25,25 25,75 125,75 125,35 115,25" style="fill:white" /><text x="75" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Passage-Marked</text>
<line x1="130" y1="50" x2="170" y2="50" style="opacity:0.75" />
<polygon points="175,25 175,75 275,75 275,35 265,25" style="fill:white" /><text x="225" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Markdown</text>
<line x1="280" y1="50" x2="320" y2="50" style="opacity:0.75" />
<polygon points="325,25 325,75 425,75 425,35 415,25" style="fill:white" /><text x="375" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">HTML</text>
Inline SVG not supported by your browser
</svg>

Preprocessings prior to Markdown-HTML conversion are done by a collection of perl scripts.
They are connected by a UNIX pipe to form a chain of processings.
The last part of the chain is a Markdown-to-HTML converter (I currently use pandoc for this purpose).

<svg width="750" height="100" style="fill:gainsboro;stroke:gray;stroke-width:1">
<polygon points="25,25 25,75 125,75 125,35 115,25" style="fill:white" /><text x="75" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Passage-Marked</text>
<line x1="130" y1="50" x2="170" y2="50" style="opacity:0.75" />
<ellipse cx="225" cy="50" rx="50" ry="25" style="stroke-width:2;opacity:0.5" /><text x="225" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Replacer</text>
<line x1="280" y1="50" x2="320" y2="50" style="opacity:0.75" />
<ellipse cx="375" cy="50" rx="50" ry="25" style="stroke-width:2;opacity:0.5" /><text x="375" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Draw</text>
<line x1="430" y1="50" x2="470" y2="50" style="opacity:0.75" />
<ellipse cx="525" cy="50" rx="50" ry="25" style="stroke-width:2;opacity:0.5" /><text x="525" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Pandoc</text>
<line x1="580" y1="50" x2="620" y2="50" style="opacity:0.75" />
<polygon points="625,25 625,75 725,75 725,35 715,25" style="fill:white" /><text x="675" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">HTML</text>
Inline SVG not supported by your browser
</svg>

This processing chain can be executed from a UNIX command line usually using a shell script to pipe these tools together.

```
$./rep.pl < README.passge-marked-text | ./draw.pl | pandoc ... > README.html
```

In addition, the tools can be incorporated into an Apache web server to produce content dynamically.
A passage-marked text can be processed and converted to HTML on the fly on reception of a browser request to the server.
A CGI shell script is used to start and connect the perl tools and the converter.

<svg width="750" height="100" style="fill:gainsboro;stroke:gray;stroke-width:1">
<rect x="25" y="25" rx="10" ry="10" width="100" height="50" style="stroke-width:2;opacity:0.5" />
<text x="75" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Browser</text>
<line x1="130" y1="50" x2="170" y2="50" style="opacity:0.75" />
<rect x="175" y="25" rx="10" ry="10" width="100" height="50" style="stroke-width:2;opacity:0.5" />
<text x="225" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Apache</text>
<line x1="280" y1="50" x2="320" y2="50" style="opacity:0.75" />
<ellipse cx="375" cy="50" rx="50" ry="25" style="stroke-width:2;opacity:0.5" /><text x="375" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">CGI Script</text>
<line x1="430" y1="50" x2="470" y2="50" style="opacity:0.75" />
<ellipse cx="525" cy="50" rx="50" ry="25" style="stroke-width:2;opacity:0.5" /><text x="525" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">Piped Tools</text>
<line x1="580" y1="50" x2="620" y2="50" style="opacity:0.75" />
<polygon points="625,25 625,75 725,75 725,35 715,25" style="fill:white" /><text x="675" y="50" style="fill:gray;stroke-width:1;dominant-baseline:middle;text-anchor:middle">HTML</text>
Inline SVG not supported by your browser
</svg>

## Background

A basic idea behind this authoring project is **preprocessing** of a source text that can be passed to down-stream tools such as a Markdown-to-HTML converter.

Preprocessing of text or programming code is called in many different ways.
An old UNIX tool 'm4' is called macro processor and used to replace words in a text file.
The C language preprocessor replaces names with constants and selects code blocks.
Web engineers use tools called template engine to replace words in an HTML page such as Java Server Pages for Java, PHP, React for Javascript, to name a few.

With processing of text, you can freely add trivial but convenient features to a source text unless the addition does not break wikitext or HTML syntax rules.
You can still use a popular wikitext converter and stable web server such as Apache without any compromise.

Two kinds of preprocessing exist: passage- or **block-level** markings usually terminated with new lines and **inline** phrase- or word-level replacements within a block.
For example, the Replacer (passage selector loader) handles block-level text while the companion project 'live data embedder' handles inline macros (varriables and actions).

A good thing about preprocessing is it is _personal_ or _private_.
A souce text prior to be applied preprocessing does not have to be _public_ or does not need to be compliant to any well-known standards or specifications.
You can freely design the input format as long as you have a tool to convert it to a legitemate final output format such as Markdown or HTML.

I am developing these preprocessing tools in order to get freedom in writing style.
I want to write the way I like to do.
I am glad if any of my tools suit your needs and help you write more easily and with fun.

---

Written ???  
Updated 2020-May-21

Visit [Kobu.Com](https://kobu.com/index-en.html).
