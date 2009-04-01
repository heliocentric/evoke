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

# These are the cross compiling tools; we need it for strip and readelf.
CROSSTOOLSPATH=${MAKEOBJDIRPREFIX}/${TARGET}${WORKDIR}/usr/src/tmp/usr/bin

# Overwrite rescue with Lazybox
cp ${BUILDDIR}/lazybox.dynamic ${WORKDIR}/usr/src/rescue/rescue/Makefile

# Copy kernel config to the source.
cp ${BUILDDIR}/targets/FreeBSD/${RELEASE}/${TARGET}/kernconf ${WORKDIR}/usr/src/sys/${TARGET}/conf/${KERNCONF}

# Patch in the binary path into the kernel directly, so that loader.conf doesn't need to.
echo "options INIT_PATH=${N_BIN}/init:/sbin/init:/stand/sysinstall" >> ${WORKDIR}/usr/src/sys/${TARGET}/conf/${KERNCONF}

if [ "${ABI}" = "7" ] ; then
	svn co --force http://svn.freebsd.org/base/head/sys/contrib/dev/ath ${WORKDIR}/usr/src/sys/contrib/dev/ath
fi
cd ${WORKDIR}/usr/src/
if [ "${NO_BUILD_WORLD}" = "" ] ; then
	echo -n " * ${target} = Building World "
	make -DLOADER_TFTP_SUPPORT LOCAL_DIRS="nsrc" MAGICPATH="/config" buildworld 1>&2
	echo ""
fi
if [ "${NO_BUILD_KERNEL}" = "" ] ; then
	echo -n " * ${target} = Building Kernel "
	make buildkernel 1>&2
	echo ""
fi

echo -n " * ${target} = Populating DESTDIR"
priv make hierarchy 1>&2
# Keeps a bug in the rescue install from acting up.
rm -r ${DESTDIR}/rescue 1>&2
mkdir -p ${DESTDIR}/rescue 1>&2

mkdir -p ${DESTDIR}${BOOTPATH}/defaults
priv make distribution 1>&2
priv make installworld 1>&2
mkdir -p ${DESTDIR}/boot
cp ${DESTDIR}/usr/src/sys/${TARGET_ARCH}/conf/GENERIC.hints ${DESTDIR}${BOOTPATH}/device.hints
priv make INSTKERNNAME=${KERNCONF} installkernel 1>&2
mkdir -p ${DESTDIR}/usr/src
echo "				[DONE]"

echo -n " * ${target} = Building Ports "

if [ "${BUILD_PORTS}" != "" ] ; then
	# Since we chroot, we need these files in the target root.
	cp ${BUILDDIR}/portbuild.sh ${DESTDIR}/
	cp ${BUILDDIR}/varlist ${DESTDIR}/
	cp ${BUILDDIR}/portlist ${DESTDIR}/
	cp /etc/resolv.conf ${DESTDIR}/etc/
	ln -s usr/share/misc ${DESTDIR}/config
	# We'll share ports and port dist files, as they don't change.
	mkdir -p ${DESTDIR}/usr/ports

	# Needed by perl. Damn it.
	mount -t devfs devfs ${DESTDIR}/dev

	# sharing files.
	mount_nullfs -o ro /usr/ports ${DESTDIR}/usr/ports
	mkdir -p ${NDISTDIR}/ports
	mount_nullfs ${NDISTDIR}/ports ${DESTDIR}/usr/ports/distfiles

	# Only for i386 on amd64 building, which doesn't currently work anyway. Still.
	if [ "$(uname -p)" = "amd64" ] ; then
		if [ ${TARGET_ARCH} = i386 ] ; then
			cp ${DESTDIR}/libexec/ld-elf.so.1 ${DESTDIR}/libexec/ld-elf32.so.1
		fi
	fi
	
	# Work around the fact that 8-CURRENT no longer has kse, by forcing 6.x to use libthr
	if [ "${ABI}" = "6" ] ; then
		cat >${DESTDIR}/etc/libmap.conf << EOF
libpthread.so.2 libthr.so.2
libpthread.so libthr.so
libc_r.so.6 libthr.so.2
libc_r.so libthr.so
EOF
	fi
	# For ports, uname will return the correct values
	UNAME_r=${RELEASE}-RELEASE UNAME_m=${TARGET_ARCH} UNAME_p=${TARGET_ARCH} chroot ${DESTDIR} /portbuild.sh 1>&2
	rm ${DESTDIR}/libexec/ld-elf32.so.1
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

if [ -d "${NDISTDIR}/${TARGET_HASH}/packages" ] ; then
	cd ${NDISTDIR}/${TARGET_HASH}/packages
	for file in *
	do
		tar -xf ${file} --exclude '+*' -C ${DESTDIR}/usr/local/
	done
fi
echo "				[DONE]"

echo -n " * ${target} = Populating FSDIR"
cp ${DESTDIR}/libexec/ld-elf.so.1 ${FSDIR}${N_LIBEXEC}
mkdir -p ${DESTDIR}/mnt/bin

# Dear lord this is ugly. Still, it simplifies other things. That's my story, and I'm sticking to it.
mount_nullfs -o union ${DESTDIR}/usr/local/plan9/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/bin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/sbin ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/libexec ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/libexec ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/lib ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/lib ${DESTDIR}/mnt/bin
mount_nullfs -o union ${DESTDIR}/usr/local/lib ${DESTDIR}/mnt/bin

# Clear flags and permissions.
cd ${DESTDIR}/mnt/bin
chflags -R noschg *
chmod a+w *


PROGS="${PROGS} $(grep ^B ${BUILDDIR}/portlist | cut -d : -f 2)"

# "Mommy Mommy! Can I see some ugly shell scripting?"
# "Yes dear, but only if you gouge one eye out first"
# "Awwww"
#
# Seriously though, as you can see, we create a for loop to generate a list of libraries by using readelf on a binary,
# then we consolidate all libs (so there are no duplicates). Then we feed that to another for loop, which copies the libs in question to FSDIR, while creating compatibility symlinks.
# See? Simple. Just, slightly confusing if you aren't used to dealing with loop constructs like this.

resolve_libs() {
	for file in "$@"
	do
		echo "${file}" >&2
		TYPE="$(OPTIONS="quiet" filetype ${file})"
		case "${TYPE}" in
			application/x-executable)
				DEPENDENCIES=$(${CROSSTOOLSPATH}/readelf -d ${file} | grep '(NEEDED)' | cut -d [ -f 2 | cut -d ] -f 1)
				echo "${DEPENDENCIES}"
				resolve_libs ${DEPENDENCIES}
			;;
			application/x-sharedlib)
				DEPENDENCIES=$(${CROSSTOOLSPATH}/readelf -d ${file} | grep '(NEEDED)' | cut -d [ -f 2 | cut -d ] -f 1)
				echo "${file}"
				echo "${DEPENDENCIES}"
				resolve_libs ${DEPENDENCIES}
			;;
		esac
	done | sort | uniq

}



cd ${DESTDIR}/mnt/bin/
for lib in $(resolve_libs ${PROGS} ganglia/modcpu.so ganglia/moddisk.so ganglia/modload.so ganglia/modmem.so ganglia/modmulticpu.so ganglia/modnet.so ganglia/modproc.so ganglia/modsys.so)
do
	DIRECTORY="$(dirname ${lib})"
	FILE="$(basename ${lib})"

	echo "Working on ${lib}" 1>&2
	if [ "${DIRECTORY}" = "." ] ; then
		DEST="${FSDIR}/${N_LIB}/${FILE}"
	else
		mkdir -p ${FSDIR}/${N_LIB}/${DIRECTORY}
		DEST="${FSDIR}/${N_LIB}/${DIRECTORY}/${FILE}"
	fi

	cat ${lib} >${DEST}
	echo "Copying to ${DEST}" 1>&2
	case "${lib}" in
		*.so.*)
			ln -s ${FILE} $(echo $(echo ${DEST} | cut -d "." -f 1-2))
		;;
	esac
done

# Strip and copy the binaries to the FSDIR
${CROSSTOOLSPATH}/strip --remove-section=.note --remove-section=.comment --strip-unneeded ${PROGS}
tar -cLf - ${PROGS} | tar -xpf - -C ${FSDIR}${N_BIN}/	
cd ${FSDIR}${N_BIN}

# We were going to use a packer, but it did absolutely nothing to size (it can't compress libs, and they are the literal bulk of the size)
#upx ${PROGS}

# Strip all the libs too for good measure
cd ${OBJDIR}
cd ${FSDIR}${N_LIB}
${CROSSTOOLSPATH}/strip --remove-section=.note --remove-section=.comment --strip-unneeded *

# Remove all the nullfs mounts... nasty nasty nasty....
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
umount ${DESTDIR}/mnt/bin
umount ${DESTDIR}/mnt/bin

# Copy geom libs to FSDIR too
cp -r ${DESTDIR}/lib/geom ${FSDIR}${N_LIB}

# And then, lazybox
cd ${WORKDIR}/rescue
tar -cf - * | tar -xf - -C ${FSDIR}${N_BIN}/ 1>&2

# run through the geom list. We use geli because it is the only binary we explicitly need.

IFS="${FORFS}"
for geom in $(grep -v ^# ${BUILDDIR}/targets/FreeBSD/${RELEASE}/share/geomlist | grep -v ^$)
do
	ln ${FSDIR}${N_BIN}/geli ${FSDIR}${N_BIN}/${geom}
done
IFS="${OLDFS}"

# Grab the bootloader files, and place them in ${FSDIR}${N_BOOT}/

cd ${DESTDIR}/boot && tar -cf - boot mbr gptboot pmbr boot0 boot2 | tar -xvpf - -C ${FSDIR}${N_BOOT}/ 1>&2

echo "				[DONE]"
