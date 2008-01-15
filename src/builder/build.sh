#!/bin/sh
# $Id$

priv () {
	if [ "${USE_SUDO}" = "YES" ] ; then
		sudo $*
	else
		$*
	fi
}


export TRACKFILE=${OBJDIR}/trackfile
export BOOTDIR=${OBJDIR}/bdir
export FSDIR=${OBJDIR}/fsdir

for target in ${TARGETS}
do
	export DESTDIR=${OBJDIR}/${target}
	export WORKDIR=${DESTDIR}
	mkdir -p ${WORKDIR}
	SRCDIR="${NDISTDIR}/$(echo ${target} | cut -d "/" -f 1)" DISTS="src" ${ROOTDIR}/share/bin/distextract 1>&2
	ERROR="$?"
	if [ "${ERROR}" != "0" ] ; then
		echo "Error code: ${ERROR}"
		exit 1
	fi
	export TARGET=$(echo ${target} | cut -d "/" -f 2)
	export TARGET_ARCH="${TARGET}"
	export NDIR=/.FreeBSD-$(echo ${target} | cut -d "/" -f 1 | cut -d "." -f 1)/${TARGET}/
	export NBINDIR=${NDIR}/bin
	export CROSS_BUILD_TESTING=yes

	echo -n " * ${target} = Patching World"
	cd ${WORKDIR}/usr/src/sys/boot/
#	export BOOTPATH="/dsbsd/${VERSION}/${target}"
	export BOOTPATH="/boot"
#	for file in $(cat ${ROOTDIR}/bootlist)
#	do
#	    sed -i .bak "s_/boot_${BOOTPATH}_g" ${WORKDIR}${file} 1>&2
#	    sed -i .bak "s_/BOOT_$(echo ${BOOTPATH} | tr a-z A-Z)_g" ${WORKDIR}${file} 1>&2
#	done
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 1>&2
	sed -i .bak "s_\"/rescue_\"${NBINDIR}_g" ${WORKDIR}/usr/src/include/paths.h 1>&2
	sed -i .bak "s_\"/etc/rc_\"/share/bin/systart_g" ${WORKDIR}/usr/src/sbin/init/pathnames.h 1>&2
	echo "				[DONE]"

	export DESTDIR=${OBJDIR}/${target}
	mkdir -p ${DESTDIR}
	mkdir -p ${FSDIR}${NBINDIR} 1>&2
	mkdir -p ${FSDIR}${NDIR}/lib 1>&2
	mkdir -p ${FSDIR}${NDIR}/libexec 1>&2
	mkdir -p ${FSDIR}${NDIR}/boot	1>&2

	export MAKEOBJDIRPREFIX=${TMPDIR}/${target}

	echo -n " * ${target} = Cleaning up"
	if [ "${NO_CLEAN}" = "" ] ; then
		rm -rf ${MAKEOBJDIRPREFIX} 
	fi
	echo "					[DONE]"
	cd ${BUILDDIR}
	tar -cf - nsrc | tar -xf - -C ${DESTDIR}/usr/src/

	case "${1}" in
		[sS][tT][aA][tT][iI][cC])
			. ${BUILDDIR}/static.sh
		;;
		[dD][yY][nN][aA][mM][iI][cC])
			. ${BUILDDIR}/dynamic.sh
		;;
		*)
			. ${BUILDDIR}/dynamic.sh
		;;
	esac
	cp ${DESTDIR}/boot/boot ${DESTDIR}/boot/mbr ${FSDIR}${NDIR}/boot/

	echo -n " * ${target} = Compressing Kernel"
	SRCDIR="${NDISTDIR}/${target}" DISTS="kernels" ${ROOTDIR}/share/bin/distextract 1>&2
	for i in GENERIC
	do
		cd ${DESTDIR}/boot/${i}/
		for file in $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2)
		do
			cp ${DESTDIR}/usr/local/modules/${file}.ko ./
		done
		gzip -9 kernel
		for file in $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2) ${MODULES}
		do
			gzip -9 ${file}.ko
		done
		rm -r *.symbols
		rm -r *.ko
		gunzip *.gz
	done
	echo "				[DONE]"

	echo -n " * ${target} = Populating BOOTPATH"
	mkdir -p ${BOOTDIR}${BOOTPATH}/defaults 1>&2
	rm -r ${DESTDIR}/boot/SMP
	cd ${DESTDIR}/boot && tar -cf - --exclude loader.old * | tar -xvf - -C ${BOOTDIR}${BOOTPATH} 1>&2
	cat >>${BOOTDIR}${BOOTPATH}/loader.conf << EOF
init_path="${NBINDIR}/init"
EOF

	echo "				[DONE]"

done

BOOTPATH=/boot
echo -n " * share = Populating FSDIR"
mkdir -p ${FSDIR}/usr/share/misc
ln -s /share/lib/termcap ${FSDIR}/usr/share/misc/
ln -s /lib ${FSDIR}/usr/lib
mkdir -p ${FSDIR}/cfg
mkdir -p ${FSDIR}/tmp
mkdir -p ${FSDIR}/home/root
mkdir -p ${FSDIR}/dev

mkdir -p ${FSDIR}/bin

mkdir -p ${FSDIR}/lib
mkdir -p ${FSDIR}/libexec
mkdir -p ${FSDIR}/boot
ln -s /cfg  ${FSDIR}/etc
ln -s /tmp  ${FSDIR}/var
ln -s /bin ${FSDIR}/sbin
cd ${ROOTDIR}

for dir in $(find share/ -not -path \*.svn\* -type d)
do
	mkdir -p ${FSDIR}/${dir}
done

for file in $(find share/ -not -path \*.svn\* -not -type d)
do
	grep '#!' ${file} | head -1 >${FSDIR}/${file}
	grep '$Id' ${file} | head -1 >>${FSDIR}/${file}
	grep -v '^#' ${file} | grep -v '[[:space:]]#' >>${FSDIR}/${file}
done

echo "					[DONE]"


echo -n " * share = Creating root.fs"
cd ${BOOTDIR}${BOOTPATH}
makefs root.fs ${FSDIR} 1>&2
MDDEVICE=$(priv mdconfig -af root.fs)
FINGERPRINT=$(sha256 -q /dev/${MDDEVICE})

for module in ${MODULES} $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2)
do
	echo "${module}_load=\"YES\"" >>${BOOTDIR}${BOOTPATH}/loader.conf
done
cat >>${BOOTDIR}${BOOTPATH}/loader.conf << EOF
kernel="GENERIC"
mfsroot_load="YES"
mfsroot_type="mfs_root"
mfsroot_name="${BOOTPATH}/root.fs"
trackfile_load="YES"
trackfile_type="mfs_root"
trackfile_name="${BOOTPATH}/trackfile"
dsbsd.fingerprint="${FINGERPRINT}" 
vfs.root.mountfrom="ufs:md0"
boot_multicons="YES"
hw.firewire.dcons_crom.force_console=1


EOF
priv mdconfig -d -u $(echo ${MDDEVICE} | cut -c 3-100)
gzip -9 root.fs	1>&2
echo "					[DONE]"

echo -n " * share = Making cmdlist and modlist image"
mkdir -p ${OBJDIR}/release
for i in ${MODULES} $(grep ^M ${BUILDDIR}/portlist | cut -d : -f 2 | sort | uniq)
do
	echo ${i} >>${OBJDIR}/release/modlist
done

for i in ${PROGS} $(grep ^B ${BUILDDIR}/portlist | cut -d : -f 2 | sort | uniq) $(grep CRUNCH_LINKS ${BUILDDIR}/lazybox.dynamic | grep -v ^# | grep -v for | cut -d ' ' -f 2-20 | paste -d " " - - - - - - - - - - - - - - - - - - - - - ) $(grep CRUNCH_PROGS ${BUILDDIR}/lazybox.dynamic | grep -v ^# | grep -v for | cut -d ' ' -f 2-20 | paste -d " " - - - - - - - - - - - - - - - - - - - - - ) 
do
	echo ${i} >>${OBJDIR}/release/cmdlist
done

echo "					[DONE]"

echo -n " * share = Creating trackfile"
cd ${BOOTDIR}
for file in $( find ./ -not -type d | cut -b 3-200)
do
	echo "F:${BOOTPATH}/${file}:$(sha256 -q ${file})" >>${TRACKFILE}
done
echo -n "# " >>${TRACKFILE}
dd if=${TRACKFILE} bs=512 fillchar=" " conv=sync of=/tmp/trackfile.head 
dd if=/dev/zero bs=512 count=1 of=/tmp/trackfile.tail
cat /tmp/trackfile.head /tmp/trackfile.tail >${BOOTDIR}${BOOTPATH}/trackfile
DEVICE=$(mdconfig -af ${BOOTDIR}${BOOTPATH}/trackfile)
geom label load
geom label label trackfile /dev/${DEVICE}
mdconfig -d -u $(echo ${DEVICE} | cut -b 3-7)
cp ${BOOTDIR}${BOOTPATH}/trackfile ${OBJDIR}/release/

echo "					[DONE]"

echo -n " * share = Making ISO image"
cd ${OBJDIR}/release
mkisofs -b boot/cdboot -no-emul-boot -r -J -V DSBSD-${VERSION} -p "${ENGINEER}" -publisher "http://www.damnsmallbsd.org" -o dsbsd.iso ${BOOTDIR} 1>&2
echo "					[DONE]"

