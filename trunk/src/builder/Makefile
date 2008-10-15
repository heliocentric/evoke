# Copyright 2007-2008 Dylan Cochran
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


.ifndef ROOTDIR
.error 3
.endif

# Our build targets for the root.fs image.
TARGETS ?= 7.0-RELEASE/i386 7.0-RELEASE/amd64
i386_ACTIVE ?= 7.0-RELEASE/i386

# Evoke Version
VERSION ?= HEAD
RREVISION != cd ${ROOTDIR} && svnversion

# This way we can override REVISION so make iso can generate 
# an ISO image at any point in the tree.
REVISION ?= r${RREVISION}

# Release Engineer
ENGINEER ?= Dylan Cochran

TMPDIR ?= /usr/obj
NDISTDIR ?= ${ROOTDIR}}/dists
OBJDIR ?= ${ROOTDIR}/obj
RELEASEDIR ?= /releases


# Default Program list
# The scripts will resolve library names, so we only need to specify
# the actual binary name.

DPROGS = "atacontrol awk bsdlabel bunzip2 bzcat bzip2 camcontrol cap_mkdb"
DPROGS += " cat chmod cp csh date dconschat dd devfs df dhclient disklabel"
DPROGS += " dmesg echo ee expr fdisk fsck_ffs fsck_msdosfs ftp ftpd fwcontrol"
DPROGS += " geom getty grep groups gunzip gzcat gzip halt head id ifconfig"
DPROGS += " jail jexec jls kenv kill kldconfig kldconfig kldload kldstat"
DPROGS += " kldunload less link ln login ls md5 mdconfig mdmfs mkdir more"
DPROGS += " mount moused mv nc newfs pciconf ping powerd ps pwd pwd_mkdb"
DPROGS += " reboot rm route sed sh sha1 sha256 ssh ssh-keygen sshd stty"
DPROGS += " swapon swapoff swapinfo syslogd tail tar tcsh tftp tftpd top"
DPROGS += " umount uniq unlink usbdevs vidcontrol whoami zcat sort pfctl"
DPROGS += " du makefs mount_msdosfs getextattr setextattr devinfo newfs_msdos"
DPROGS += " stat dirname lsvfs rtsol egrep mount_cd9660 rmdir gpart gpt"

# List of kernel objects in base that will be on the image. Ports modules
# are added automatically.

DMODULES = "acpi tmpfs"



# Shared variables.
default: iso

.if ${VERSION} == HEAD
VERSION = ${REVISION}
REALV = HEAD
.endif

MODULES ?= ${DMODULES}
PROGS ?= $({DPROGS}
BUILDDIR = ${ROOTDIR}/builder
BSDIR ?= /evoke
BOOTPREFIX = ${BSDIR}/${VERSION}
PRODUCTDIR = ${BOOTPREFIX}/product
COOKIEDIR = ${OBJDIR}/cookies

# unset WRKDIRPREFIX
ERRFILE != echo ${ROOTDIR}/logs/$(date +%Y%m%d%H%M%S).log



# make iso variables.
ACTIVE_ABI != echo ${i386_ACTIVE} | cut -d . -f 1 
ISO ?= ${RELEASEDIR}/ISO-IMAGES/${VERSION}/evoke.iso
ISODIR != dirname ${ISO}
ISTMPDIR ?= ${TMPDIR}${ROOTDIR}/iso-gen/



# make release variables.

PER_RELEASE_DIR = ${RELEASEDIR}${BOOTPREFIX}
RELEASECOOKIE = ${COOKIEDIR}/RELEASE

# make bootdir variables.

BOOTDIRCOOKIE = ${COOKIEDIR}/BOOTDIR
BOOTDIR = ${OBJDIR}/bdir

# make rootfs variables.
ROOTFS = ${PRODUCTDIR}/evoke.fs.gz

# make fsdir variables.
FSDIRCOOKIE = ${COOKIEDIR}/FSDIR
FSDIR = ${OBJDIR}/fsdir

# make sharedir variables.
SHARECOOKIE = ${COOKIEDIR}/SHARE
SHAREDIR = ${ROOTDIR}/share
%sharedir != cd ${ROOTDIR} && find share/ -not -path \*.svn\* -type d
%sharefile != cd ${ROOTDIR} && find share/ -not -path \*.svn\* -not -type d




iso: ${ISO}
release: ${RELEASECOOKIE}
bootdir: ${BOOTDIRCOOKIE}
rootfs: ${BOOTDIR}${ROOTFS}
fsdir: ${FSDIRCOOKIE}
sharedir: ${SHARECOOKIE}

${ISO}: ${RELEASECOOKIE} ${PER_RELEASE_DIR}
	@mkdir -p ${COOKIEDIR}
	@mkdir -p ${ISODIR}
	@-rm -r ${ISTMPDIR}
	@mkdir -p ${ISTMPDIR}/cdboot
	@cd ${RELEASEDIR} && tar -cf - .${BOOTPREFIX} | tar -xpf - -C ${ISTMPDIR}
	@cp ${ISTMPDIR}${BOOTPREFIX}/freebsd${ACTIVE_ABI}/i386/cdboot ${ISTMPDIR}/cdboot/i386
	@mkisofs -b cdboot/i386 -no-emul-boot -r -J -V EVOKE-${VERSION} -p "${ENGINEER}" -publisher "http://evoke.googlecode.com" -o ${RELEASEDIR}/ISO-IMAGES/${VERSION}${BSDIR}.iso ${ISTMPDIR} 1>&2

# Note, we have two targets, the cookie and the directory; if either are too old
# real-releasedir will be ran.
# fuck. it will always be run. Even when it doesn't need to be.

${RELEASECOOKIE}: ${BOOTDIRCOOKIE}
	@echo "share = Installing BOOTDIR to release directory"
	@mkdir -p ${PER_RELEASE_DIR}
	@cd ${BOOTDIR}${BOOTPREFIX} && tar -cf - * | tar -xpf - -C ${PER_RELEASE_DIR}
.if ${REALV} == HEAD
	@-rm ${RELEASEDIR}${BSDIR}/${REALV}
	@cd ${RELEASEDIR}${BSDIR} && ln -s ${VERSION} ${REALV}
.endif
	@mkdir -p ${COOKIEDIR}
	@touch ${RELEASECOOKIE}

${PER_RELEASE_DIR}: ${BOOTDIRCOOKIE}
	@echo "share = Installing BOOTDIR to release directory"
	@mkdir -p ${PER_RELEASE_DIR}
	@cd ${BOOTDIR}${BOOTPREFIX} && tar -cf - * | tar -xpf - -C ${PER_RELEASE_DIR}
.if ${REALV} == HEAD
	@-rm ${RELEASEDIR}${BSDIR}/${REALV}
	@cd ${RELEASEDIR}${BSDIR} && ln -s ${VERSION} ${REALV}
.endif
	@mkdir -p ${COOKIEDIR}
	@touch ${RELEASECOOKIE}



# Main BOOTDIR compilation routine.

${BOOTDIRCOOKIE}: ${BOOTDIR}${ROOTFS}
	@mkdir -p ${COOKIEDIR}
	@touch ${BOOTDIRCOOKIE}

# generate a root fs image if FSDIR has been modified.
${BOOTDIR}${ROOTFS}: ${FSDIRCOOKIE} 
	@mkdir -p ${BOOTDIR}${PRODUCTDIR}
	@makefs ${BOOTDIR}${PRODUCTDIR}/evoke.fs ${FSDIR}
	@-rm ${BOOTDIR}${ROOTFS} 1>&2
	@gzip -9 ${BOOTDIR}${PRODUCTDIR}/evoke.fs

# Main FSDIR compilation routine.

${FSDIRCOOKIE}: ${SHARECOOKIE}
	@mkdir -p ${COOKIEDIR}
	@touch ${FSDIRCOOKIE}



clean:
	@echo "share = Cleaning up"
	@rm -r ${COOKIEDIR}
#	chflags -R noschg ${OBJDIR} 2>>${ERRFILE}
#	rm -r ${OBJDIR} 2>>${ERRFILE}
#	mkdir -p ${OBJDIR} 2>>${ERRFILE}


# Share directory.


${SHARECOOKIE}: ${SHAREDIR}/bin/* ${SHAREDIR}/lib/* ${SHAREDIR}/lib/pam.d/*
	@cd ${ROOTDIR} && for dir in ${%sharedir} ; \
	do \
		mkdir -p ${FSDIR}/system/$${dir} ; \
	done

# Add files in share/ to FSDIR/share, however, strip them of all comments and copyrights for space saving.
	@cd ${ROOTDIR} && for file in ${%sharefile} ; \
	do \
		grep '#!' $${file} | head -1 >${FSDIR}/system/$${file} ; \
		grep '$Id' $${file} | head -1 >>${FSDIR}/system/$${file} ; \
		grep -v '^#' $${file} | grep -v '[[:space:]]#' >>${FSDIR}/system/$${file} ; \
		chmod a+rx ${FSDIR}/system/$${file} ; \
	done
	@mkdir -p ${COOKIEDIR}
	@touch ${SHARECOOKIE}


