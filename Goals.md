

## Key ##

| #	| Description											|
|:--|:----------------------|
| 0	| No work has been done									|
| 1	| Data which is written to disk uses the format specified, but no programs truly 'use' it	|
| 2	| Evoke programs support it, but third party programs do not.					|
| 3	| Support is feature complete.									|

## General Platform ##

| Description													| Version	| #	|
|:------------------------|:--------|:--|
| Multiple installed versions. 										| 0.1		   | 3	|
| Multiple binary targets, including abis and architectures.							| 0.1		   | 3	|
| Single shared root filesystem.										| 0.1		   | 3	|
| Allow evoke to coexist with existing FreeBSD, PC-BSD, DesktopBSD et al installations.			| 0.1		   | 3	|
| Store system configuration information out of band of the boot filesystem, in a fault tolerant manner.	| 0.1		   | 3	|
| Support pxebooting, disk booting, and cd booting, with the same exact environment.				| 0.1		   | 3	|
| The system should be cache-coherent, if a file is different, it's name should be different.			| 0.1		   | 3	|
| Split the released system files, from the site or machine specific files.					| 0.1		   | 2	|
| Fix file's readelf.c so filetype will return information that the build system can use.			| 0.2		   | 0	|
| Replace parts of systart with nexusd, and use nexusd instead of init						| 0.2		   | 3	|
| Replace the logic from mounter, and put it into a privileged mount daemon					| 0.3 		  | 0	|

### nexusd ###

Currently, single user mode on evoke is broken. This is because to get a full dynamic linking environment, systart has to do nullfs mounting. Since systart isn't run in single user mode, this does not get done, and single user mode is extremely limited. To fix this, we will replace the init binary with nexusd.

| Component									|	Status		|
|:------------------|:--------|
| Verify the root filesystem.							|	DONE		  |
| nullfs mount the architecture and abi specific directories.			|	DONE		  |
| Set up any variables for systart, including abi/architecture/etc.		|	DONE		  |
| Integrate watchdogd.								|	DONE		  |
| Integrate powerd.								|	Not Started	|
| Integrate devd-like functionality.						|	Not Started	|
| Start a control thread to replace the old 'signal' based init control.	|	Not Started	|

### mountd ###

While mounter works in a single user environment, it does not work in a multi-user environment with unprivileged
users. To fix this, we will have to write a privileged mount daemon.

  * Will store state information about mounts, so that multi-mounting and device node creation work as intended on a multi-user system.
  * Communicate with the mounter utility via a UDS, and make sure the mounter utility offloads session specific information (always passing the working directory for relative files, etc)
  * Subscribe to nexusd's device insertion/deletion feeds, and handle new devices.
  * Allow users to insert and remove 'rules' for new devices, for automounting and 'automagic' uid/gids, so fstab is completely obsolete.

## User Management ##

| Description													| Version	| #	|
|:------------------------|:--------|:--|
| UUID user identification, instead of serialized ids.								| 0.1		   | 1	|
| Authentication daemon based user management.									| N/A		   | 0	|
| Ubiquitous use of RSA and DSA based identity verification instead of plaintext passwords.			| N/A		   | 0	|

## Basic Networking ##

| Description													| Version	| #	|
|:------------------------|:--------|:--|
| IPv4 DHCP based autoconfiguration										| 0.1		   | 4	|
| IPv4 Manual configuration											| N/A		   | 0	|
| Storing information usually gained via rtadv in a DHCPv4 packet.						| N/A		   | 0	|
| IPv6 rtadv based autoconfiguration										| N/A		   | 0	|
| Support for all applicable DHCP based options.								| N/A		   | 0	|

## Advanced Networking ##

| Description													| Version	| #	|
|:------------------------|:--------|:--|
| Support multiple 'networks' with their own authentication, policies, and their own root ssl cert		| N/A		   | 0	|
| Full privacy segregation between networks									| N/A		   | 0	|
| A running system can be joined to many networks, with different policies in effect, at the same time.	| N/A		   | 0	|
| Use jails to segregate them, and remount /system to provide the base system files.				| N/A		   | 0	|

## User Interface ##

| Description																	| Version	| #	|
|:----------------------------|:--------|:--|
| Replace a tty subsystem based around ioctls, with a generalized console daemon.								| N/A		   | 0	|
| Use file descripters 3 and 4 as 'consin' and 'consout', and replace the outdated use of ioctls on /dev/tty with a 'console protocol'		| N/A		   | 0	|
| Console protocol needs inline mouse event support, and should grow some of the advanced key features that right now rely on an X server	| N/A		   | 0	|


## Xorg ##

With just the Xorg binary, the xinit binary, the xauth binary, and the xterm binary. Differences:


### [r846](https://code.google.com/p/evoke/source/detail?r=846) (without Xorg) ###
Build time:
  1. 860.604u 2462.413s 5:49:23.04 63.5%   -1444+1144k 451451+1187583io 508844pf+49w
Size:
> 23258 1024 byte blocks


### [r851](https://code.google.com/p/evoke/source/detail?r=851) (with Xorg) ###
Build time:
> 20409.213u 2897.353s 8:09:38.60 79.3%   -713+-749k 436749+1317614io 543278pf+11w
Size:
> 25984 1024 byte blocks