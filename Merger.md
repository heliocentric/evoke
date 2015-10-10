<a href='Hidden comment: 
type: command
author: heliocentric
name: merger
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`merger [sourcedirectory] [targetdirectory]`


## Description ##

merger uses the environment variables OS, ABI, and ARCH, to create an environment needed by the kernel in question. For FreeBSD, this means nullfs mounting them to /lib, /libexec, and /bin.

## Required Files ##

  * mount\_nullfs - base
> > Required for FreeBSD, as it's the only way to have a filesystem appear in two places.
