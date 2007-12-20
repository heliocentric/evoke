#!/bin/sh
# $Id$

priv () {
	if [ "${USE_SUDO}" = "YES" ] ; then
		sudo $*
	else
		$*
	fi
}

if [ "${WRKDIRPREFIX}" = "" ] ; then
	export WRKDIRPREFIX=${OBJDIR}
fi

TARGETS="6.3-RC1/i386"
VERSION=0.1r1

export ERRFILE=${WRKDIRPREFIX}/error.log
export TRACKFILE=${WRKDIRPREFIX}/trackfile
export BOOTDIR=${WRKDIRPREFIX}/bdir
export FSDIR=${WRKDIRPREFIX}/fsdir

for target in ${TARGETS}
do
	echo "Starting build for ${target}"
	export DESTDIR=${WRKDIRPREFIX}/${target}
	mkdir -p ${DESTDIR}
	SRCDIR="${ROOTDIR}/dists/$(echo ${target} | cut -d "/" -f 1)" DISTS="src" ${ROOTDIR}/share/bin/distextract >>${ERRFILE} 2>>${ERRFILE}
	ERROR="$?"
	if [ "${ERROR}" != "0" ] ; then
		echo "Error code: ${ERROR}"
		exit 1
	fi
	export WORKDIR=${WRKDIRPREFIX}/${target}
	export TARGET=$(echo ${target} | cut -d "/" -f 2)
	export TARGET_ARCH="${TARGET}"
	export NDIR=/.FreeBSD-$(echo ${target} | cut -d "/" -f 1 | cut -d "." -f 1)/${TARGET}/
	export NBINDIR=${NDIR}/bin
	export CROSS_BUILD_TESTING=yes

	echo -n " * ${target} = Patching World ....."
	cd ${WORKDIR}/usr/src/sys/boot/
#	export BOOTPATH="/dsbsd/${VERSION}/${target}"
	export BOOTPATH="/boot"
#	for file in $(cat ${ROOTDIR}/bootlist)
#	do
#	    sed -i .bak "s_/boot_${BOOTPATH}_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#	    sed -i .bak "s_/BOOT_$(echo ${BOOTPATH} | tr a-z A-Z)_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#	done
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 2>>${ERRFILE} >>${ERRFILE}
	sed -i .bak "s_\"/rescue_\"${NBINDIR}_g" ${WORKDIR}/usr/src/include/paths.h 2>>${ERRFILE} >>${ERRFILE}
	sed -i .bak "s_\"/etc/rc_\"/share/bin/systart_g" ${WORKDIR}/usr/src/sbin/init/pathnames.h 2>>${ERRFILE} >>${ERRFILE}
	export DESTDIR=${WRKDIRPREFIX}/${target}
	mkdir -p ${DESTDIR}
	mkdir -p ${FSDIR}${NBINDIR} 2>>${ERRFILE} >>${ERRFILE}
	mkdir -p ${FSDIR}${NDIR}/lib 2>>${ERRFILE} >>${ERRFILE}
	mkdir -p ${FSDIR}${NDIR}/libexec 2>>${ERRFILE} >>${ERRFILE}

	export MAKEOBJDIRPREFIX=/tmp/dyn${target}

	echo -n " * ${target} = Cleaning up object files ....."
	if [ "${NO_CLEAN}" = "" ] ; then
		rm -rf ${MAKEOBJDIRPREFIX} 2>>${ERRFILE}
	fi
	echo " [DONE]"

	case "${1}" in
		[dD][yY][nN][aA][mM][iI][cC])
			. ${BUILDDIR}/dynamic.sh
		;;
		*)
			. ${BUILDDIR}/static.sh
		;;
	esac

	echo -n " * ${target} = Compressing Kernel ....."
	SRCDIR="${ROOTDIR}/dists/${target}" DISTS="kernels" ${ROOTDIR}/share/bin/distextract >/dev/null
	for i in GENERIC
	do
		cd ${DESTDIR}/boot/${i}/
		rm -r *.gz 2>/dev/null
		rm -r *.symbols 2>/dev/null
		rm g_md.ko
		gzip -9 kernel acpi.ko dcons.ko dcons_crom.ko nullfs.ko geom_label.ko geom_mirror.ko geom_concat.ko geom_eli.ko geom_nop.ko geom_raid3.ko geom_shsec.ko geom_stripe.ko 2>>${ERRFILE}
		rm -r *.ko
	done
	echo " [DONE]"

	echo -n " * ${target} = Populating BOOTPATH ....."
	mkdir -p ${BOOTDIR}${BOOTPATH}/defaults 2>>${ERRFILE} >>${ERRFILE}
	cd ${DESTDIR}/boot && tar -cf - --exclude SMP --exclude loader.old * | tar -xvf - -C ${BOOTDIR}${BOOTPATH} 2>>${ERRFILE} >>${ERRFILE}
	cat >>${BOOTDIR}${BOOTPATH}/loader.conf << EOF
init_path="${NBINDIR}/init"
EOF

	echo " [DONE]"

done

BOOTPATH=/boot
echo -n " * share = Populating FSDIR ....."
mkdir -p ${FSDIR}/share/lib
mkdir -p ${FSDIR}/usr/share/misc
cp ${WORKDIR}/usr/share/misc/termcap ${FSDIR}/share/lib/termcap
cp ${WORKDIR}/etc/login.conf ${FSDIR}/share/lib/login.conf
ln -s /share/lib/termcap ${FSDIR}/usr/share/misc/
mkdir -p ${FSDIR}/dev
mkdir -p ${FSDIR}/bin
mkdir -p ${FSDIR}/lib
mkdir -p ${FSDIR}/libexec
mkdir -p ${FSDIR}/cfg
mkdir -p ${FSDIR}/tmp
ln -s /cfg  ${FSDIR}/etc
ln -s /tmp  ${FSDIR}/var
ln -s /bin ${FSDIR}/sbin
cd ${WRKDIRPREFIX}
for i in $(find ${FSDIR} -name ".svn")
do
	rm -r ${i}
done
cd ${ROOTDIR}
tar -cf - share | tar -xf - -C ${FSDIR}/
echo " [DONE]"


echo -n " * share = Creating root.fs ....."
cd ${BOOTDIR}${BOOTPATH}
rm -r root.fs* 2>>${ERRFILE} >>${ERRFILE}
makefs root.fs ${FSDIR} 2>>${ERRFILE} >>${ERRFILE}
MDDEVICE=$(priv mdconfig -af root.fs)
FINGERPRINT=$(sha256 -q /dev/${MDDEVICE})
cat >>${BOOTDIR}${BOOTPATH}/loader.conf << EOF
kernel="GENERIC"
mfsroot_load="YES"
mfsroot_type="mfs_root"
mfsroot_name="${BOOTPATH}/root.fs"
trackfile_load="YES"
trackfile_type="mfs_root"
trackfile_name="${BOOTPATH}/trackfile"
dcons_load="YES"
dcons_crom_load="YES"
geom_label_load="YES"
geom_mirror_load="YES"
#geom_concat_load="YES"
#geom_eli_load="YES"
#geom_nop_load="YES"
#geom_raid3_load="YES"
#geom_stripe_load="YES"
#geom_shsec_load="YES"
nullfs_load="YES"
dsbsd.fingerprint="${FINGERPRINT}" 
vfs.root.mountfrom="ufs:md0"
EOF

priv mdconfig -d -u $(echo ${MDDEVICE} | cut -c 3-100)
gzip -9 root.fs	2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"

echo -n " * share = Creating trackfile ....."
cd ${BOOTDIR}
for file in $( find ./ -not -type d | cut -b 3-200)
do
	echo "F:${BOOTPATH}/${file}:$(sha256 -q ${file})" >>${TRACKFILE}
done
echo -n "# " >>${TRACKFILE}
dd if=${TRACKFILE} bs=512 fillchar=" " conv=sync of=/tmp/trackfile.head 2>/dev/null
dd if=/dev/zero bs=512 count=1 of=/tmp/trackfile.tail 2>/dev/null
cat /tmp/trackfile.head /tmp/trackfile.tail >${BOOTDIR}${BOOTPATH}/trackfile
DEVICE=$(mdconfig -af ${BOOTDIR}${BOOTPATH}/trackfile)
geom label load
geom label label trackfile /dev/${DEVICE}
mdconfig -d -u $(echo ${DEVICE} | cut -b 3-7)
echo " [DONE]"

echo -n " * share = Making ISO image ....."
cd ${WRKDIRPREFIX}
mkisofs -b boot/cdboot -no-emul-boot -r -J -V DamnSmallBSD-HEAD -publisher "www.damnsmallbsd.org" -o dsbsd.iso ${BOOTDIR} 2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"
