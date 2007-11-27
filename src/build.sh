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

ARCHS="i386"
# Choose dist source

echo "Please insert a FreeBSD 6.3-BETA2 CD, and specify the device node. (ex. cd0)"
echo " -- OR --"
echo "Enter the path of the release files (/home/user/blah)" 


until [ "${DONE}" = "done" ]
do
	if [ -f "${WRKDIRPREFIX}/6.3-BETA2-i386-disc1.iso" ] ; then
		echo "insert mount iso"
	fi
	read -p "[acd0] > " NODE
	case "${NODE}" in
		?cd*)

		;;
		*)
			if [ -d "${NODE}/6.3-BETA2" ] ; then
				export FBSD_DISTDIR="${NODE}/6.3-BETA2"
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
		if [ "${NO_CLEAN}" = "" ] ; then
			rm -rf ${DESTDIR}
		fi
	fi
	for distset in base kernels src
	do
		cd ${FBSD_DISTDIR}/${distset}
		for dist in *.aa
		do
			distfile=$(echo ${dist} | cut -d \. -f 1)
			echo -n " * Extracting ${distset}/${distfile} ....."
			case "${distset}" in
				src)
					mkdir -p ${DESTDIR}/usr/src
					cat ${distfile}.?? | gunzip | tar -xpf - -C ${DESTDIR}/usr/src/
				;;
				kernels)
					mkdir -p ${DESTDIR}/boot
					cat ${distfile}.?? | gunzip | tar -xpf - -C ${DESTDIR}/boot/
				;;
				*)
					mkdir -p ${DESTDIR}
					cat ${distfile}.?? | gunzip | tar -xpf - -C ${DESTDIR}/
				;;
			esac
			echo " [DONE]"
		done
	done
done

export ERRFILE=${WRKDIRPREFIX}/error.log
export BOOTDIR=${WRKDIRPREFIX}/bdir
export FSDIR=${WRKDIRPREFIX}/fsdir

for TARGET in ${ARCHS}
do
	export WORKDIR=${WRKDIRPREFIX}/${TARGET}
	export TARGET
	export TARGET_ARCH="${TARGET}"
	export MAKEOBJDIRPREFIX=/tmp/${TARGET}

	echo -n " * Cleaning up object files....."
	if [ "${NO_CLEAN}" = "" ] ; then
		rm -rf /tmp/${TARGET} 2>/dev/null
	fi
	echo " [DONE]"

	echo -n " * Patching World....."
	cd ${WORKDIR}/usr/src/sys/boot/
	export BOOTPATH="/.boot/0.1r2/${TARGET}"
	for file in $(find ./ -not -type d)
	do
	    sed -i .bak "s_\"/boot/kernel_\"${BOOTPATH}/GENERIC_g" ${file} 2>>${ERRFILE} >>${ERRFILE}
	    sed -i .bak "s_\"/boot/loader_\"${BOOTPATH}/loader_g" ${file} 2>>${ERRFILE} >>${ERRFILE}
	done
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 2>>${ERRFILE} >>${ERRFILE}
	echo " [DONE]"


	echo -n " * Building World....."
	cd ${WORKDIR}/usr/src/
	if [ "${NO_CLEAN}" = "" ] ; then
#		make  -DNO_CLEAN -DLOADER_TFTP_SUPPORT -DLOADER_BZIP2_SUPPORT LOADER_FIREWIRE_SUPPORT="yes" buildworld 2>>${ERRFILE} >>${ERRFILE}
	fi
	echo " [DONE]"

	echo -n " * Populating DESTDIR=${DESTDIR}....."
	export DESTDIR=${WRKDIRPREFIX}/${TARGET}
	mkdir -p ${DESTDIR}
	priv make distribution 2>>${ERRFILE} >>${ERRFILE}
	priv make installworld 2>>${ERRFILE} >>${ERRFILE}
	mkdir -p ${DESTDIR}/usr/src
	priv mount_nullfs ${WORKDIR}/usr/src/ ${DESTDIR}/usr/src/ 2>>${ERRFILE} >>${ERRFILE}
	echo " [DONE]"

	echo -n " * Compressing Kernel ....."
	for i in GENERIC SMP
	do
		cd ${DESTDIR}/boot/${i}/
		bzip2 *
	done

	echo " [DONE]"

	echo -n " * Populating BOOTPATH=${BOOTPATH}....."
	mkdir -p ${BOOTPATH} 2>>${ERRFILE} >>${ERRFILE}
	cd ${DESTDIR}/boot/
	tar -cf - * | tar -xvf - -C ${BOOTPATH} 2>>${ERRFILE} >>${ERRFILE}
	echo " [DONE]"


	echo -n " * Populating FSDIR=${FSDIR}....."
	mkdir -p ${FSDIR}/FreeBSD6/${TARGET}/bin 2>>${ERRFILE} >>${ERRFILE}
	cd ${WORKDIR}/rescue/
	tar -cf - * | tar -xf - -C ${FSDIR}/FreeBSD6/${TARGET}/bin 2>>${ERRFILE} >>${ERRFILE}
	echo " [DONE]"

	echo -n " * Populating FSDIR=${FSDIR}....."
	cd ${BOOTDIR}${BOOTPATH}
	makefs root.fs ${FSDIR}
	gzip -9 root.fs	
	echo " [DONE]"

	umount ${DESTDIR}/usr/src
done
