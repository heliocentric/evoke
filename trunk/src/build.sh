#!/bin/sh
# $Id$

ROOTDIR=`pwd`
OBJDIR=${OBJDIR}/obj
mkdir -p ${OBJDIR}
BUILDERDIR=${ROOTDIR}/builder

${BUILDERDIR}/build.sh
