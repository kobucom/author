#!/bin/bash

# getlang.sh - a bash function to return a desired language through stdout
# - target selector if query string of 'select=...' specified
# - language code (without regional code) from Accept-Language HTTP header
# - server's default language code
# - 'en' if all failed

# 20-apr-11 part of rep.sh made independent so that rep.cgi can also use
# 20-apr-12 lang=xx -> select=xx.yy...

# call arguments: getlang.sh query-string accept-language
QS=$1
AL=$2

# debug output issued to stderr so that you can see them in apache error.log
>&2 echo getlang.sh: query-string = "${QS}", accept-language = "$AL"

# SYS_LANG - default server language
# on debian:
#  /etc/local.gen lists possible candidates:
#   aa_DJ ISO-8859-1
#   aa_DJ.UTF-8 UTF-8
#    ...
#  and /etc/default/locale contains the selected one such as:
#   LANG=en_US.UTF-8
# redhat keeps it in /etc/sysconfig/i18n in the same format.

# to take 'en' from the above format, remove ' ' '.' '_' in this order
SYS_LANG=$(grep "^LANG=" /etc/default/locale | sed -E 's/^LANG=(.+)$/\1/' | cut -d " " -f 1 | cut -d "." -f 1 | cut -d "_" -f 1)

# default language in case no query string nor accept-language is available
DEF_LANG=${SYS_LANG:-en}

# variable to store final target selector (or language) to return
TGT_LANG=""

if [[ $QS =~ ^select=.+ ]]; then
	# 1) explicitly specified query string of 'select=<selector>' takes precedence
	# this may take a form of "en" or "ja" etc but not "en-us"
    TGT_LANG=${QS/select=/}
else
	# 2) take implicit Accept-Language header if select=xx missing
	TGT_LANG=${AL:-$DEF_LANG}
	if [ "$TGT_LANG" = "*" ]; then
		TGT_LANG=$DEF_LANG
	fi
fi

# to extract only the first language code from complicated Accept-Language header,
# remove ',' ';' '-' in this order so that you can take 'en' from 'en-us;q=0.5,ja'
# note that periods (.) are not removed since select=<selector> may include them.
TGT_LANG=$(echo $TGT_LANG | cut -d "," -f 1 | cut -d ";" -f 1 | cut -d "-" -f 1);

	# TODO: current version of rep.pl accepts list of lang codes
	# all lang codes in ACCEPT_LANGUAGE can now be passed with -s option
	
>&2 echo SYS_LANG = "${DEF_LANG}", DEF_LANG = "$DEF_LANG", TGT_LANG = "${TGT_LANG}"

# output the determined language (or selctor) to stdout
echo "${TGT_LANG}"
