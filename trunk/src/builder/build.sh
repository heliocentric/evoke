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


# This is the location of the trackfile.
export TRACKFILE=${OBJDIR}/trackfile

# BOOTDIR is the 'boot' directory; it's the root of the cd image
export BOOTDIR=${OBJDIR}/bdir

# FSDIR is the root of the root.fs image
export FSDIR=${OBJDIR}/fsdir

if [ "${VERSION}" = "HEAD" ] ; then
	if [ "${REVISION}" != "" ] ; then
		export VERSION=r${REVISION}
	fi
fi
# The prefix for this version, for BOOTDIR, so we can avoid collisions with FreeBSD.
export BOOTPREFIX=/dsbsd/${VERSION}

# PRODUCTDIR is where the filesystem images are stored.
export PRODUCTDIR=/dsbsd/${VERSION}/product

for target in ${TARGETS}
do
	# The TARGET and TARGET_ARCH are used by buildworld, and also internally
	# except for PC98, they are the same.
	export TARGET=$(echo ${target} | cut -d "/" -f 2)
	export TARGET_ARCH="${TARGET}"

	# Release (eg, 6.3-RELEASE)
	export RELEASE=$(echo ${target} | cut -d "/" -f 1)

	# Kernel ABI (eg, 7 for 7.0-RELEASE or 7.1-RELEASE)
	export ABI=$(echo ${target} | cut -d "/" -f 1 | cut -d "." -f 1)

	# Kernel config definition; since boot loader versioning works now,
	# no need to use anything other then kernel
	export KERNCONF="kernel"

	# for installkernel/installworld and places in the script
	# that need to know where installworld is putting things
	export DESTDIR=${OBJDIR}/${target}
	mkdir -p ${DESTDIR}

	# erm, why is this here? might be removable, older version probably treated 
	# them seperately.
	export WORKDIR=${DESTDIR}
	mkdir -p ${WORKDIR}

	# N_ prefix variables are for the file copies from DESTDIR to FSDIR, the 
	# targets are arch and abi specific.
	export N_DIR=/system/FreeBSD-${ABI}/${TARGET}
	export N_SHAREBIN=/system/share/bin
	export N_SHARELIB=/system/share/lib
	export N_BIN=${N_DIR}/bin
	export N_LIB=${N_DIR}/lib
	export N_LIBEXEC=${N_DIR}/libexec
	export N_BOOT=${N_DIR}/boot

	mkdir -p ${FSDIR}${N_BIN} 1>&2
	mkdir -p ${FSDIR}${N_LIB} 1>&2
	mkdir -p ${FSDIR}${N_LIBEXEC} 1>&2
	mkdir -p ${FSDIR}${N_BOOT} 1>&2

	# This forces same architecture buildworld/buildkernels to build cross-tools
	# and build-tools adequately.
	# ...
	#
	# DO NOT REMOVE UNDER PENALTY OF DEATH.
	export CROSS_BUILD_TESTING=yes

	# Extract source distfiles into ${DESTDIR}
	SRCDIR="${NDISTDIR}/${RELEASE}" DISTS="src" ${ROOTDIR}/share/bin/distextract 1>&2
	ERROR="$?"
	if [ "${ERROR}" != "0" ] ; then
		# Wooo, real error message now.
		echo "Source dist extraction failed."
		echo "Error code: ${ERROR}"
		exit 1
	fi

	echo -n " * ${target} = Patching World"

	# Ok, we need to patch around some hard coded paths in src/
	cd ${WORKDIR}/usr/src/sys/boot/

	# This changes per ${target}
	export BOOTPATH="${BOOTPREFIX}/freebsd${ABI}/${TARGET}"
	mkdir -p ${BOOTDIR}${BOOTPATH}

	# Patch these files to our paths, so they don't collide.
	sed -i .bak "s@/boot/device.hints@${BOOTPATH}/device.hints@g" ${WORKDIR}/usr/src/sys/boot/forth/loader.conf 1>&2
	sed -i .bak "s@/boot/loader.conf@${BOOTPREFIX}/loader.conf@g" ${WORKDIR}/usr/src/sys/boot/forth/loader.conf 1>&2
	sed -i .bak "s@/boot/loader.conf.local@${BOOTPREFIX}/loader.conf.local@g" ${WORKDIR}/usr/src/sys/boot/forth/loader.conf 1>&2

	for file in $(cat ${ROOTDIR}/bootlist)
	do
	    # This works for most.
	    sed -i .bak "s@/boot@${BOOTPATH}@g" ${WORKDIR}${file} 1>&2
	    # This is for cdboot. Case specific
	    sed -i .bak "s@/BOOT@$(echo ${BOOTPATH} | tr a-z A-Z)@g" ${WORKDIR}${file} 1>&2
	done
	# Get rid of this latency addition in pxeboot (fixed in 7.0, but necessary on 6.x)
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 1>&2

	# rescue binaries hard code /rescue; for us, it's more productive to point it to the abi/arch 
	# directory directly. It makes systart transparent.
	sed -i .bak "s@\"/rescue@\"${N_BIN}@g" ${WORKDIR}/usr/src/include/paths.h 1>&2


	# we don't have a real /etc, so point init to systart.
	sed -i .bak "s_\"/etc/rc_\"${N_SHAREBIN}/systart_g" ${WORKDIR}/usr/src/sbin/init/pathnames.h 1>&2
	echo ""

	# We use TMPDIR so that it can be different then the OBJDIR, as TMPDIR is write heavy.
	export MAKEOBJDIRPREFIX=${TMPDIR}/${target}

	echo -n " * ${target} = Cleaning up"
	if [ "${NO_CLEAN}" = "" ] ; then
		rm -rf ${MAKEOBJDIRPREFIX} 
	fi
	echo ""


	# This copies nsrc to src/, to compile our own code. For some reason does not work, but non-critical.

	cd ${BUILDDIR}
	tar -cf - nsrc | tar -xf - -C ${DESTDIR}/usr/src/

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

	# let's make bsdlabel and fdisk have real bootcode.
	cp ${DESTDIR}${BOOTPATH}/boot ${DESTDIR}${BOOTPATH}/mbr ${FSDIR}${N_BOOT}

	echo -n " * ${target} = Compressing Kernel"
	cd ${DESTDIR}/boot/${KERNCONF}/

	# Grab port modules and copy them to the kernel directory.
	for file in $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2)
	do
		cp ${DESTDIR}/usr/local/modules/${file}.ko ./
	done

	gzip -9 kernel
	for file in $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2) ${MODULES}
	do
		gzip -9 ${file}.ko
	done
	# Remove everything that is not gzipped.
	rm -r *.symbols
	rm -r *.ko
	# Yes, this is all wasteful. But this bug will be fixed eventually, and when it does, this line can be removed.
	gunzip *.gz

	echo "				[DONE]"

	echo -n " * ${target} = Populating BOOTPATH"

	# Shouldn't tar be doing this?
	mkdir -p ${BOOTDIR}${BOOTPATH}/defaults 1>&2
	cd ${DESTDIR}/boot && tar -cf - --exclude loader.old * | tar -xvf - -C ${BOOTDIR}${BOOTPATH} 1>&2

	# Yes, we need it twice. Why? Because only certain things in the build system are boot versioned. So it's split across two directories.
	cd ${DESTDIR}${BOOTPATH} && tar -cf - --exclude loader.old * | tar -xvf - -C ${BOOTDIR}${BOOTPATH} 1>&2

	echo "				[DONE]"

done

echo -n " * share = Populating FSDIR"

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
ln -s /bin ${FSDIR}/sbin


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
	grep -v '^#' ${file} | grep -v '[[:space:]]#' >>${FSDIR}/system/${file}
	chmod a+rx ${FSDIR}/system/${file}
done

echo "					[DONE]"


echo -n " * share = Creating root.fs"
# Make dsbsd.fs, the main product filesystem.
mkdir -p ${BOOTDIR}${PRODUCTDIR}
cd ${BOOTDIR}${PRODUCTDIR}
makefs dsbsd.fs ${FSDIR} 1>&2
MDDEVICE=$(priv mdconfig -af dsbsd.fs)

# Trust me, this is necessary; sha256 the file returns a different hash then the device node
FINGERPRINT=$(sha256 -q /dev/${MDDEVICE})
priv mdconfig -d -u $(echo ${MDDEVICE} | cut -c 3-100)
gzip -9 dsbsd.fs	1>&2

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
mfsroot_name="${PRODUCTDIR}/dsbsd.fs"
trackfile_load="YES"
trackfile_type="mfs_root"
trackfile_name="${BOOTPREFIX}/trackfile"
dsbsd.fingerprint="${FINGERPRINT}" 
# boot_multicons="YES"
# hw.firewire.dcons_crom.force_console=1
kern.hz=100
EOF

echo "					[DONE]"

mkdir -p ${RELEASEDIR}${BOOTPREFIX}

echo -n " * share = Making cmdlist and modlist image"

# Easier to list it this way now.

for i in ${MODULES} $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2 | sort | uniq)
do
	echo ${i} >>${BOOTDIR}${BOOTPREFIX}/modlist
done

for i in ${PROGS} $(grep ^B ${BUILDDIR}/portlist | cut -d : -f 2) $(grep CRUNCH_LINKS ${BUILDDIR}/lazybox.dynamic | grep -v ^# | grep -v for | cut -d ' ' -f 2-20 | paste -d " " - - - - - - - - - - - - - - - - - - - - - ) $(grep CRUNCH_PROGS ${BUILDDIR}/lazybox.dynamic | grep -v ^# | grep -v for | cut -d ' ' -f 2-20 | paste -d " " - - - - - - - - - - - - - - - - - - - - -) 
do
	echo ${i}
done | sort | uniq >>${BOOTDIR}${BOOTPREFIX}/cmdlist

echo "					[DONE]"

echo -n " * share = Creating trackfile"
# The trackfile serves two purposes. To make the system verifyable, and to allow us to safely tftp install. Yay!
cd ${BOOTDIR}
for file in $( find ./ -not -type d | cut -b 3-200)
do
	echo "F:/${file}:$(sha256 -q ${file})" >>${TRACKFILE}
done
echo -n "# " >>${TRACKFILE}

# Why? We add a trailer to the trackfile, and create a label in it; this way it always comes up as /dev/label/trackfile, and the kernel can always find it.
dd if=${TRACKFILE} bs=512 fillchar=" " conv=sync of=/tmp/trackfile.head 
dd if=/dev/zero bs=512 count=1 of=/tmp/trackfile.tail
cat /tmp/trackfile.head /tmp/trackfile.tail >${BOOTDIR}${BOOTPREFIX}/trackfile
DEVICE=$(mdconfig -af ${BOOTDIR}${BOOTPREFIX}/trackfile)
geom label load
geom label label trackfile /dev/${DEVICE}
mdconfig -d -u $(echo ${DEVICE} | cut -b 3-7)
echo "					[DONE]"

echo -n " * share = Creating RELEASEDIR"
cd ${BOOTDIR}${BOOTPREFIX}
tar -cf - * | tar -xf - -C ${RELEASEDIR}${BOOTPREFIX}/
echo ""

echo -n " * share = Making ISO image"

# Don't ask; cdboot is the main reason why bootloader versioning was turned off for so damned long.

mkdir -p ${BOOTDIR}/cdboot
cp ${BOOTDIR}/dsbsd/${VERSION}/freebsd$(echo ${i386_ACTIVE} | cut -d "." -f 1)/$(echo ${i386_ACTIVE} | cut -d "/" -f 2)/cdboot ${BOOTDIR}/cdboot/i386
mkdir -p ${RELEASEDIR}/ISO-IMAGES/${VERSION}
cd ${RELEASEDIR}/ISO-IMAGES/${VERSION}

# DO NOT TOUCH UNDER PENALTY OF DEATH.
mkisofs -b cdboot/i386 -no-emul-boot -r -J -V DSBSD-${VERSION} -p "${ENGINEER}" -publisher "http://www.damnsmallbsd.org" -o dsbsd.iso ${BOOTDIR} 1>&2
echo "					[DONE]"

