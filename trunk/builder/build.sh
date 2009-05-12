#!/bin/sh
# $Id$

# Here for a day when almost everything can be done from an unprivileged user.
# Unfortunately, that day is not today.
# So keep it for the places that would be critical if we had a choice.
priv () {
	if [ "${USE_SUDO}" = "YES" ] ; then
		sudo $*
	else
		$*
	fi
}

export FORFS="
"
export OLDFS=" 	
"
export SVNDATE="$(svn info --xml | awk '/<date>/, /<\/date>/' | sed 's@<date>@@g' | sed 's@</date>@@g' | sed 's@T@ @g' | cut -d '.' -f 1)"
export TRACKFILE_DATE="$(date -j -f "%Y-%m-%dT%H:%M:%S" "${SVNDATE}" "+%s")"

# BOOTDIR is the 'boot' directory; it's the root of the cd image
export BOOTDIR=${OBJDIR}/bdir

# FSDIR is the root of the root.fs image
export FSDIR=${OBJDIR}/fsdir

# The prefix for this version, for BOOTDIR, so we can avoid collisions with FreeBSD.
export BOOTPREFIX=/evoke/${VERSION}/${REVISION}

# PRODUCTDIR is where the filesystem images are stored.
export PRODUCTDIR=${BOOTPREFIX}/product

TARGETLIST="$(cat ${BUILDDIR}/targetlist | grep -v ^$ | grep -v ^#)"

for target in $(cat ${BUILDDIR}/targetlist | grep -v ^$ | grep -v ^#)
do
	# The TARGET and TARGET_ARCH are used by buildworld, and also internally
	# except for PC98, they are the same.
	export TARGET_HASH=$(echo ${target} | md5 -q)
	export TARGET=$(echo ${target} | cut -d ":" -f 3)
	export TARGET_ARCH="${TARGET}"

	# Release (eg, 6.3)
	export RELEASE=$(echo ${target} | cut -d ":" -f 4)

	# Kernel ABI (eg, 7 for 7.0-RELEASE or 7.1-RELEASE)
	export ABI=$(echo ${target} | cut -d ":" -f 2)

	# Kernel config definition; since boot loader versioning works now,
	# no need to use anything other then kernel
	export KERNCONF="kernel"

	# for installkernel/installworld and places in the script
	# that need to know where installworld is putting things
	export DESTDIR=${OBJDIR}/${TARGET_HASH}
	mkdir -p ${DESTDIR}

	# erm, why is this here? might be removable, older version probably treated 
	# them seperately.
	export WORKDIR=${DESTDIR}
	mkdir -p ${WORKDIR}

	# N_ prefix variables are for the file copies from DESTDIR to FSDIR, the 
	# targets are arch and abi specific.
	export N_DIR=/system/FreeBSD-${RELEASE}/${TARGET}
	export N_SHAREBIN=/system/share/bin
	export N_SHARELIB=/system/share/lib
	export N_BIN=${N_DIR}/bin
	export N_LIB=${N_DIR}/lib
	export N_LIBEXEC=${N_DIR}/libexec
	export N_BOOT=${N_DIR}/boot
	export N_BINSHARE=${N_DIR}/share

	mkdir -p ${FSDIR}${N_BIN} 1>&2
	mkdir -p ${FSDIR}${N_LIB} 1>&2
	mkdir -p ${FSDIR}${N_LIBEXEC} 1>&2
	mkdir -p ${FSDIR}${N_BOOT} 1>&2
	mkdir -p ${FSDIR}${N_BINSHARE} 1>&2

	# This forces same architecture buildworld/buildkernels to build cross-tools
	# and build-tools adequately.
	# ...
	#
	# DO NOT REMOVE UNDER PENALTY OF DEATH.
	export CROSS_BUILD_TESTING=yes

	# Extract source distfiles into ${DESTDIR}
#	SRCDIR="${NDISTDIR}/${RELEASE}" DISTS="src" ${ROOTDIR}/share/bin/distextract 1>&2
	export URL=$(echo ${target} | cut -d ":" -f 5)
	export URLREV=$(echo ${target} | cut -d ":" -f 6)
	export SRCDIR=${NDISTDIR}/${URL}/src
	mkdir -p ${SRCDIR}
	if [ -d ${SRCDIR}/.svn ] ; then
		cd ${SRCDIR}
		svn up -r ${URLREV} ${SRCDIR} 1>&2
	else
		svn co http://svn.freebsd.org/base/${URL}@${URLREV} ${SRCDIR} 1>&2
	fi
	cd ${SRCDIR} 
	mkdir -p ${DESTDIR}/usr/src
	tar -cpf - * | tar -xvpf - -C ${DESTDIR}/usr/src/
	ERROR="$?"
	if [ "${ERROR}" != "0" ] ; then
		# Wooo, real error message now.
		echo "Source dist extraction failed."
		echo "Error code: ${ERROR}"
		exit 1
	fi
	if [ "${RELEASE}" = "7.1" ] ; then
		cd ${DESTDIR}/usr/src/sys
		rm -r boot
		svn co http://svn.freebsd.org/base/releng/7.2/sys/boot boot 1>&2
	fi

	echo " * ${target} = Patching World"


	# Before we do anything else, apply all diffs in the shared directory for the release.

	PATCHLIST="$(echo ${BUILDDIR}/targets/FreeBSD/${RELEASE}/share/patches/*)"
	if [ "${PATCHLIST}" != "" ] ; then
		cd ${WORKDIR}/usr/src

		for patchfile in ${PATCHLIST}
		do
			patch -p0 <"${patchfile}" >&2
		done
	fi

	# Ok, we need to patch around some hard coded paths in src/
	cd ${WORKDIR}/usr/src/sys/boot/

	# This changes per ${target}
	export BOOTPATH="${BOOTPREFIX}/FreeBSD/${RELEASE}/${TARGET}"
	mkdir -p ${BOOTDIR}${BOOTPATH}

	# Get rid of /libexec/ld-elf.so.1, and use the rtld in each arch+abi specific directory.
	for file in /usr/src/sys/${TARGET}/${TARGET}/elf_machdep.c
	do
		sed -i .bak "s@/libexec/ld-elf.so.1@${N_LIBEXEC}/ld-elf.so.1" ${WORKDIR}${file} 1>&2
	done

	# Point rtld to ${N_LIBDIR} instead of the /lib, hopefully, this will allow us to compile the system with 
	# only init statically linked. 
	sed -i .bak "s@/lib:/usr/lib@${N_LIBDIR}" ${WORKDIR}/usr/src/libexec/rtld-elf/rtld.h 1>&2

	# Remove the ld-elf32.so.1 kludge in favor of a more universal method.
	for file in /usr/src/sys/compat/ia32/ia32_sysvec.c /usr/src/libexec/rtld-elf/rtld.c /usr/src/libexec/rtld-elf/debug.h
	do
		sed -i .bak "s@/libexec/ld-elf32.so.1@/system/FreeBSD-${ABI}/i386/libexec/ld-elf.so.1" ${WORKDIR}${file} 1>&2
	done

	# Patch these files to our paths, so they don't collide.
	# This is the bulk of the boot loader versioning support.
	sed -i .bak "s@/boot/device.hints@${BOOTPATH}/device.hints@g" ${WORKDIR}/usr/src/sys/boot/forth/loader.conf 1>&2
	sed -i .bak "s@/boot/loader.conf.local@/evoke/misc/site.conf@g" ${WORKDIR}/usr/src/sys/boot/forth/loader.conf 1>&2
	sed -i .bak "s@/boot/loader.conf@${BOOTPREFIX}/loader.conf@g" ${WORKDIR}/usr/src/sys/boot/forth/loader.conf 1>&2
	for file in $(cat ${BUILDDIR}/bootlist)
	do
	    # This works for most.
	    sed -i .bak "s@/boot/@${BOOTPATH}/@g" ${WORKDIR}${file} 1>&2
	    # This is for cdboot. Case specific
	    sed -i .bak "s@/BOOT/@$(echo ${BOOTPATH} | tr a-z A-Z)/@g" ${WORKDIR}${file} 1>&2
	done

	# Get rid of this latency addition in pxeboot (fixed in 7.0, but necessary on 6.x)
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 1>&2

	# rescue binaries hard code /rescue; for us, it's more productive to point it to the abi/arch 
	# directory directly. It makes systart transparent.
	sed -i .bak "s@\"/rescue@\"${N_BIN}@g" ${WORKDIR}/usr/src/include/paths.h 1>&2


	# we don't have a real /etc, so point init to systart.
	sed -i .bak "s_\"/etc/rc_\"${N_SHAREBIN}/systart_g" ${WORKDIR}/usr/src/sbin/init/pathnames.h 1>&2

	# Patch for lib/libmagic's build-tools target.
	sed -i .bak "s_usr/sbin usr/share/misc_usr/sbin usr/share/misc config_g" ${WORKDIR}/usr/src/Makefile.inc1 1>&2

	# We use TMPDIR so that it can be different then the OBJDIR, as TMPDIR is write heavy.
	export MAKEOBJDIRPREFIX=${OBJDIR}/obj/${TARGET_HASH}
	mkdir -p ${MAKEOBJDIRPREFIX}


	# This copies nsrc to src/, to compile our own code. For some reason does not work, but non-critical.

	cd ${BUILDDIR}/targets/FreeBSD/share/
	tar -cf - nsrc | tar -xf - -C ${DESTDIR}/usr/src/

	cd ${DESTDIR}/usr/src/nsrc
	FILELIST="$(find . -not -path \*.svn\* -not -type d)"

	sed -i .bak "s@%%ABI%%@FreeBSD-${RELEASE}@g" ${FILELIST}
	sed -i .bak "s@%%ARCH%%@${TARGET}@g" ${FILELIST}

	# Allow us to build both statically and dynamically. Note, it needs to be automated more.

	case "${1}" in
		[sS][tT][aA][tT][iI][cC])
			. ${BUILDDIR}/static.sh
		;;
		[dD][yY][nN][aA][mM][iIk][cC])
			. ${BUILDDIR}/dynamic.sh
		;;
		*)
			. ${BUILDDIR}/dynamic.sh
		;;
	esac

	echo " * ${target} = Compressing Kernel"
	cd ${DESTDIR}/boot/${KERNCONF}/

	# Grab port modules and copy them to the kernel directory.
	for file in $(grep -v ^# ${BUILDDIR}/portlist | grep ^M: | cut -d : -f 2)
	do
		if [ -f ${DESTDIR}/usr/local/modules/${file}.ko ] ; then
			cp ${DESTDIR}/usr/local/modules/${file}.ko ./
		else
			cp ${DESTDIR}/boot/modules/${file}.ko ./
		fi
	done

	if [ "${EVOKE_BUILDER_GZIPKERN}" = "yes" ] ; then
		gzip -9nc kernel >kernel.gz
		rm kernel
	fi
	for file in $(grep -v ^# ${BUILDDIR}/portlist | grep ^M: | cut -d : -f 2) ${MODULES}
	do
		if [ "${EVOKE_BUILDER_GZIPKERN}" = "yes" ] ; then
			gzip -9nc ${file}.ko >${file}.ko.gz
		else
			mv ${file}.ko ${file}.ka
		fi
	done
	# Remove everything that is not gzipped.
	rm -r *.symbols
	rm -r *.ko
	rm -r *.hints
	if [ "${EVOKE_BUILDER_GZIPKERN}" != "yes" ] ; then
		for file in $(grep -v ^# ${BUILDDIR}/portlist | grep ^M: | cut -d : -f 2) ${MODULES}
		do
				mv ${file}.ka ${file}.ko
		done
	fi


	echo " * ${target} = Populating BOOTPATH"

	# Shouldn't tar be doing this?
	mkdir -p ${BOOTDIR}${BOOTPATH}/defaults 1>&2
	cd ${DESTDIR}/boot && tar -cf - --exclude loader.old --exclude modules * | tar -xvf - -C ${BOOTDIR}${BOOTPATH} 1>&2
	# Yes, we need it twice. Why? Because only certain things in the build system are boot versioned. So it's split across two directories.
	cd ${DESTDIR}${BOOTPATH} && tar -cf - --exclude loader.old * | tar -xvf - -C ${BOOTDIR}${BOOTPATH} 1>&2

	cp ${BOOTDIR}${BOOTPATH}/pxeboot ${BOOTDIR}${BOOTPATH}/pxeboot-qemu && chmod o+w ${BOOTDIR}${BOOTPATH}/pxeboot-qemu && echo >> ${BOOTDIR}${BOOTPATH}/pxeboot-qemu
	mv "${BOOTDIR}${BOOTPATH}/pxeboot-qemu" "${BOOTDIR}${BOOTPATH}/pxeboot"

done

echo " * share = Populating FSDIR"

# These directories are defined in the Hierarchy.
mkdir -p ${FSDIR}/bin
mkdir -p ${FSDIR}/lib
mkdir -p ${FSDIR}/libexec
mkdir -p ${FSDIR}/boot
mkdir -p ${FSDIR}/dev
mkdir -p ${FSDIR}/mem
mkdir -p ${FSDIR}/config

# Compat scaffolding; Be patched out eventually. However, as all it does is make things look worse, it isn't that bad.

# This is needed for tcsh
mkdir -p ${FSDIR}/usr/share/misc
ln -s /config/termcap ${FSDIR}/usr/share/misc/
ln -s /lib ${FSDIR}/usr/lib
mkdir -p ${FSDIR}/home/root
ln -s /config  ${FSDIR}/etc
ln -s /mem  ${FSDIR}/var
ln -s /mem/scratch ${FSDIR}/tmp
ln -s /bin ${FSDIR}/sbin

# Needed for ganglia
mkdir -p ${FSDIR}/usr/local
ln -s /lib ${FSDIR}/usr/local/lib
ln -s /bin ${FSDIR}/usr/local/bin
ln -s /bin ${FSDIR}/usr/local/sbin
ln -s /bin ${FSDIR}/usr/bin
ln -s /bin ${FSDIR}/usr/sbin
ln -s /bin ${FSDIR}/usr/local/libexec
ln -s /bin ${FSDIR}/usr/libexec
ln -s /config ${FSDIR}/usr/local/etc



cd ${ROOTDIR}
# Mirror directory tree of share/
for dir in $(find share/ -not -path \*.svn\* -type d)
do
	mkdir -p ${FSDIR}/system/${dir}
done

# Add files in share/ to FSDIR/share, however, strip them of all comments and copyrights for space saving.
for file in $(find share/ -not -path \*.svn\* -not -type d)
do
	grep '#!' ${file} | head -1 >${FSDIR}/system/${file}
	grep '$Id' ${file} | head -1 >>${FSDIR}/system/${file}
	grep -v "^#" ${file} | grep -v ^$ >>${FSDIR}/system/${file}
	chmod a+rx ${FSDIR}/system/${file}
done

mkdir -p ${FSDIR}/system/share/lib/zoneinfo

cd ${DESTDIR}/usr/share/zoneinfo
tar -cf - * | tar -xpf - -C ${FSDIR}/system/share/lib/zoneinfo/

cp "${EVOKE_BUILDER_PUBLIC}" "${FSDIR}/system/share/lib/evoke_public.rsa"
echo "/dev/md0		/	ufs	rw	1	1" >${FSDIR}/system/share/lib/fstab

mkdir -p ${FSDIR}/system/share/doc

if [ -d "${ROOTDIR}/doc" ] ; then
	cd ${ROOTDIR}/doc
	for file in $(ls)
	do
		ISDOC=$(grep ^#labels ${file} | grep Doc)
		if [ "${ISDOC}" != "" ] ; then
			cp ${file} ${FSDIR}/system/share/doc/${file}
		fi
 	done
fi

chmod -R 555 ${FSDIR}/system
chflags -R schg ${FSDIR}/system

echo " * share = Creating root.fs"
# Make evoke.fs, the main product filesystem.
mkdir -p ${BOOTDIR}${PRODUCTDIR}
cd ${BOOTDIR}${PRODUCTDIR}
makefs evoke.fs ${FSDIR} 1>&2
MDDEVICE=$(priv mdconfig -af evoke.fs)

# Trust me, this is necessary; sha256 the file returns a different hash then the device node
FINGERPRINT=$(sha256 -q /dev/${MDDEVICE})
priv mdconfig -d -u $(echo ${MDDEVICE} | cut -c 3-100)
gzip -9nc evoke.fs >evoke.fs.gz
rm evoke.fs 1>&2

# Add all MODULES and port modules to loader.conf
for module in ${MODULES} $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2)
do
	echo "${module}_load=\"YES\"" >>${BOOTDIR}${BOOTPREFIX}/loader.conf
done

cat >>${BOOTDIR}${BOOTPREFIX}/loader.conf << EOF
kernel="${KERNCONF}"
kernel_options="-r"
mfsroot_load="YES"
mfsroot_type="mfs_root"
mfsroot_name="${PRODUCTDIR}/evoke.fs"
trackfile_load="YES"
trackfile_type="mfs_root"
trackfile_name="${BOOTPREFIX}/trackfile"
evoke.trackfile="md1"
evoke.fingerprint="${FINGERPRINT}"
evoke.moused="yes"
evoke.version="${VERSION}/${REVISION}"
evoke.misc.message="YES"
boot_multicons="YES"
kern.hz=100
EOF



echo " * share = Making cmdlist, modlist and abi"

# Easier to list it this way now.

for i in ${MODULES} $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2 | sort | uniq)
do
	echo ${i} >>${BOOTDIR}${BOOTPREFIX}/modlist
done

for i in ${PROGS} $(grep -v ^# ${BUILDDIR}/portlist | grep ^B: | cut -d : -f 2) $(grep CRUNCH_LINKS ${BUILDDIR}/lazybox.dynamic | grep -v ^# | grep -v for | cut -d ' ' -f 2-20 | paste -d " " - - - - - - - - - - - - - - - - - - - - - ) $(grep CRUNCH_PROGS ${BUILDDIR}/lazybox.dynamic | grep -v ^# | grep -v for | cut -d ' ' -f 2-20 | paste -d " " - - - - - - - - - - - - - - - - - - - - -) 
do
	echo ${i}
done | sort | uniq >>${BOOTDIR}${BOOTPREFIX}/cmdlist


echo " * share = Creating trackfile"
# The trackfile serves two purposes. To make the system verifyable, and to allow us to safely tftp install. Yay!

# This is the location of the trackfile.
export TRACKFILE=${BOOTDIR}${BOOTPREFIX}/trackfile
export TRACKFILE_PRIVATE_KEY="${EVOKE_BUILDER_PRIVATE}"

cd ${BOOTDIR}${BOOTPREFIX}
TRACKFILE_AUTHORITY="${EVOKE_BUILDER_USER_UUID}" TRACKFILE_USER="${EVOKE_BUILDER_AUTHORITY_UUID}" OPTIONS="write quiet" verify *



echo " * share = Creating RELEASEDIR"

# grab a list of already installed versions for create-updates.
VERSIONLIST="$(cd ${RELEASEDIR}/evoke && find . -not -path "./misc*" -depth 2 | cut -b 3-300 | sort -r | head -n 7 | paste - - - - - - -)"

mkdir -p ${RELEASEDIR}${BOOTPREFIX}
cd ${BOOTDIR}${BOOTPREFIX}
tar -cf - * | tar -xf - -C ${RELEASEDIR}${BOOTPREFIX}/
echo ""

echo " * share = Generating Binary Diffs"
update create "${VERSION}/${REVISION}" "${BOOTDIR}${BOOTPREFIX}" ${VERSIONLIST} 1>&2
#cd "${RELEASEDIR}" && tar -cf - "evoke/misc/BIN-UPDATES/${VERSION}/${REVISION}" | tar -xvpf - -C "${BOOTDIR}/"
echo ""

echo " * share = Making ISO image"

# Don't ask; cdboot is the main reason why bootloader versioning was turned off for so damned long.

mkdir -p ${BOOTDIR}/cdboot
cp ${BOOTDIR}${BOOTPREFIX}/FreeBSD/$(echo ${i386_ACTIVE} | cut -d "-" -f 1)/$(echo ${i386_ACTIVE} | cut -d "/" -f 2)/cdboot ${BOOTDIR}/cdboot/i386
mkdir -p ${BOOTDIR}/evoke/misc
echo "${VERSION}/${REVISION}" >${BOOTDIR}/evoke/misc/versionlist

mkdir -p ${RELEASEDIR}/evoke/misc/ISO-IMAGES/${VERSION}/${REVISION}

if [ -d "${BOOTOVERLAY}" ] ; then
	cd ${BOOTOVERLAY}
	tar -cf - --exclude ".." --exclude "." * .* | tar -xf - -C ${BOOTDIR}/
fi

cd ${RELEASEDIR}/evoke/misc/ISO-IMAGES/${VERSION}/${REVISION}

# DO NOT TOUCH UNDER PENALTY OF DEATH.
mkisofs -b cdboot/i386 -no-emul-boot -r -J -V EVOKE-${VERSION}-${REVISION} -p "${ENGINEER}" -publisher "http://evoke.googlecode.com" -o evoke.iso ${BOOTDIR} 1>&2

ISO_SHA256="$(sha256 *)"
ISO_MD5="$(md5 *)"

echo "${ISO_SHA256}" >>CHECKSUM.SHA256
echo "${ISO_MD5}" >>CHECKSUM.MD5

mkdir -p ${RELEASEDIR}/evoke/misc
(cat "${RELEASEDIR}/evoke/misc/versionlist" ; echo "${VERSION}/${REVISION}") | sort -r | uniq >"${TMPDIR}/mirrortest"
mv "${TMPDIR}/mirrortest" "${RELEASEDIR}/evoke/misc/versionlist"
rm ${RELEASEDIR}/evoke/${VERSION}/HEAD
ln -sf ${REVISION} ${RELEASEDIR}/evoke/${VERSION}/HEAD

if [ "${EVOKE_PUSH_MIRROR}" != "" ] ; then
	cd ${RELEASEDIR}/evoke

	MOUNTPOINT="${TMPDIR}/$(dd if=/dev/random bs=1m count=4 | sha256 -q)"

	mkdir -p "${MOUNTPOINT}"

	for volume in $(mounter search "tag=${EVOKE_PUSH_MIRROR}")
	do
		mounter "${volume}" "${MOUNTPOINT}"
		mkdir -p "${MOUNTPOINT}/evoke/misc"
		tar -cf - "${VERSION}/${REVISION}" "misc/ISO-IMAGES/${VERSION}/${REVISION}" "misc/BIN-UPDATES/${VERSION}/${REVISION}" | tar -xvf - -C "${MOUNTPOINT}/evoke/"
		( cat "${MOUNTPOINT}/evoke/misc/versionlist" ; echo "${VERSION}/${REVISION}") | sort -r | uniq >"${TMPDIR}/mirrortest"
		mv "${TMPDIR}/mirrortest" "${MOUNTPOINT}/evoke/misc/versionlist"

		rm ${MOUNTPOINT}/evoke/${VERSION}/HEAD
		ln -sf ${REVISION} ${MOUNTPOINT}/evoke/${VERSION}/HEAD
		mounter umount "${MOUNTPOINT}"
	done
fi

