#!/bin/sh
# $Id$

cd ${WORKDIR}/usr/src/sys/boot/
#for file in $(cat ${ROOTDIR}/bootlist)
#do
#    sed -i .bak "s_/boot_${BOOTPATH}_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#    sed -i .bak "s_/BOOT_$(echo ${BOOTPATH} | tr a-z A-Z)_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#done
sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 2>>${ERRFILE} >>${ERRFILE}
sed -i .bak "s_\"/rescue_\"${NBINDIR}_g" ${WORKDIR}/usr/src/include/paths.h 2>>${ERRFILE} >>${ERRFILE}
sed -i .bak "s_\"/etc/rc_\"/share/bin/systart_g" ${WORKDIR}/usr/src/sbin/init/pathnames.h 2>>${ERRFILE} >>${ERRFILE}
cp ${BUILDDIR}/lazybox.static ${WORKDIR}/usr/src/rescue/rescue/Makefile
echo " [DONE]"

echo -n " * ${target} = Building World ....."
cd ${WORKDIR}/usr/src/
if [ "${NO_CLEAN}" = "" ] ; then
	make  -DLOADER_TFTP_SUPPORT buildworld 2>>${ERRFILE} >>${ERRFILE}
fi
echo " [DONE]"

echo -n " * ${target} = Populating DESTDIR ....."
export DESTDIR=${WRKDIRPREFIX}/${target}
mkdir -p ${DESTDIR}
priv make hierarchy 2>>${ERRFILE} >>${ERRFILE}
rm -r ${DESTDIR}/rescue
mkdir -p ${DESTDIR}/rescue
mkdir -p ${DESTDIR}${BOOTPATH}/defaults
priv make installworld 2>>${ERRFILE} >>${ERRFILE}
priv make distribution 2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"

echo -n " * ${target} = Populating FSDIR ....."
mkdir -p ${FSDIR}${NBINDIR} 2>>${ERRFILE} >>${ERRFILE}
mkdir -p ${FSDIR}${NDIR}/lib 2>>${ERRFILE} >>${ERRFILE}
mkdir -p ${FSDIR}${NDIR}/libexec 2>>${ERRFILE} >>${ERRFILE}
cd ${WORKDIR}/rescue && tar -cf - * | tar -xf - -C ${FSDIR}${NBINDIR} 2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"

