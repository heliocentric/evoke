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

TARGETS="6.3-RC1/i386"
VERSION=0.1r1

export ERRFILE=${WRKDIRPREFIX}/error.log
export BOOTDIR=${WRKDIRPREFIX}/bdir
export FSDIR=${WRKDIRPREFIX}/fsdir
chflags -R noschg ${FSDIR}
chflags -R noschg ${BOOTDIR}
rm -r ${BOOTDIR}
rm -r ${FSDIR}

echo "" >${ERRFILE}
for target in ${TARGETS}
do
	echo "Starting build for ${target}"
	export DESTDIR=${WRKDIRPREFIX}/${target}
	chflags -R noschg ${DESTDIR}
	if [ -d "${DESTDIR}" ] ; then
			rm -rf ${DESTDIR}
	fi
	mkdir -p ${DESTDIR}
	SRCDIR="${WRKDIRPREFIX}/dists/$(echo ${target} | cut -d "/" -f 1)" DISTS="src" ${WRKDIRPREFIX}/share/bin/distextract >>${ERRFILE} 2>>${ERRFILE}
	ERROR="$?"
	if [ "${ERROR}" != "0" ] ; then
		echo "Error code: ${ERROR}"
		exit 1
	fi
	export WORKDIR=${WRKDIRPREFIX}/${target}
	export TARGET=$(echo ${target} | cut -d "/" -f 2)
	export TARGET_ARCH="${TARGET}"
	export MAKEOBJDIRPREFIX=/tmp/${target}
	export NBINDIR=/.FreeBSD-$(echo ${target} | cut -d "/" -f 1 | cut -d "." -f 1)/${TARGET}/bin

	echo -n " * ${target} = Cleaning up object files ....."
	if [ "${NO_CLEAN}" = "" ] ; then
		rm -rf ${MAKEOBJDIRPREFIX} 2>>${ERRFILE}
	fi
	echo " [DONE]"

	echo -n " * ${target} = Patching World ....."
	cd ${WORKDIR}/usr/src/sys/boot/
#	export BOOTPATH="/dsbsd/${VERSION}/${target}"
	export BOOTPATH="/boot"
#	for file in $(cat ${WRKDIRPREFIX}/bootlist)
#	do
#	    sed -i .bak "s_/boot_${BOOTPATH}_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#	    sed -i .bak "s_/BOOT_$(echo ${BOOTPATH} | tr a-z A-Z)_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#	done
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 2>>${ERRFILE} >>${ERRFILE}
	sed -i .bak "s_\"/rescue_\"${NBINDIR}_g" ${WORKDIR}/usr/src/include/paths.h 2>>${ERRFILE} >>${ERRFILE}
	sed -i .bak "s_\"/etc/rc_\"/share/bin/systart_g" ${WORKDIR}/usr/src/sbin/init/pathnames.h 2>>${ERRFILE} >>${ERRFILE}
	cp ${WRKDIRPREFIX}/lazybox.Makefile ${WORKDIR}/usr/src/rescue/rescue/Makefile
	echo " [DONE]"

	echo -n " * ${target} = Building World ....."
	cd ${WORKDIR}/usr/src/
	if [ "${NO_CLEAN}" = "" ] ; then
		make  -DLOADER_TFTP_SUPPORT buildworld 2>>${ERRFILE} >>${ERRFILE}
	fi
	echo " [DONE]"

	echo -n " * ${target} = Populating DESTDIR=${DESTDIR} ....."
	export DESTDIR=${WRKDIRPREFIX}/${target}
	mkdir -p ${DESTDIR}
	priv make hierarchy 2>>${ERRFILE} >>${ERRFILE}
	rm -r ${DESTDIR}/rescue
	mkdir -p ${DESTDIR}/rescue
	mkdir -p ${DESTDIR}${BOOTPATH}/defaults
	priv make installworld 2>>${ERRFILE} >>${ERRFILE}
	priv make distribution 2>>${ERRFILE} >>${ERRFILE}
	echo " [DONE]"

	echo -n " * ${target} = Compressing Kernel ....."
	SRCDIR="${WRKDIRPREFIX}/dists/${target}" DISTS="kernels" ${WRKDIRPREFIX}/share/bin/distextract >/dev/null
	for i in GENERIC
	do
		cd ${DESTDIR}/boot/${i}/
		rm -r *.gz 2>/dev/null
		rm -r *.symbols 2>/dev/null
		rm g_md.ko
		gzip -9 kernel acpi.ko dcons.ko dcons_crom.ko nullfs.ko 2>>${ERRFILE}
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

	echo -n " * ${target} = Populating FSDIR ....."
	mkdir -p ${FSDIR}${NBINDIR} 2>>${ERRFILE} >>${ERRFILE}
	cd ${WORKDIR}/rescue && tar -cf - * | tar -xf - -C ${FSDIR}/${NBINDIR} 2>>${ERRFILE} >>${ERRFILE}
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
mkdir -p ${FSDIR}/tmp
mkdir -p ${FSDIR}/etc
ln -s /tmp  ${FSDIR}/var
ln -s /bin ${FSDIR}/sbin
cd ${WRKDIRPREFIX}
for i in $(find ${FSDIR} -name ".svn")
do
	rm -r ${i}
done
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
dcons_load="YES"
dcons_crom_load="YES"
geom_label_load="YES"
nullfs_load="YES"
dsbsd.fingerprint="${FINGERPRINT}" 
vfs.root.mountfrom="ufs:md0"
EOF

priv mdconfig -d -u $(echo ${MDDEVICE} | cut -c 3-100)
gzip -9 root.fs	2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"

echo -n " * share = Making ISO image ....."
cd ${WRKDIRPREFIX}
mkisofs -b boot/cdboot -no-emul-boot -r -J -V DamnSmallBSD-HEAD -publisher "www.damnsmallbsd.org" -o dsbsd.iso ${BOOTDIR} 2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"
