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

CROSSTOOLSPATH=${MAKEOBJDIRPREFIX}/${TARGET}${WORKDIR}/usr/src/tmp/usr/bin

cp ${BUILDDIR}/lazybox.dynamic ${WORKDIR}/usr/src/rescue/rescue/Makefile
cp ${BUILDDIR}/kernels/${ABI}/${TARGET} ${WORKDIR}/usr/src/sys/${TARGET}/conf/${KERNCONF}
echo "options INIT_PATH=${NBINDIR}/init:/sbin/init:/stand/sysinstall" >> ${WORKDIR}/usr/src/sys/${TARGET}/conf/${KERNCONF}

echo -n " * ${target} = Building World "
cd ${WORKDIR}/usr/src/
if [ "${NO_BUILD_WORLD}" = "" ] ; then
	make -DLOADER_TFTP_SUPPORT LOADER_FIREWIRE_SUPPORT="yes" LOCAL_DIRS="nsrc" buildworld 1>&2
fi
if [ "${NO_BUILD_KERNEL}" = "" ] ; then
	make buildkernel 1>&2
fi
echo "				[DONE]"

echo -n " * ${target} = Populating DESTDIR"
priv make hierarchy 1>&2
rm -r ${DESTDIR}/rescue 1>&2
mkdir -p ${DESTDIR}/rescue 1>&2
priv make installworld 1>&2
priv make distribution 1>&2
priv make INSTKERNNAME=${KERNCONF} installkernel 1>&2
mkdir -p ${DESTDIR}/usr/src
echo "				[DONE]"

echo -n " * ${target} = Building Ports "
if [ "${BUILD_PORTS}" != "" ] ; then
	cp ${BUILDDIR}/portbuild.sh ${DESTDIR}/
	cp ${BUILDDIR}/portlist ${DESTDIR}/
	cp /etc/resolv.conf ${DESTDIR}/etc/
	mkdir -p ${DESTDIR}/usr/ports
	mkdir -p ${OBJDIR}/portsdists
	mount -t devfs devfs ${DESTDIR}/dev
	mount_nullfs -o ro /usr/ports ${DESTDIR}/usr/ports
	mount_nullfs ${OBJDIR}/portsdists ${DESTDIR}/usr/ports/distfiles
	chroot ${DESTDIR} /portbuild.sh 1>&2
	umount ${DESTDIR}/usr/ports/distfiles
	umount ${DESTDIR}/usr/ports
	umount ${DESTDIR}/dev
fi
echo "				[DONE]"

echo -n " * ${target} = Installing Packages "
mkdir -p ${DESTDIR}/usr/local/bin
mkdir -p ${DESTDIR}/usr/local/sbin
mkdir -p ${DESTDIR}/usr/local/lib
mkdir -p ${DESTDIR}/usr/local/libexec
mkdir -p ${DESTDIR}/usr/local/plan9/bin
mkdir -p ${DESTDIR}/usr/local/plan9/bin/venti

if [ -d "${NDISTDIR}/${target}/packages" ] ; then
	cd ${NDISTDIR}/${target}/packages
	for file in *
	do
		tar -xf ${file} --exclude '+*' -C ${DESTDIR}/usr/local/
	done
fi
echo "				[DONE]"

echo -n " * ${target} = Populating FSDIR"
cp ${DESTDIR}/libexec/ld-elf.so.1 ${FSDIR}${NDIR}/libexec/
mkdir -p ${DESTDIR}/mnt/lib
mkdir -p ${DESTDIR}/mnt/bin

mount_nullfs -o union ${DESTDIR}/usr/local/plan9/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/plan9/bin/venti ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/libexec ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/libexec ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/lib ${DESTDIR}/mnt/lib
mount_nullfs -o union ${DESTDIR}/usr/lib ${DESTDIR}/mnt/lib
mount_nullfs -o union ${DESTDIR}/usr/local/lib ${DESTDIR}/mnt/lib
cd ${DESTDIR}/mnt/lib
chflags -R noschg *
chmod a+w *
cd ${DESTDIR}/mnt/bin
chflags -R noschg *
chmod a+w *


PROGS="${PROGS} $(grep ^B ${BUILDDIR}/portlist | cut -d : -f 2)"
for lib in $( for i in ${PROGS} ${DESTDIR}/mnt/lib/pam*.so.?
	do
		${CROSSTOOLSPATH}/readelf -d ${i} | grep '(NEEDED)' | cut -d [ -f 2 | cut -d ] -f 1
	done | sort | uniq ) ${DESTDIR}/mnt/lib/pam_nologin.so.? ${DESTDIR}/mnt/lib/pam_opie.so.? ${DESTDIR}/mnt/lib/pam_opieaccess.so.? ${DESTDIR}/mnt/lib/pam_permit.so.? ${DESTDIR}/mnt/lib/pam_unix.so.? ${DESTDIR}/mnt/lib/pam_login_access.so.?
do
	cd ${DESTDIR}/mnt/lib/
	tar -cf - $(basename ${lib}) | tar -xf - -C ${FSDIR}${NDIR}/lib/
	ln -s $(basename ${lib}) ${FSDIR}${NDIR}/lib/$(echo $(basename ${lib}) | cut -d "." -f 1-2)
done

cd ${DESTDIR}/mnt/bin
${CROSSTOOLSPATH}/strip --remove-section=.note --remove-section=.comment --strip-unneeded ${PROGS}
tar -cLf - ${PROGS} | tar -xpf - -C ${FSDIR}${NBINDIR}/	
cd ${FSDIR}${NBINDIR}
#upx ${PROGS}
cd ${OBJDIR}
cd ${FSDIR}${NDIR}/lib
${CROSSTOOLSPATH}/strip --remove-section=.note --remove-section=.comment --strip-unneeded *
umount ${DESTDIR}/mnt/lib
umount ${DESTDIR}/mnt/lib
umount ${DESTDIR}/mnt/lib
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin

cp -r ${DESTDIR}/lib/geom ${FSDIR}${NDIR}/lib/
cd ${WORKDIR}/rescue
tar -cf - * | tar -xf - -C ${FSDIR}${NBINDIR}/ 1>&2
echo "				[DONE]"
