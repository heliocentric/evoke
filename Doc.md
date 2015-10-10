<a href='Hidden comment: 
type: command
author: heliocentric
program-class search
name: doc
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`doc [search string]`


## Description ##

doc is a wrapper for the real man page viewer, and our documents. You specify a search string, for the document you wish to view.

Search string is specified by key=name tuples, any spaces must use quotes, so that the shell will put them into single argv[.md](.md) entries in the array.

If a = does not exist in an argv entry, it is treated like it was name=**.**

Ex.

  * `doc name=mounter` - get the normal doc wiki for mounter.
  * `doc name=close type=libc` - get the close function call definition, as it applies to libc.
  * `doc name=read type=libc doctype=man` - get the read call, and force it to be a typical man page.
  * `doc sh` - equivalent to `doc name=sh`

## Search options ##

  * name - the logical name of the command, function call, etc.
  * type - the type, useful if you have conflicting names, for example, read can be a sh builtin, a libc call, or a function in another language.
  * proglang - the programming language the program or library call is written in.
  * author - author of the program, library call.
  * doctype - man, wiki, useful to force a scope. Default is all doc types
  * output -
    * tty - output suitable for a terminal.
    * batch - output all results, directly to stdout. Useful for testing time.
    * namelist - output a list of all matching names.
    * filelist - output a list of all matching files.