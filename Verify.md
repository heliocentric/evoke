<a href='Hidden comment: 
type: command
author: heliocentric
program-class fileop
name: verify
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`verify file1 [file2] [...]`


## Description ##

Verify files specified against stored sha256 and md5 hashes stored in extended attributes or in a trackfile. If passed 'write' in the OPTIONS, it will also write the hashes into the extended attributes, or in the specified trackfile. If no files are specified, then all we do is verify the trackfile if specified, or return with a 0 error code.

## Required Files ##

  * stat - base
> > NetBSD-like stat, which supports -f "%HT"
  * md5 - base
> > FreeBSD-style md5 or linux md5sum (must support -q option)
  * sha256 - base
> > FreeBSD-style sha256 (must support -q option)
  * openssl - base
> > OpenSSL command program. Used for signature support.