#!/bin/sh
# $Id$

export ROOTDIR=`pwd`
export OBJDIR=${OBJDIR}/obj/$(date "+%Y%m%d%H%M.%S")
mkdir -p ${OBJDIR}
export BUILDERDIR=${ROOTDIR}/builder

${BUILDERDIR}/build.sh
