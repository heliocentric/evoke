#!/bin/sh
# $Id$

if [ "${WRKDIRPREFIX}" = "" ] ; then
	export WRKDIRPREFIX=$(pwd)
fi

ARCHS="i386 amd64 powerpc"

echo "Please Insert a FreeBSD 6.3 CD, and specify the device node. (ex. cd0)"
echo " -- OR --
echo "Enter the path of the release files (/home/user/blah)" 
read -p "[acd0] > " NODE

case "${NODE}" in
	/*)
		echo "${NODE}"
	;;
	?cd*)
		echo "${NODE}"
	*)
		
	;;
e
sac
#
#for TARGET in ${ARCHS}
#do
#	chflags -R noschg ${WRKDIRPREFIX}/${TARGET}
#	rm -r ${WRKDIRPREFIX}/${TARGET}
#	rm -r /tmp/${TARGET}
#	mkdir -p ${WRKDIRPREFIX}/${TARGET}/usr/src
#	export DESTDIR=${WRKDIRPREFIX}/${TARGET}
#	cd /mnt/6.3-BETA2/src/
#	for dist in *.aa
#	do
#		distfile=$(echo ${dist} | cut -d \. -f 1)
#		echo ${distfile}
#		echo ${DESTDIR}
#		cat ${distfile}.?? | gunzip | tar -xpf - -v -C ${DESTDIR}/usr/src
#	done
#done

#for TARGET in ${ARCHS}
#do
#	export WORKDIR=${WRKDIRPREFIX}/${TARGET}
#	export TARGET
#	export TARGET_ARCH="${TARGET}"
#	export MAKEOBJDIRPREFIX=/tmp/${TARGET}
#	cd ${WORKDIR}/usr/src/sys/boot/
#	export BOOTPATH="/.boot/0.1r2/${TARGET}"
#	mkdir -p ${WORKDIR}${BOOTPATH}
#	for file in $(cat ${WRKDIRPREFIX}/bootlist)
#	do
#	    echo "${WORKDIR}/${i}"
#	    sed -i .bak "s!/boot!${BOOTPATH}!g" ${WORKDIR}/${file}
#	done
#	sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c
#	cd ${WORKDIR}/usr/src/
#	make -DLOADER_TFTP_SUPPORT -DLOADER_BZIP2_SUPPORT LOADER_FIREWIRE_SUPPORT="yes" buildworld
#	make DESTDIR=${WORKDIR} installworld
#	rm -r /tmp/${TARGET}
#done
