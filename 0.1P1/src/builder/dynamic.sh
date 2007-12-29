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
export PROGS="atacontrol awk bsdlabel bunzip2 bzcat bzip2 camcontrol cap_mkdb cat chmod cp \
csh date dconschat dd devfs df dhclient disklabel dmesg echo ee expr fdisk fsck_ffs fsck_msdosfs \
ftp ftpd fwcontrol geom getty grep groups gunzip gzcat gzip halt head id ifconfig jail jexec jls kenv \
kill kldconfig kldload kldstat kldunload less link ln login ls md5 mdconfig mdmfs mkdir more mount moused \
mv nc newfs pciconf ping powerd ps pwd pwd_mkdb reboot rm route sed sh sha1 sha256 ssh ssh-keygen \
sshd stty swapon syslogd tail tar tcsh tftp tftpd top umount uniq unlink usbdevs vidcontrol whoami \
zcat sort pfctl"
cp ${BUILDDIR}/lazybox.dynamic ${WORKDIR}/usr/src/rescue/rescue/Makefile


echo -n " * ${target} = Building World ....."
cd ${WORKDIR}/usr/src/
if [ "${NO_CLEAN}" = "" ] ; then
	make  -DLOADER_TFTP_SUPPORT LOCAL_DIRS="nsrc" buildworld 2>>${ERRFILE} >>${ERRFILE}
fi
echo "				[DONE]"

echo -n " * ${target} = Populating DESTDIR"
priv make hierarchy 2>>${ERRFILE} >>${ERRFILE}
rm -r ${DESTDIR}/rescue
mkdir -p ${DESTDIR}/rescue
priv make installworld 2>>${ERRFILE} >>${ERRFILE}
priv make distribution 2>>${ERRFILE} >>${ERRFILE}
mkdir -p ${DESTDIR}/usr/src
echo "				[DONE]"

echo -n " * ${target} = Populating FSDIR"
cp ${DESTDIR}/libexec/ld-elf.so.1 ${FSDIR}${NDIR}/libexec/
mkdir -p ${DESTDIR}/mnt/lib
mkdir -p ${DESTDIR}/mnt/bin

mount_nullfs -o union ${DESTDIR}/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/libexec ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/lib ${DESTDIR}/mnt/lib
mount_nullfs -o union ${DESTDIR}/usr/lib ${DESTDIR}/mnt/lib
cd ${DESTDIR}/mnt/bin
for lib in $( for i in ${PROGS} ${DESTDIR}/mnt/lib/pam*.so.?
	do
		ldd -f "%o\n" ${i}
	done | sort | uniq ) ${DESTDIR}/mnt/lib/pam*.so.?
do
	cd ${DESTDIR}/mnt/lib/
	strip --remove-section=.note --remove-section=.comment ${lib}
	cp $(basename ${lib}) ${FSDIR}${NDIR}/lib
	ln -s ${lib} ${FSDIR}${NDIR}/lib/$(echo $(basename ${lib}) | cut -d "." -f 1-2)
done
cd ${DESTDIR}/mnt/bin
strip --remove-section=.note --remove-section=.comment ${PROGS}
tar -cLf - ${PROGS} | tar -xf - -C ${FSDIR}${NBINDIR}/	
cd ${WRKDIRPREFIX}
umount ${DESTDIR}/mnt/lib
umount ${DESTDIR}/mnt/lib
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
cp -r ${DESTDIR}/lib/geom ${FSDIR}${NDIR}/lib/
cd ${WORKDIR}/rescue
tar -cf - * | tar -xf - -C ${FSDIR}${NBINDIR}/ 2>>${ERRFILE} >>${ERRFILE}
echo "				[DONE]"
