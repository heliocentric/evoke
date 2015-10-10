<a href='Hidden comment: 
type: release-doc
author: heliocentric
name: intro
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>



## Warnings ##

Warning: Evoke now uses gzip to compress the kernel and all modules. There are reports that evoke is now unbootable on qemu, however, there are no reports of problems on real hardware. If you find any problems, we urge you to create a ticket in the issue tracker describing the boot problem.

## Features ##


### Installing evoke on a FreeBSD system ###

First, you need to fetch a release iso, for example:

> fetch http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r1/evoke.iso

Then, extract the evoke directory to your / (note, extract only the 'evoke' directory, if you try to extract the entire thing, it will make your / unreadable by non-root users).

> tar -xvpf evoke.iso -C / evoke

Evoke is now installed on your system! You can activate it by doing the following:

> echo "/evoke/0.1/[r1](https://code.google.com/p/evoke/source/detail?r=1)/FreeBSD/7.1/i386/loader" >/boot.config

Note that 0.1 and [r1](https://code.google.com/p/evoke/source/detail?r=1) are the release and revision you are running, respectively. If you are using 0.2 or HEAD, change them accordingly. (Evoke's 'update' utility has a menu for normal users).

It is recommended that you read [Config](Config.md) and the rest of this document **before** rebooting, so you can for example enable sshd, configure static ip addresses, and other necessary steps.

### SSH ###

Like the pilot, 0.1 supports ssh, however because evoke is currently single user, the ssh daemon is disabled. To enable it, add the following to /evoke/misc/site.conf:

> evoke.sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAABI...."

Where the key is your public key. Currently, this method is an administrative interface that only supports a single public key. It is not recommended to use this feature in a pxeboot environment unless the hardware of both the boot server, the client, and all networking infrastructure is completely secured.

### Install ###

Evoke supports a basic installer, intended for use with dedicated hard drives or thumb drives. Shared systems (with freebsd, windows, etc) are currently not supported with installer. This includes resizing partitions, adding boot menus, etc. Please do not use on those drives, thank you.

To access the installer, type:

> installer

And choose the 'Install Evoke' menu entry.

### Update ###

Evoke now supports an update utility. To access, simply type:

> update

This will list your bootable filesystems, and allow you to choose the release to update to. If you want to specify a directory to update, type:

> update /directory

Caveat: The Activate menu entry only activates systems that boot directly off of the filesystem. Systems which are netbooted are not supported through this menu.

### Changes to Previous Releases ###

N/A

### Programs ###

| Name				| Change	| Description												|
|:--------|:-------|:-----------------------|
| [systart](Systart.md)		| **New**	| System startup program										|
| [update](Update.md)		| **New**	| Binary patched based update utility.									|
| [doc](Doc.md)			| **New**	| Documentation system with a search interface.							|
| [mounter](Mounter.md)		| **New**	| Wrapper for kernel specific mount apis.								|
| [sysconfig](Sysconfig.md)	| **New**	| Utility to safely store system configuration data.							|
| [userconfig](Userconfig.md)	| **New**	| Utility to support login and user management.							|
| [verify](Verify.md)		| **New**	| File verification utility, with support for extended attributes and trackfiles.			|
| [filetype](Filetype.md)		| **New**	| Utility to identify the type of a specified file, and supports extended attribute based caching.	|

## Special Thanks ##

Jamie Ivanov of RadioactiveRussian.com for providing another test machine for the kenv patch.

## Revisions ##

### [r8](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r8/) ###

Released: 06/13/2009

#### Targets ####

  * FreeBSD 7.2-RELEASE/i386
  * FreeBSD 7.1-RELEASE-p5/i386

#### Errata ####

  * Add 'fs' to all existing filesystem protocols, so mounter list fs will have the proper output.
  * Fix a bug in mounter's 'protocol tasting' support, where device names could not be passed as file paths.
  * Fix a bug in remount detection where the filesystems are refered only by GEOM's
  * Add missing mount options to mounter.
  * Fix a bug with update's ordering of revisions [r1000](https://code.google.com/p/evoke/source/detail?r=1000) was coming 'after' [r999](https://code.google.com/p/evoke/source/detail?r=999), even though it should not have.

#### Security Updates ####

  * Fix several security bug that are irrelevant with our single user setup.

### [r7](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r7/) ###

Released: 05/05/2009

#### Targets ####

  * FreeBSD 7.2-RELEASE/i386
  * FreeBSD 7.1-RELEASE-p5/i386

#### Errata ####

  * Fix a broken backmerge.

#### Security Updates ####

  * N/A

### [r6](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r6/) ###

Released: 05/05/2009

#### Targets ####

  * FreeBSD 7.2-RELEASE/i386
  * FreeBSD 7.1-RELEASE-p5/i386

#### Errata ####

  * Just chmod -R /system to 555, and add the immutable flag. We can do this because we cleanly seperate system and user.
  * Modify the file patches so that file -i won't add setuid/setgid to the beginning of the type.
  * Modify the dmesg output to report the proper sizes of disks.
  * Use major and minor version numbers for the ABI, that way there are no syncing issues.
  * Add 'tasting' support to mounter, so it no longer requires a protocol for files/directories/device nodes.

#### Security Updates ####

  * N/A

### [r5](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r5/) ###

Released: 04/22/2009

#### Targets ####

  * FreeBSD 7.1-RELEASE-p5/i386

#### Errata ####

  * N/A

#### Security Updates ####

  * [FreeBSD Security Advisory FreeBSD-SA-09:08.openssl](http://security.freebsd.org/advisories/FreeBSD-SA-09:08.openssl.asc)
  * [FreeBSD Security Advisory FreeBSD-SA-09:07.libc](http://security.freebsd.org/advisories/FreeBSD-SA-09:07.libc.asc)

### [r4](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r4/) ###

Released: 04/19/2009

#### Targets ####

  * FreeBSD 7.1-RELEASE-p4/i386

#### Errata ####

  * Set 7.1's bootcode directly to 7.2, rather then 7-STABLE.
  * Add directory support to trackfiles, and teach update and verify to use them.
  * Fix a bug in filetype that prevented stat from working correctly on files with spaces.
  * Add 'mime type' to the end of each file record in a trackfile.
  * If the TRACKFILE\_DATE environment variable isn't set, verify will use date +%s
  * Change the PRINTF\_BUFR\_SIZE to 128.

#### Security Updates ####

  * N/A

### [r3](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r3/) ###

Released: 04/15/2009

#### Targets ####

  * FreeBSD 7.1-RELEASE-p4/i386

#### Errata ####

  * Fix a bug where md devices appeared as 'valid' install targets.
  * Add a 'real' tag to disks, for ad0 and da0.
  * Fix a bug where userconfig used mounter list fs instead of mounter list proto.

#### Security Updates ####

  * N/A

### [r2](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r2/) ###

Released: 04/12/2009

#### Targets ####

  * FreeBSD 7.1-RELEASE-p4/i386

#### Errata ####

  * Add a configuration variable to disable ntpd at startup
  * Add iostat and systat to the image.
  * Add moduli file to the image.

#### Security Updates ####

  * N/A

### [r1](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.1/r1/) ###

Released: 04/07/2009

#### Targets ####

  * FreeBSD 7.1-RELEASE-p4/i386

#### Security Updates ####

  * N/A