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
	if [ -d "${DESTDIR}" ] ; then
		case "${CLEAN}" in
			[yY][eE][sS])
				chflags -R noschg ${WRKDIRPREFIX}/${TARGET}
				rm -rf ${WRKDIRPREFIX}/${TARGET}
			;;
		esac
	fi
	for distset in base kernels src
	do
		cd ${FBSD_DISTDIR}/${distset}
		for dist in *.aa
		do
			distfile=$(echo ${dist} | cut -d \. -f 1)
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
					cat ${distfile}.?? | gunzip | tar -xpf - -C ${DESTDIR}/
				;;
			esac
		done
	done
done

for TARGET in ${ARCHS}
do
	export WORKDIR=${WRKDIRPREFIX}/${TARGET}
	export TARGET
	export TARGET_ARCH="${TARGET}"
	export MAKEOBJDIRPREFIX=/tmp/${TARGET}
#	rm -rf /tmp/${TARGET} 2>/dev/null
	cd ${WORKDIR}/usr/src/sys/boot/
	export BOOTPATH="/.boot/0.1r2/${TARGET}"
	mkdir -p ${WORKDIR}${BOOTPATH}
	for file in $(cat ${WRKDIRPREFIX}/bootlist)
	do
	    sed -i .bak "s_/boot_${BOOTPATH}_g" ${WORKDIR}/${file}
	done
	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c
	cd ${WORKDIR}/usr/src/
	make -DNO_CLEAN -DLOADER_TFTP_SUPPORT -DLOADER_BZIP2_SUPPORT LOADER_FIREWIRE_SUPPORT="yes" buildworld
	priv make DESTDIR=${WORKDIR} installworld
done
