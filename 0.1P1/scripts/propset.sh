#!/bin/sh
#
# Sets svn properties on files so that we can do Id, Date, etc
# $Id$
#

for fn in `find ./ -not -type d | grep -v "/\." | grep -v "~$"`
do
	svn propset svn:keywords "Date Author Revision HeadURL ID" $fn
done
