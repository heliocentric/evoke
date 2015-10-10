<a href='Hidden comment: 
type: command
author: heliocentric
program-class fileop
name: filetype
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`filetype file1 [file2] [...]`


## Description ##

Return the mime type for a file, consult the file's type field in stat, the user.mime\_type extended attribute, and then file's --mime-type option.

## Required Files ##

  * stat - base
> > NetBSD-like stat, which supports -f "%HT"
  * file - base
> > Needs to support --mime-type.