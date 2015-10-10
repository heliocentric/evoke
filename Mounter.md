<a href='Hidden comment: 
type: command
author: heliocentric
program-class command
name: mounter
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`mounter unmount directory`

`mounter list [ proto | fs | <fsname> ]`

`mounter proto://username:password@hostname:port/directory directory`

`mounter proto://username:password@1.2.3.4:port/directory directory`

`mounter proto://username:password@[08fe::24e5:2319:1]:port/directory directory`

`mounter proto:/directory/file directory`

`mounter proto:geom directory`

## Description ##

mounter is a way of mounting filesystems, be they remote or local, in a standard manner. Rather then burdoning the user with remembering what -o options specify the username, the password, port number; they are in a set format in mounter. We borrowed the url syntax, and adhere to it strictly. Also, we have support for automatic creation of md or ggate devices when a normal file is specified, and tearing down the md device when mounter unmount is used.

## Feature List ##

  * Uses an extended URL format.
  * Supports searching for volumes to mount, currently only via tag.

## Required Files ##

  * Path where the file is - port it is in and/or base
> > Long Description

## Implementation ##

Implementation Notes

## Bugs ##

mounter does not handle the case where one of the special url characters: /, :, @, [, and ] appear in a field. For example, a username such as blah@whatever.org, which is common in some hosting services.

The proper way to handle this would be to support \ to escape the characters when they aren't to be used as deliminators. Anyone is free to implement this.