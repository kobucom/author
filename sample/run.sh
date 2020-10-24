#!/bin/bash

# run.sh: calls preprocessors in turn

PREPRO_AUTHOR=../prepro

lang=en
#lang=ja

os_type=.debian
#os_type=.centos
#os_type=.centos.v8

cat sample.md | \
	$PREPRO_AUTHOR/Include.pm | \
	$PREPRO_AUTHOR/Selector.pm --select "$lang" --versions "$os_type"| \
	$PREPRO_AUTHOR/Style.pm | \
	$PREPRO_AUTHOR/Draw.pm | \
	pandoc -f gfm-autolink_bare_uris -t html5 \
		-c "pandoc-gfm.css" \
		-T "PREPRO" \
		-M title="Sample" \
		-M lang="$lang" \
	> output.html
