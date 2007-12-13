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
	export WRKDIRPREFIX=$(pwd)
fi

TARGETS="6.3-RC1/i386 6.3-RC1/amd64 6.3-RC1/powerpc 7.0-BETA4/amd64"
ARCHS="i386 powerpc amd64"
VERSION="6.3-RC1"

# Choose dist source

echo "Please insert a FreeBSD ${VERSION} CD, and specify the device node. (ex. cd0)"
echo " -- OR --"
echo "Enter the path of the release files (/home/user/blah)" 


until [ "${DONE}" = "done" ]
do
	if [ -f "${WRKDIRPREFIX}/${VERSION}-i386-disc1.iso" ] ; then
		echo "insert mount iso"
	fi
	read -p "[acd0] > " NODE
	case "${NODE}" in
		?cd*)

		;;
		*)
			if [ -d "${NODE}/${VERSION}" ] ; then
				export FBSD_DISTDIR="${NODE}/${VERSION}"
				DONE=done
			fi
		;;
	esac
done


for TARGET in ${ARCHS}
do
	export DESTDIR=${WRKDIRPREFIX}/${TARGET}
	chflags -R noschg ${DESTDIR}
	if [ -d "${DESTDIR}" ] ; then
			rm -rf ${DESTDIR}
	fi
	mkdir -p ${DESTDIR}
	SRCDIR="${FBSD_DISTDIR}" DISTS="base kernels src" ${WRKDIRPREFIX}/share/bin/distextract
	ERROR="$?"
	if [ "${ERROR}" != "0" ] ; then
		echo "Error code: ${ERROR}"
		exit 1
	fi
done

export ERRFILE=${WRKDIRPREFIX}/error.log
export BOOTDIR=${WRKDIRPREFIX}/bdir
export FSDIR=${WRKDIRPREFIX}/fsdir
rm -r ${BOOTDIR}
rm -r ${FSDIR}

for TARGET in ${ARCHS}
do
	export WORKDIR=${WRKDIRPREFIX}/${TARGET}
	export TARGET
	export TARGET_ARCH="${TARGET}"
	export MAKEOBJDIRPREFIX=/tmp/${TARGET}

	echo -n " * Cleaning up object files ....."
	if [ "${NO_CLEAN}" = "" ] ; then
		rm -rf /tmp/${TARGET} 2>${ERRFILE}
	fi
	echo " [DONE]"

	echo -n " * Patching World ....."
	cd ${WORKDIR}/usr/src/sys/boot/
	export BOOTPATH="/boot/"
#	for file in $(find ./ -not -type d -not -name .bak)
#	do
#	    sed -i .bak "s_\"/boot/kernel_\"${BOOTPATH}/GENERIC_g" ${file} 2>>${ERRFILE} >>${ERRFILE}
#	    sed -i .bak "s_\"/boot/loader_\"${BOOTPATH}/loader_g" ${file} 2>>${ERRFILE} >>${ERRFILE}
#	    sed -i .bak "s_\"/BOOT/LOADER_\"/.BOOT/0.1R2/I386/LOADER_g" ${file} 2>>${ERRFILE} >>${ERRFILE}
#	done
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 2>>${ERRFILE} >>${ERRFILE}
	sed -i .bak "s_\"/rescue_\"/.FreeBSD-6/${TARGET}/bin_g" ${WORKDIR}/usr/src/include/paths.h 2>>${ERRFILE} >>${ERRFILE}
	sed -i .bak "s_\"/etc/rc_\"/share/bin/systart_g" ${WORKDIR}/usr/src/sbin/init/pathnames.h 2>>${ERRFILE} >>${ERRFILE}
	cp ${WRKDIRPREFIX}/lazybox.Makefile ${WORKDIR}/usr/src/rescue/rescue/Makefile
	echo " [DONE]"


	echo -n " * Building World ....."
	cd ${WORKDIR}/usr/src/
	if [ "${NO_CLEAN}" = "" ] ; then
		make  -DLOADER_TFTP_SUPPORT buildworld 2>>${ERRFILE} >>${ERRFILE}
	fi
	echo " [DONE]"

	echo -n " * Populating DESTDIR=${DESTDIR} ....."
	export DESTDIR=${WRKDIRPREFIX}/${TARGET}
	mkdir -p ${DESTDIR}
	priv make hierarchy 2>>${ERRFILE} >>${ERRFILE}
	rm -r ${DESTDIR}/rescue
	mkdir -p ${DESTDIR}/rescue
	priv make installworld 2>>${ERRFILE} >>${ERRFILE}
#	priv make distribution 2>>${ERRFILE} >>${ERRFILE}
	mkdir -p ${DESTDIR}/usr/src
#	priv mount_nullfs ${WORKDIR}/usr/src/ ${DESTDIR}/usr/src/ 2>>${ERRFILE} >>${ERRFILE}
	echo " [DONE]"

	echo -n " * Compressing Kernel ....."
	for i in GENERIC
	do
		cd ${DESTDIR}/boot/${i}/
		rm -r *.gz 2>/dev/null
		rm g_md.ko
		gzip -9 kernel acpi.ko dcons.ko dcons_crom.ko nullfs.ko
		rm -r *.ko
	done

	echo " [DONE]"

	echo -n " * Populating BOOTPATH=${BOOTPATH} ....."
	mkdir -p ${BOOTDIR}/${BOOTPATH} 2>>${ERRFILE} >>${ERRFILE}
	cd ${DESTDIR}/boot/
	tar -cf - --exclude SMP --exclude loader.old * | tar -xvf - -C ${BOOTDIR}/${BOOTPATH} 2>>${ERRFILE} >>${ERRFILE}
	cat >${BOOTDIR}/${BOOTPATH}/loader.conf << EOF
kernel="GENERIC"
mfsroot_load="YES"
mfsroot_type="mfs_root"
mfsroot_name="${BOOTPATH}/root.fs"
dcons_load="YES"
dcons_crom_load="YES"
geom_label_load="YES"
nullfs_load="YES"
init_path="/.FreeBSD-6/i386/bin/init"
vfs.root.mountfrom="ufs:md0"
EOF
	echo " [DONE]"

	echo -n " * Populating FSDIR (.FreeBSD-6/${TARGET}) ....."
	mkdir -p ${FSDIR}/.FreeBSD-6/${TARGET}/bin 2>>${ERRFILE} >>${ERRFILE}
	cd ${WORKDIR}/rescue
	tar -cf - * | tar -xf - -C ${FSDIR}/.FreeBSD-6/${TARGET}/bin/ 2>>${ERRFILE} >>${ERRFILE}
	mkdir -p ${FSDIR}/share/lib
	mkdir -p ${FSDIR}/usr/share/misc
	cp ${WORKDIR}/usr/share/misc/termcap ${FSDIR}/share/lib/termcap
	cp ${WORKDIR}/etc/login.conf ${FSDIR}/share/lib/login.conf
	ln -s /share/lib/termcap ${FSDIR}/usr/share/misc/
	echo " [DONE]"
done

echo -n " * Populating FSDIR (shared) ....."
mkdir -p ${FSDIR}/dev
mkdir -p ${FSDIR}/bin
mkdir -p ${FSDIR}/tmp
mkdir -p ${FSDIR}/etc
ln -s /tmp  ${FSDIR}/var
ln -s /bin ${FSDIR}/sbin
cd ${WRKDIRPREFIX}
tar -cf - share | tar -xf - -C ${FSDIR}/
echo " [DONE]"


echo -n " * Creating root.fs ....."
cd ${BOOTDIR}/${BOOTPATH}
rm -r root.fs* 2>>${ERRFILE} >>${ERRFILE}
makefs root.fs ${FSDIR} 2>>${ERRFILE} >>${ERRFILE}
MDDEVICE=$(priv mdconfig -af root.fs)
FINGERPRINT=$(sha256 -q /dev/${MDDEVICE})
echo "dsbsd.fingerprint=\"${FINGERPRINT}\"" >>${BOOTDIR}/${BOOTPATH}/loader.conf
priv mdconfig -d -u $(echo ${MDDEVICE} | cut -c 3-100)
gzip -9 root.fs	2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"

echo -n " * Making ISO image ....."
cd ${WRKDIRPREFIX}
mkisofs -b boot/cdboot -no-emul-boot -r -J -V DamnSmallBSD-HEAD -publisher "www.damnsmallbsd.org" -o dsbsd.iso ${BOOTDIR} 2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"


