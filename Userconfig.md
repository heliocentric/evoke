<a href='Hidden comment: 
type: command
author: heliocentric
program-class command
name: userconfig
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`userconfig [commnd]`


## Description ##

Allow users to login, create a user account, and encrypt it via cryptofs and encfs if the user chooses.

## Commands ##

  * create
> > Create a directory for a user, and set a password.
  * login
> > Login as the user specified.
  * list
> > List the users in the sysconfig directory.
  * menu
> > Display a pretty menu for choosing the user.
  * logout
> > Logout.

## Required Files ##

  * uuid - misc/ossp-uuid
> > A uuid program that allows us to specify version 4 uuids (the uuidgen in base only supports version 1)
  * encfs - sysutils/fusefs-encfs
> > Necessary, even though encrypting the userconfig data is optional
  * cryptofs - sysutils/fusefs-cryptofs
> > Necessary, even though encrypting the userconfig data is optional
  * awk - base
> > one-true-awk

## Implementation ##

Each user is stored in the sysconfig partition, in a directory named after the user's UUID. This was chosen to avoid the collisions inherent in using a login name, or an incrementing id number. Users may have the same login name, as long as their UUID is different, and even have the same real name (If you want, you can have 100 users in a sysconfig partition named 'John Smith', and nothing will break.).

The userconfig utility mirrors sysconfig, and has the added bonus of supporting transparent password based encryption via cryptofs or encfs. Note, that this is not 'remote login', as this will only encrypt the real 'keyring' data stored in the directory specified by N\_CURUSER and soon, HOME (note, we may make them seperate, due to some assumptions made by processes using HOME, but N\_CURUSER will always point to this directory).