#!/bin/sh
# Copyright 2007-2010 Dylan Cochran
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted providing that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

# $Id$

cd ${WORKDIR}/usr/src/sys/boot/
#for file in $(cat ${ROOTDIR}/bootlist)
#do
#    sed -i .bak "s_/boot_${BOOTPATH}_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#    sed -i .bak "s_/BOOT_$(echo ${BOOTPATH} | tr a-z A-Z)_g" ${WORKDIR}${file} 2>>${ERRFILE} >>${ERRFILE}
#done
sed -i .bak '/pxe_setnfshandle(rootpath);/d' ${WORKDIR}/usr/src/sys/boot/i386/libi386/pxe.c 2>>${ERRFILE} >>${ERRFILE}
sed -i .bak "s_\"/rescue_\"${N_BIN}_g" ${WORKDIR}/usr/src/include/paths.h 2>>${ERRFILE} >>${ERRFILE}
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
mkdir -p ${FSDIR}${N_BIN} 2>>${ERRFILE} >>${ERRFILE}
mkdir -p ${FSDIR}${N_LIB} 2>>${ERRFILE} >>${ERRFILE}
mkdir -p ${FSDIR}${N_LIBEXEC 2>>${ERRFILE} >>${ERRFILE}
cd ${WORKDIR}/rescue && tar -cf - * | tar -xf - -C ${FSDIR}${N_BIN} 2>>${ERRFILE} >>${ERRFILE}
echo " [DONE]"

