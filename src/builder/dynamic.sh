#!/bin/sh
# $Id$
export PROGS="atacontrol awk bsdlabel bunzip2 bzcat bzip2 camcontrol cap_mkdb cat chmod cp csh date dconschat dd devfs df dhclient disklabel dmesg echo ee expr fdisk fsck_ffs fsck_msdosfs ftp ftpd fwcontrol geom getty grep groups gunzip gzcat gzip halt head id ifconfig jail jexec jls kenv kill kldconfig kldload kldstat kldunload less link ln login ls md5 mdconfig mdmfs mkdir more mount moused mv nc newfs pciconf ping powerd ps pwd pwd_mkdb reboot rm route sed sh sha1 sha256 ssh ssh-keygen sshd stty swapon syslogd tail tar tcsh tftp tftpd top umount uniq unlink usbdevs vidcontrol whoami zcat"
cp ${BUILDDIR}/lazybox.dynamic ${WORKDIR}/usr/src/rescue/rescue/Makefile
echo " [DONE]"


echo -n " * Building World ....."
cd ${WORKDIR}/usr/src/
if [ "${NO_CLEAN}" = "" ] ; then
	make  -DLOADER_TFTP_SUPPORT buildworld 2>>${ERRFILE} >>${ERRFILE}
fi
echo " [DONE]"

echo -n " * Populating DESTDIR=${DESTDIR} ....."
priv make hierarchy 2>>${ERRFILE} >>${ERRFILE}
rm -r ${DESTDIR}/rescue
mkdir -p ${DESTDIR}/rescue
priv make installworld 2>>${ERRFILE} >>${ERRFILE}
priv make distribution 2>>${ERRFILE} >>${ERRFILE}
mkdir -p ${DESTDIR}/usr/src
echo " [DONE]"

echo -n " * Populating FSDIR  ....."
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
for lib in $( for i in ${PROGS}
	do
		ldd -f "%o\n" ${i}
	done | sort | uniq )
do
	cp ${DESTDIR}/mnt/lib/${lib} ${FSDIR}${NDIR}/lib
done
for prog in ${PROGS}
do
	cp ${prog} ${FSDIR}${NBINDIR}/	
done
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
echo " [DONE]"
