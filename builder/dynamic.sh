#!/bin/sh
# Copyright 2007-2010 Dylan Cochran
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
#cp ${BUILDDIR}/lazybox.dynamic ${WORKDIR}/usr/src/rescue/rescue/Makefile

if [ -f "${BUILDDIR}/targets/FreeBSD/${RELEASE}/share/whitelist" ] ; then
	# Add support for the 'whitelist' commands.
	cp "${BUILDDIR}/targets/FreeBSD/${RELEASE}/share/whitelist" ${WORKDIR}/usr/src/rescue/rescue/Makefile
fi

# Copy kernel config to the source.
cp ${BUILDDIR}/targets/FreeBSD/${RELEASE}/${TARGET}/kernconf ${WORKDIR}/usr/src/sys/${TARGET}/conf/${KERNCONF}


# Patch in the binary path into the kernel directly, so that loader.conf doesn't need to.

VERSIONLIST="$(echo "${TARGETLIST}" | cut -d : -f 4 | sort -r | uniq)"
INIT_PATH="${N_BIN}/nexusd:${N_BIN}/init:/system/FreeBSD-${RELEASE}/i386/bin/nexusd:/system/FreeBSD-${RELEASE}/i386/bin/init"

for version in ${VERSIONLIST}
do
	if [ "$(echo "${version}" | cut -d . -f 1)" -lt "$(echo "${RELEASE}" | cut -d . -f 1)" ] ; then
		if [ "${TARGET_ARCH}" = "amd64" ] ; then		
			INIT_PATH=${INIT_PATH}:/system/FreeBSD-${version}/amd64/bin/nexusd
			INIT_PATH=${INIT_PATH}:/system/FreeBSD-${version}/amd64/bin/init
			INIT_PATH=${INIT_PATH}:/system/FreeBSD-${version}/i386/bin/nexusd
			INIT_PATH=${INIT_PATH}:/system/FreeBSD-${version}/i386/bin/init
		else
			INIT_PATH=${INIT_PATH}:/system/FreeBSD-${version}/${TARGET_ARCH}/bin/nexusd
			INIT_PATH=${INIT_PATH}:/system/FreeBSD-${version}/${TARGET_ARCH}/bin/init
		fi
	fi
done

echo "options INIT_PATH=${INIT_PATH}:/sbin/init:/stand/sysinstall" >> ${WORKDIR}/usr/src/sys/${TARGET}/conf/${KERNCONF}

if [ "${ABI}" = "7" ] ; then
	svn co --force http://svn.freebsd.org/base/head/sys/contrib/dev/ath ${WORKDIR}/usr/src/sys/contrib/dev/ath
fi
cd ${WORKDIR}/usr/src/
if [ "${NO_BUILD_WORLD}" = "" ] ; then
	echo " * ${target} = Building World "
	make -DLOADER_TFTP_SUPPORT LOCAL_DIRS="nsrc" MAGICPATH="/config" -DWITHOUT_LIB32 buildworld 1>&2
fi
if [ "${NO_BUILD_KERNEL}" = "" ] ; then
	echo " * ${target} = Building Kernel "
	make buildkernel 1>&2
fi

echo " * ${target} = Populating DESTDIR"
priv make hierarchy 1>&2
# Keeps a bug in the rescue install from acting up.
rm -r ${DESTDIR}/rescue 1>&2
mkdir -p ${DESTDIR}/rescue 1>&2
rm -r ${DESTDIR}/whitelist 1>&2
mkdir -p ${DESTDIR}/whitelist 1>&2

mkdir -p ${DESTDIR}${BOOTPATH}/defaults
priv make distribution 1>&2
mkdir -p ${DESTDIR}/usr/src/tmp/config

priv make LOCAL_DIRS="nsrc" -DWITHOUT_LIB32 installworld 1>&2
mkdir -p ${DESTDIR}/boot
cp ${DESTDIR}/usr/src/sys/${TARGET_ARCH}/conf/GENERIC.hints ${DESTDIR}${BOOTPATH}/device.hints
priv make INSTKERNNAME=${KERNCONF} installkernel 1>&2
mkdir -p ${DESTDIR}/usr/src

if [ "${BUILD_PORTS}" != "" -a "${KERNEL_ONLY}" = "no" ] ; then
	echo " * ${target} = Building Ports "

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
	if [ ${TARGET_ARCH} = i386 ] ; then
		cp ${DESTDIR}/libexec/ld-elf.so.1 ${DESTDIR}/libexec/ld-elf32.so.1
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
	umount ${DESTDIR}/usr/ports/distfiles
	umount ${DESTDIR}/usr/ports
	umount ${DESTDIR}/dev
	echo " * ${target} = Installing Packages "

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

	echo " * ${target} = Populating FSDIR"
	cd ${DESTDIR}/libexec && tar -cf - * | tar -xvpf - -C ${FSDIR}${N_LIBEXEC}


	mkdir -p ${DESTDIR}/mnt/bin
	mkdir -p ${DESTDIR}/mnt/lib

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
	mount_nullfs -o union ${DESTDIR}/lib ${DESTDIR}/mnt/lib
	mount_nullfs -o union ${DESTDIR}/usr/lib ${DESTDIR}/mnt/lib
	mount_nullfs -o union ${DESTDIR}/usr/local/lib ${DESTDIR}/mnt/lib

	# Clear flags and permissions.
	cd ${DESTDIR}/mnt/bin
	chflags -R noschg *
	chmod a+w *
	cd ${DESTDIR}/mnt/lib
	chflags -R noschg *
	chmod a+w *


	PROGS="${PROGS} $(grep -v ^# ${BUILDDIR}/portlist | grep ^B: | cut -d : -f 2)"

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
			TYPE="$(OPTIONS="quiet" filetype ${RESOLVE_BINDIR}/${file})"
			if [ "${TYPE}" = "" ] ; then
				TYPE="$(OPTIONS="quiet" filetype ${RESOLVE_LIBDIR}/${file})"
			fi
			case "${TYPE}" in
				application/x-executable)
					DEPENDENCIES=$(${CROSSTOOLSPATH}/readelf -d ${DESTDIR}/mnt/bin/${file} | grep '(NEEDED)' | cut -d [ -f 2 | cut -d ] -f 1)
					echo "${DEPENDENCIES}"
					resolve_libs ${DEPENDENCIES}
				;;
				application/x-sharedlib)
					DEPENDENCIES=$(${CROSSTOOLSPATH}/readelf -d ${DESTDIR}/mnt/lib/${file} | grep '(NEEDED)' | cut -d [ -f 2 | cut -d ] -f 1)
					echo "${file}"
					echo "${DEPENDENCIES}"
					resolve_libs ${DEPENDENCIES}
				;;
			esac
		done | sort | uniq

	}

	RESOLVE_BINDIR="${DESTDIR}/mnt/bin"
	RESOLVE_LIBDIR="${DESTDIR}/mnt/lib"
	echo "Executing resolve_libs" >&2
	cd ${DESTDIR}/mnt/bin/
	BASELIBS=$(resolve_libs ${PROGS})
	echo "${BASELIBS}" >&2
	cd ${DESTDIR}/mnt/lib
	EXTRALIBS="$(echo libasn1.so.* ggi/input/stdin.so ggi/input/vgl.so ggi/display/vgl.so)"
	echo "${EXTRALIBS}" >&2
	for lib in ${BASELIBS} ganglia/modcpu.so ganglia/moddisk.so ganglia/modload.so ganglia/modmem.so ganglia/modmulticpu.so ganglia/modnet.so ganglia/modproc.so ganglia/modsys.so ${EXTRALIBS}
 	do
		cd ${DESTDIR}/mnt/lib
		DIRECTORY="$(dirname ${lib})"
		FILE="$(basename ${lib})"

		echo "Working on ${lib}" >&2
		if [ "${DIRECTORY}" = "." ] ; then
			DEST="${FSDIR}/${N_LIB}/${FILE}"
		else
			mkdir -p ${FSDIR}/${N_LIB}/${DIRECTORY}
			DEST="${FSDIR}/${N_LIB}/${DIRECTORY}/${FILE}"
		fi

		cat ${DESTDIR}/mnt/lib/${lib} >${DEST}
		echo "Copying to ${DEST}" >&2
		case "${lib}" in
			*.so.*)
				ln -s ${FILE} $(echo $(echo ${DEST} | cut -d "." -f 1-2))
			;;
		esac
	done
	cd ${DESTDIR}/mnt/bin
	# Strip and copy the binaries to the FSDIR
	${CROSSTOOLSPATH}/strip --remove-section=.note --remove-section=.comment --strip-unneeded ${PROGS}
	tar -cLf - ${PROGS} | tar -xpf - -C ${FSDIR}${N_BIN}/	
	cd ${FSDIR}${N_BIN}

	for binary in $(grep -v ^# ${BUILDDIR}/portlist | grep ^B: | cut -d : -f 2,5)
	do
		STARTNAME="$(echo ${binary} | cut -d : -f 1)"
		ENDNAME="$(echo ${binary} | cut -d : -f 2)"
		if [ "${ENDNAME}" != "" ] ; then
			mv "${STARTNAME}" "${ENDNAME}"
		fi
	done

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
	umount ${DESTDIR}/mnt/lib
	umount ${DESTDIR}/mnt/lib
	umount ${DESTDIR}/mnt/lib


	echo " * ${target} = Copying Directories to ${N_BINSHARE}"

	for file in $(grep -v ^# ${BUILDDIR}/portlist | grep ^D: | awk -F : '{ if ($4 == "binshare") { print $2; } }')
	do

		DIRNAME="$(dirname ${file})"
		DIRECTORY="$(basename ${file})"
		if [ -d "${DESTDIR}/${DIRNAME}" ] ; then
			cd ${DESTDIR}/${DIRNAME}
			echo " * ${target} = Copying ${DESTDIR}/${DIRNAME}/${DIRECTORY} to ${N_BINSHARE}"
			tar -cf - "${DIRECTORY}" | tar -xvpf - -C "${FSDIR}${N_BINSHARE}/"
		fi
	done

	# Copy geom libs to FSDIR too
	cp -r ${DESTDIR}/lib/geom ${FSDIR}${N_LIB}


	# run through the geom list. We use geli because it is the only binary we explicitly need.

	IFS="${FORFS}"
	for geom in $(grep -v ^# ${BUILDDIR}/targets/FreeBSD/${RELEASE}/share/geomlist | grep -v ^$)
	do
		ln ${FSDIR}${N_BIN}/geli ${FSDIR}${N_BIN}/${geom}
	done
	IFS="${OLDFS}"

	# Grab the bootloader files, and place them in ${FSDIR}${N_BOOT}/

	cd ${DESTDIR}/boot && tar -cf - boot mbr gptboot pmbr boot0 boot2 | tar -xvpf - -C ${FSDIR}${N_BOOT}/ 1>&2
else
	# Copy the whitelist contents.
	mkdir -p "${FSDIR}${N_BIN}"
	cd ${DESTDIR}/whitelist && tar -cf - * | tar -xvpf - -C "${FSDIR}${N_BIN}/"
fi
