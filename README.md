# Multi-Language Authoring and Publishing with Apache-only Web Site

The purpose of this project is to enable:

- Authoring and publishing multi-language articles and documents using Markdown or other wikitext source
- Content management system (CMS) built only with Apache

A basic idea behind this project is **preprocessing** of a source text using passage or block-level markings.
You can **freely add a trivial but convenient feature** to a source text unless the addition does not break wikitext or HTML syntax rules.
You can still use a popular wikitext converter and stable web server such as Apache without any compromise.

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

>The 'rep' stands for 'Replacer', an old name for the passage selector loader script. The project name 'getaheta' (ge-ta-he-ta) refers to two symbols I once used instead of 'ja' and 'en' markers.

The [brief summary](http://www.kobu.com/getaheta) describes what you can do with these tools.
