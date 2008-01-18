#!/bin/sh
# Copyright 2007-2008 Dylan Cochran
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
export TARGETS="6.3-RC2/i386 7.0-RC1/i386"

# DamnSmallBSD Version
export VERSION="HEAD"

# Release Engineer
export ENGINEER="Dylan Cochran"


# List of programs in base to add to the image.
# The script already handles resolving libraries, and lazybox provides
# utilities needed by merger, and systart until merger has been ran.

export PROGS="
atacontrol awk bsdlabel bunzip2 bzcat bzip2 camcontrol cap_mkdb 
cat chmod cp csh date dconschat dd devfs df dhclient disklabel dmesg echo 
ee expr fdisk fsck_ffs fsck_msdosfs ftp ftpd fwcontrol geom getty grep 
groups gunzip gzcat gzip halt head id ifconfig jail jexec jls kenv kill 
kldconfig kldload kldstat kldunload less link ln login ls md5 mdconfig 
mdmfs mkdir more mount moused mv nc newfs pciconf ping powerd ps pwd 
pwd_mkdb reboot rm route sed sh sha1 sha256 ssh ssh-keygen sshd stty 
swapon swapoff swapinfo syslogd tail tar tcsh tftp tftpd top umount 
uniq unlink usbdevs vidcontrol whoami zcat sort pfctl du makefs 
mount_msdosfs
"

# List of kernel objects in base that will be on the image. Ports modules
# are added automatically.

export MODULES="
acpi dcons dcons_crom nullfs geom_label geom_mirror geom_concat geom_eli
geom_nop geom_raid3 geom_shsec geom_stripe pf crypto zlib speaker tmpfs
"

export ROOTDIR=`pwd`

# Overridable options

if [ "${TMPDIR}" = "" ] ; then
	export TMPDIR="/tmp"
fi
if [ "${NDISTDIR}" = "" ] ; then
	export NDISTDIR="${ROOTDIR}/dists"
fi
if [ "${OBJDIR}" = "" ] ; then
	export OBJDIR="${ROOTDIR}/obj"
fi


unset WRKDIRPREFIX
export ERRFILE=${ROOTDIR}/logs/$(date +%Y%m%d%H%M%S).log

echo -n " * share = Cleaning up"

chflags -R noschg ${OBJDIR} 2>>${ERRFILE}
rm -r ${OBJDIR} 2>>${ERRFILE}
mkdir -p ${OBJDIR} 2>>${ERRFILE}
export BUILDDIR=${ROOTDIR}/builder
echo "						[DONE]"

${BUILDDIR}/build.sh 2>>${ERRFILE}
