#!/bin/sh
# Copyright 2007-2009 Dylan Cochran
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

export WRKDIRPREFIX=/usr/obj
export PACKAGES=/packages
mkdir ${PACKAGES}
unexport DESTDIR
unexport TMPDIR
unexport KERNCONF
unexport ABI

LOCALBASE=/usr/local
X11BASE=/usr/local
OSVERSION=`awk '/^#define __FreeBSD_version/ {print $3}' < /usr/src/sys/sys/param.h`
OSREL=`awk 'BEGIN {FS="\""}; /^REVISION/ {print $2}' < /usr/src/sys/conf/newvers.sh`
BRANCH=`awk 'BEGIN {FS="\""}; /^BRANCH/ {print $2}' < /usr/src/sys/conf/newvers.sh`
ARCH=`uname -p`
UNAME_n=tinderbox.host
UNAME_r=${OSREL}-${BRANCH}
UNAME_s=FreeBSD
UNAME_v="FreeBSD ${OSREL}-${BRANCH} #0: `date`    root@tinderbox.host:/usr/src/sys/magic/kernel/path"
#
BATCH=1
PACKAGE_BUILDING=1
USA_RESIDENT=YES
PORTOBJFORMAT=elf
HAVE_MOTIF=1
FTP_PASSIVE_MODE=yes
FTP_TIMEOUT=900
HTTP_TIMEOUT=900

for i in $(set | grep = | awk -F= '{ print $1 }') ; do
    export ${i}
done

for port in $(cat /portlist | cut -d : -f 3  | sort | uniq)
do
	cd /usr/ports/${port}/
	make -DFORCE_PKG_REGISTER -DNO_IGNORE -DBATCH package-recursive
done
