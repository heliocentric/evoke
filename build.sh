#!/bin/sh
# Copyright 2007-2009 Dylan Cochran
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted providing that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# $Id$

# Our build targets for the root.fs image.
export i386_ACTIVE="7.2-RELEASE/i386"

# Evoke Version
export VERSION="HEAD"
export REVISION="r$(svnversion)"

# Release Engineer
export ENGINEER="Dylan Cochran"

# List of programs in base to add to the image.
# The script already handles resolving libraries, and lazybox provides
# utilities needed by merger, and systart until merger has been ran.

export PROGS="
atacontrol awk bsdlabel bunzip2 bzcat bzip2 camcontrol cap_mkdb 
cat chmod cp csh date dconschat dd devfs df dhclient disklabel dmesg echo 
ee expr fdisk fsck_ffs fsck_msdosfs ftp ftpd fwcontrol geli getty grep 
groups gunzip gzcat gzip halt head id ifconfig jail jexec jls kenv kill init kenv
kldconfig kldload kldstat kldunload less link ln login ls md5 mdconfig 
mdmfs mkdir more mount moused mv nc newfs pciconf ping powerd ps pwd cut uname mount_nullfs
printf pwd_mkdb reboot rm route sed sh sha1 sha256 ssh ssh-keygen sshd stty 
swapon swapoff swapinfo syslogd tail tar tcsh tftp tftpd top umount sysctl
uniq unlink usbdevs vidcontrol whoami zcat sort pfctl du makefs 
mount_msdosfs getextattr setextattr devinfo newfs_msdos stat dirname lsvfs
rtsol egrep mount_cd9660 rmdir gpt tr file bsdiff bspatch savecore dumpon runterm
openssl fetch basename dumpfs command wc sleep uptime adjkerntz ntpd iostat systat nexusd ddb curl
netd
"

# List of kernel objects in base that will be on the image. Ports modules
# are added automatically.

export MODULES="acpi tmpfs evoke"

export ROOTDIR=`pwd`

# Overridable options

if [ "${OBJDIR}" = "" ] ; then
	export OBJDIR="${ROOTDIR}/obj"
	mkdir -p ${OBJDIR}
fi
if [ "${TMPDIR}" = "" ] ; then
	export TMPDIR="/tmp/buildenv"
	mkdir -p ${TMPDIR}
fi
if [ "${NDISTDIR}" = "" ] ; then
	export NDISTDIR="${ROOTDIR}/dists"
	mkdir -p ${NDISTDIR}
fi
if [ "${RELEASEDIR}" = "" ] ; then
	export RELEASEDIR="/releases"
	mkdir -p ${RELEASEDIR}
fi

export PATH="${ROOTDIR}/share/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

unset WRKDIRPREFIX
export ERRFILE=${ROOTDIR}/logs/$(date +%Y%m%d%H%M%S).log

echo " * share = Cleaning up"


OBJENV="$(mounter list object 2>${DEVICES}/null)"

if [ "${OBJENV}" != "" ] ; then 
	mounter "object:$(echo ${OBJENV} | head -n 1)" ${OBJDIR} 2>>${ERRFILE}
else
	chflags -R noschg ${OBJDIR} 2>>${ERRFILE}
	rm -r ${OBJDIR} 2>>${ERRFILE}
	mkdir -p ${OBJDIR} 2>>${ERRFILE}
fi

DISTENV="$(mounter list dists 2>${DEVICES}/null)"

if [ "${DISTENV}" != "" ] ; then 
	mounter "dists:$(echo ${DISTENV} | head -n 1)" ${NDISTDIR} 2>>${ERRFILE}
fi

export BUILDDIR=${ROOTDIR}/builder

${BUILDDIR}/build.sh 2>>${ERRFILE}
if [ "${OBJENV}" != "" ] ; then 
	mounter umount ${OBJDIR} 2>>${ERRFILE}
fi
if [ "${OBJENV}" != "" ] ; then 
	mounter umount ${NDISTDIR} 2>>${ERRFILE}
fi

