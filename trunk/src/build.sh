#!/bin/sh
# $Id$

export TARGETS="6.3-RC1"
export VERSION="HEAD"
echo -n " * share = Cleaning up object files ....."
export ROOTDIR=`pwd`
export OBJDIR=${ROOTDIR}/obj
chflags -R noschg ${OBJDIR} 2>/dev/null
rm -r ${OBJDIR} 2>/dev/null
mkdir -p ${OBJDIR}
export BUILDDIR=${ROOTDIR}/builder

echo " [DONE"
${BUILDDIR}/build.sh ${1}
