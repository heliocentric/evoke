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

> fetch http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.2/r1/evoke.iso

Then, extract the evoke directory to your / (note, extract only the 'evoke' directory, if you try to extract the entire thing, it will make your / unreadable by non-root users).

> tar -xvpf evoke.iso -C / evoke

Evoke is now installed on your system! You can activate it by doing the following:

> echo "/evoke/0.2/[r1](https://code.google.com/p/evoke/source/detail?r=1)/FreeBSD/7.1/i386/loader" >/boot.config

Note that 0.2 and [r1](https://code.google.com/p/evoke/source/detail?r=1) are the release and revision you are running, respectively. If you are using 0.3 or HEAD, change them accordingly. (Evoke's 'update' utility has a menu for normal users).

It is recommended that you read [Config](Config.md) and the rest of this document **before** rebooting, so you can for example enable sshd, configure static ip addresses, and other necessary steps.

### SSH ###

Like 0.1, 0.2 supports ssh, however because evoke is currently single user, the ssh daemon is disabled. To enable it, add the following to /evoke/misc/site.conf:

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

  * nexusd - A init replacement with support for full system consistancy checks, power management, and device management features.
  * textdump support is now enabled by default

### Programs ###

| Name				| Change	| Description													|
|:--------|:-------|:------------------------|
| [nexusd](Nexusd.md)		| **New**	| System initialization program										|

## Revisions ##

### [r1](http://www.damnsmallbsd.org/pub/evoke/misc/ISO-IMAGES/0.2/r1/) ###

Released: N/A

#### Targets ####

  * FreeBSD 7.2-RELEASE/i386

#### Security Updates ####

  * N/A