# PREPRO Preprocessors Demo

## Selector - mixed languages

/en/
You can use apt command to install Apache web server on Debian:
/ja/
aptコマンドを使ってDebianにApacheウェブサーバをインストールできます。
/end/

$ sudo apt install apache2 

## Selector - version selectors

To install apache:

/.debian/
$sudo apt install apache2
/.centos/
$sudo yum install httpd
/.centos.v8/

or

$sudo dnf install httpd
/end/

## Selector - prefix style test

/en/ This text is included when the request language is English.

/ja/This text is for Japanese only.  
ここは日本語で書かれた部分。

/any/ In any language ...

## Draw - inline SVG chart

A limited types of shapes with centered text can be drawn with lines to neighboring shapes.

!draw!
box "PC" -; ball "sftp" +; disk "Server Folder"
~; paper "File"
!end!

## Style - apply stylesheet classes

Left side - default

{center}
Centered text
{end}

{right}
Right-aligned text
{end}

## Include - file load test

[local file]

!@foo.md!

[remote content]

!%https://kobu.com/docker/bar.md!

