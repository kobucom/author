#!/bin/bash

# rep.cgi - multi-lingal markdown-to-html converter as an apache handler
#  rep.cgi is an action handler called from apache web server's mod_actions module
#  when a predefined URL is requested.
#
# rep.cgi (handler) is revised from rep.sh (filter).
# see rep.sh comments for detail of file conversion meachanism.
# The difference between rep.cgi and rep.sh:
#  - names of environment variables referenced: query string, document path
#  - source input: rep.sh takes from stdin while rep.cgi reads a file
#  - what url points to: a real .md file in case of rep.sh while a virtual url in case of rep.cgi
#
# 2020-apr-11 revised from rep.sh
# 2020-apr-12 tested with sample.md
# 2020-apr-14 draw.pl incorporated
# 2020-apr-18 .mdp replaced to .md

#debug
#echo 'Content-Type: text/plain'
#echo ''
#printenv

# DOCUMENT_ROOT=/var/www/html
# PATH_TRANSLATED=/var/www/html/news/test.md
# REQUEST_URI=/news/test.md?select=ja
# PATH_INFO=/news/test.md
# QUERY_STRING=select=ja
# HTTP_ACCEPT_LANGUAGE=ja,en-US;q=0.7,en;q=0.3

>&2 echo "[rep.cgi] " \
	DOCUMENT_ROOT = "$DOCUMENT_ROOT", \
	PATH_INFO = "$PATH_INFO", \
	QUERY_STRING = "$QUERY_STRING", \
	HTTP_ACCEPT_LANGUAGE = "$HTTP_ACCEPT_LANGUAGE"

# location of replacer files
if [ -z "$REP_HOME" ]; then
	REP_HOME=/usr/local/bin
fi

# change virtual extension to real one
PATH_INFO=${PATH_INFO/\.mdp/.md}

# parameters
FULLPATH="/var/www/dav${PATH_INFO}"
DIRNAME=$(dirname $FULLPATH)
BASENAME=$(basename -s .md $FULLPATH)
SELECTOR=$($REP_DIR/getlang.sh "$QUERY_STRING" "$HTTP_ACCEPT_LANGUAGE")

>&2 echo FULLPATH = "$FULLPATH", \
	DIRNAME = "$DIRNAME", \
	BASENAME = "$BASENAME", \
    SELECTOR = "$SELECTOR"

# header
echo 'Content-Type: text/html'
echo ''

# conversion
cat ${FULLPATH} | $REP_HOME/rep.pl -s${SELECTOR} -p${DIRNAME} | \
	$REP_HOME/draw.pl | \
	pandoc -f gfm -t html5 -c "/pandoc-gfm.css" \
	-T "Converted" -M title=${BASENAME}
