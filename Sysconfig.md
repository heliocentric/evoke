<a href='Hidden comment: 
type: command
author: heliocentric
program-class command
name: sysconfig
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`sysconfig command GEOM [options]`


## Description ##

The system configuration utility creates and modifies the system configuration partition, which is typically stored on a thumb drive, carried by the user. For example, the user's private rsa key, username info, etc.

## Feature List ##

  * create - Initializes the first sector, adding a uuid, the number of entries in the array, and a long description
  * clear - Clear the entire system configuration data.
  * verify - Verify the header, set the exit code to 0 if passed, exit code 3 if failed
  * commit - Create an archive of the specified directory (most of the time, not the same directory as what the system is using) and commit it to the oldest entry in the log, ignoring the consistency.
  * extract - Extract the most recent, consistent tarball from the partition, and copy it to the path specified. if the sha256 hash doesn't match, we fall back to the second most recent, etc. In this way we gain a level of fault tolerance.
  * list - Effectively a pseudonym for 'mounter list sysconfig'

## Required Files ##

  * /usr/local/bin/uuid - misc/ossp-uuid
> > Necessary due to the usage of version 4 UUIDs, which uuidgen cannot generate

## Implementation ##


### Version 1.0 ###

  * Header sector
    * First 64 bytes contain a sha256 hash of the data in the rest of the sector.
    * The rest is the actual header data, formatted as a newline delimited list of name=value pairs in normal UTF-8 form.
      * version = the version number of the on disk format.
      * padsize = the number of sectors between the header sector, and the start of the array of records.
      * entrysize = size of each record in sectors.
      * log = number of records.
      * description = a long description, used for display purposes when multiple sysconfig partitions are found.
      * uuid = the uuid for this sysconfig partition.
  * Record Format
    * First 64 bytes contain a sha256 hash of all of the data from what remains of this sector, to the end of the record.
    * The next 10 bytes contain a UNIX UTC time stamp of the date of commit, if the date on the running system is lower then the date of the most recent record in the log, we store the date of that record + 1. In this way sysconfig can always choose the most recent dated record.
    * From this point on, the contents are a tar.gz file.