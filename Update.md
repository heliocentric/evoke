<a href='Hidden comment: 
type: command
author: heliocentric
program-class command
name: update
programming-language: sh
svnid: $Id$
svnauthor: $Author$
svnrevision: $Revision$
'></a>

`update [command]`


## Description ##

Update is a binary update utility, that aggressively tries to grab the correct files for the chosen release, and falls back on grabbing full files.

## Feature List ##

  * install - Installs the release in the second argument, to the directory of the first argument.
  * activate - Activates the release in the second argument, to the directory of the first argument.
  * menu - Draws a menu for choosing the releases, and activating them.

## Required Files ##

  * /usr/bin/bspatch - base
> > bspatch is the utility we use to apply the binary patches.

## Implementation ##

  1. update fetches the trackfile for the target release from the mirrors.
  1. We use the sha256 hash of the destination file, to build a url like so: http://www.damnsmallbsd.org/pub/evoke/misc/BIN-UPDATES/0.1/r1/${HASH}/trackfile
  1. This trackfile contains a list of source hashes available. They are sorted by size, and we filter out all source hashes that don't exist on any previous releases trackfiles.
  1. If we can fetch the file, we check to see if the destination or source has a .gz, or .bz2 extension. If it does, we first uncompress it to the staging area.
  1. We now run bspatch over the source, using the downloaded file, saving it to the staging area.
  1. If the destination's extension was .gz or .bz2, we compress it.
  1. Now, we sha256 the destination file, and compare it to the entry in the trackfile. If it matches, then we go to step #9.
  1. If we can't get the file, or the resulting file is corrupt, we go through each available release and repeat the process until we hit the oldest one. If the oldest one fails, then we fall back, to grabbing the file directly, for example: http://www.damnsmallbsd.org/pub/evoke/0.1/r1/loader.conf. Then we go to step #4. We also set a bit to detect the end of the logic, if this method does not work, we error out and tell the user something is broken.
  1. Since we've verified that the file was not corrupted in transit, and that the patch applied cleanly, put it in another part of the staging area.
  1. Once all the files in the trackfile are done, move the files out of the staging area onto the boot filesystem.
  1. Allow the user the option of activating the downloaded release by calling installer.
  1. Follow installer's mo, sync the disks, disable all write caching, and write the /boot.config for the active filesystem. Sync. re-enable write caching, done. Rinse, Repeat.