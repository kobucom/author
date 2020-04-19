# Multi-Lingal Selector Loader on the Web

2020-apr-12 first edition

In this document, the multi-lingal selector loader is called just 'Replacer', an old name for it.

Before continuing, see [README-rep](README-rep.md) to get familiar with the Replacer program and its source format, passage-marked text.
It includes how to use the replacer locally on your PC using command line (called **local** configuration).

This document describes how to build a Apache-based content management system for Replacer (called **apache** configutation) where all conversion work is done automatically online.

## Apache Configuration

In a local configuration, you use Replacer on your local PC.
You store your source markdown files on your PC, run Replacer and any converter on your PC to generate a desired output (html or PDF) on your PC.
Then you upload the final output on the web or pass it to someone via email.

!draw!
paper "Source" -; ball "Replacer" -; ball "Converter" -; paper "Output"|
~; ~; ~; ball "File transfer" -; box "Web server"
!end!

In an apache configuration, you store source files on an Apache web server using **webdav** technology.
You use your PC to create, edit and organize source files but the files are eventually stored on the web server.
You don't need to manually convert or upload the output to the web server any more.
When a web browser user requests a certain URL on your server, the relevent source file(s) are converted on the fly and an output is passed to the browser.

!draw!
box "PC" -; paper "Source" -; box "Webdav folder" |
~; ~; ball "Apache" -; paper "HTML output"
!end!

## Workflow

Here is a short scenario showing how you can create and publish a web page in an apache configuration.

- Connect to your web server from your PC and open the webdav folder,
- Create or place a passage-marked source in that folder,  
for example, 'sample.md' containing two languages: English and Japanese.
- That's it.
- Open your web broser to request the page:
  - 'http://www.example.com/news/sample.mdp?select=ja' to view a Japanese page,
  - 'http://www.example.com/news/sample.mdp?select=en' to view an English page, or
  - 'http://www.example.com/news/sample.mdp' to view the page in whichever language your browser is configured.

## Components

Basically the Replacer can handle any text format as far as a converter for the final representation format is available.
In this example apache configuration, some components are added to Apache to handle conversion from Markdown to HTML on the web server.

!draw!
box "Apache" -; ball "rep.cgi" |
~; ball "rep.pl" -; ball "pandoc" -; box "Browser"
!end!

### Replacer-provided components

- rep.pl - main Replacer program in Perl (same as the command line version desribed in [README-rep](README-rep.md))
- Apache add-on
  - rep.cgi - action handler CGI script (shell script)
  - getlang.sh - shell script called from rep.cgi to determine the target language
  - pandoc-gfm.css - a minimum stylesheet passed to pandoc

The 'rep.cgi' script is set up so that Apache calls it when a certain URL is requested.
Rep.cgi calls the Replacer (rep.pl) and then 'pandoc' to convert passage-marked markdown text to HTML.

### Third-party products

- Apache web server with webdav feature enabled
- pandoc document converter used to convert github-flavoured markdown to html

## Language Handling

The Replacer accepts any string or dot-delimited strings as a target selector.
Typical case is a language code (without regional code).
In other cases, it can be a version, product name or anything.

The web technology allows specification of one or more language codes (such as 'en') with or without regional codes ('us' in 'en-us') a browser user prefers.

In the apache configuration, either a Replacer-style target selector or standard language code can be used.
It is determined in the following precedence (getLang.sh does this):

- explicit request per file access: query string of the format select=<i>selector</i> as in 'http://server/news/sample.mdp?select=ja.v2' for example,
- web browser's default language settings passed through HTTP Accept-Language header; a user can change this by Language in Options page, and
- server's default language (stored in /etc/default/locale in debian or in /etc/sysconfig/i18n in redhat).

In the latter two cases, only a language code (such as 'en' not whole 'en-us') is passed to the Replacer.

## Connecting to Webdav Server from your PC

You author source files using your local PC.
You need to place files in a webdav folder on a web server.
Usually accessing a remote webdav folder is easier than uploading files to a web server using a file transfer tool such as secure ftp.
You can directly create and edit a file in a webdav folder as if you are using  local files rather than copying files to the folder.

One way to access a remote webdav folder is to use a webdav client tool.

!draw!
box "PC" -; ball "Webdav client" -; box "Webdav folder" -; box "Web server"
!end!

Another way is to use an already available function in your platform.

!draw!
box "PC" -; ball "Windows" -; box "Webdav folder" -; box "Web server"
!end!

Instead of using a dedicated tool, you can use:

- File Explorer to attach a webdav folder as a network drive in Windows, 
- Finder (Connect to Server) to access a webdav folder on MacOS,
- File Manager (Connect to Server) in Ubuntu desktop
- davfs2 file system driver to mount a webdav folder in non-desktop Linux
- etc.

## Server Setup Instructions

This section explains how to set up an apache configuration taking Debian (a distribution or 'version' of Linux) as an example.
Before proceeding, install Apache2 and enable CGI (not described here).

The example configuration described here assumes the following rules:

- a virtual extension '.mdp' is used to refer a converted version of a passage-marked markdown source text (.md)
- a subfolder name in the webdav directory represents a project or author account (such as 'news' or 'borris')
- the name of a subfolder is used as a prefix in a URL so that 'http://server/news/sample.mdp' requests conversion of a source text in 'sample.md' in the 'news' subfolder in the webdav folder
- a common stylesheet called 'pandoc-gfm.css' is placed in the top folder of the web site and used with every generated file

First set up folders as follows:

```
  /var/www/
    html - virtual host top (already created in debian)
    dav - webdav folder
```

Create the webdav folder and set its owner to the Apache user.

```
  $mkdir -p /var/www/dav
  $chown www-data:www-data /var/www/dav
```

Enable webdav on Apache.
Load mod_dav and mod_dav_fs and specify:

```
  DavLockDB "/var/lock/apache2/DavLock"
  Alias /webdav /var/www/dav
  <Directory "/var/www/dav">
    Dav On
    # security and authentication   
  </Directory>
```

>You need to set up security and authentication when you publish your webdav server on the internet; for example HTTP digest authentication or SSL with basic authentication.

Now you should be able to access the webdav folder using URL of 'http://server/webdav' or 'webdav://server/webdav' where you create and edit source files.

To enable reader's access, create a project or account association.
Load mod_actions and specify:

```
AddHandler passage-marked-text .mdp
Action passage-marked-text /cgi-bin/rep.cgi virtual
Alias /news /var/www/dav/news
```

The 'virtual' keyword is important for this setup.
If 'http://server/news/sample.mdp' is requested by a browser, an action handler called 'rep.cgi' is called to read '/var/www/dav/news/sample.md' and returns the converted HTML output as a response to the browser.
Neither 'sample.mdp' nor 'sample.html' exists in the real file system.
The output is created on the fly from the 'sample.md'.

Install the Replacer and the action handler:

```
$cp rep.cgi /usr/lib/cgi-in
$cp rep.pl getlang.sh draw.pl /usr/local/bin
$cp pandoc-gfm.css /var/www/html
```

