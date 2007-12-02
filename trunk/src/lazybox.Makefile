#$FreeBSD: src/rescue/rescue/Makefile,v 1.45.2.2 2007/02/20 08:33:31 delphij Exp $
#	@(#)Makefile	8.1 (Berkeley) 6/2/93

PROG=	lazybox
BINDIR?=/rescue

# Shell scripts need #! line to be edited from /bin/sh to /rescue/sh
SCRIPTS= nextboot_FIXED
SCRIPTSNAME_nextboot_FIXED= nextboot
nextboot_FIXED: ../../sbin/reboot/nextboot.sh
	sed '1s/\/bin\//\/rescue\//' ${.ALLSRC} > ${.TARGET}
CLEANFILES+= nextboot_FIXED

SCRIPTS+= dhclient_FIXED
SCRIPTSNAME_dhclient_FIXED= dhclient-script
dhclient_FIXED: ../../sbin/dhclient/dhclient-script
	sed '1s/\/bin\//\/rescue\//' ${.ALLSRC} > ${.TARGET}
CLEANFILES+= dhclient_FIXED

#################################################################
#
# General notes:
#
# A number of Make variables are used to generate the crunchgen config file.
#
#  CRUNCH_SRCDIRS: lists directories to search for included programs
#  CRUNCH_PROGS:  lists programs to be included
#  CRUNCH_LIBS:  libraries to link with
#  CRUNCH_BUILDOPTS: generic build options to be added to every program
#
# Special options can be specified for individual programs
#  CRUNCH_SRCDIR_$(P): base source directory for program $(P)
#  CRUNCH_BUILDOPTS_$(P): additional build options for $(P)
#  CRUNCH_ALIAS_$(P): additional names to be used for $(P)
#
# By default, any name appearing in CRUNCH_PROGS or CRUNCH_ALIAS_${P}
# will be used to generate a hard link to the resulting binary.
# Specific links can be suppressed by setting
# CRUNCH_SUPPRESS_LINK_$(NAME) to 1.
#

# Define Makefile variable RESCUE
CRUNCH_BUILDOPTS+= -DRESCUE
# Define compile-time RESCUE symbol when compiling components
CRUNCH_BUILDOPTS+= CRUNCH_CFLAGS=-DRESCUE

# An experiment that failed: try overriding bsd.lib.mk and bsd.prog.mk
# rather than incorporating rescue-specific logic into standard files.
#MAKEFLAGS= -m ${.CURDIR} ${.MAKEFLAGS}

# Hackery:  'librescue' exists merely as a tool for appropriately
# recompiling specific library entries.  We _know_ they're needed, and
# regular archive searching creates ugly library ordering problems.
# Easiest fix: tell the linker to include them into the executable
# first, so they are guaranteed to override the regular lib entries.
# Note that if 'librescue' hasn't been compiled, we'll just get the
# regular lib entries from libc and friends.
CRUNCH_LIBS+= ${.OBJDIR}/../librescue/*.o

###################################################################
# Programs from stock /bin
#
# WARNING: Changing this list may require adjusting
# /usr/include/paths.h as well!  You were warned!
#
CRUNCH_SRCDIRS+= bin
CRUNCH_PROGS_bin= cat chio chmod date dd df echo 	\
	 expr kenv kill ln ls mkdir mv ps pwd 	\
	 realpath rm sh stty test
CRUNCH_LIBS+= -lcrypt -ledit -lkvm -lm -lutil
.if !defined(NO_CRYPT) && !defined(NO_OPENSSL)
CRUNCH_LIBS+= -lcrypto
.endif

# Additional options for specific programs
CRUNCH_ALIAS_test= [
CRUNCH_ALIAS_sh= -sh
# The -sh alias shouldn't appear in /rescue as a hard link
CRUNCH_SUPPRESS_LINK_-sh= 1
CRUNCH_ALIAS_ln= link
CRUNCH_ALIAS_rm= unlink


.if !defined(NO_TCSH)
CRUNCH_PROGS_bin+= csh
CRUNCH_ALIAS_csh= -csh tcsh -tcsh
CRUNCH_SUPPRESS_LINK_-csh= 1
CRUNCH_SUPPRESS_LINK_-tcsh= 1
.endif

###################################################################
# Programs from standard /sbin
#
# WARNING: Changing this list may require adjusting
# /usr/include/paths.h as well!  You were warned!
#
# Note that mdmfs have their own private 'pathnames.h'
# headers in addition to the standard 'paths.h' header.
#
CRUNCH_SRCDIRS+= sbin
CRUNCH_PROGS_sbin= atacontrol bsdlabel		\
	camcontrol clri devfs dmesg			\
	fsck_ffs fsck_msdosfs 	\
	ifconfig init 				\
	kldconfig kldload kldstat kldunload 			\
	md5 mdconfig mdmfs mount	\
	mount_nullfs			\
	newfs		\
	ping reboot			\
	route 		\
	swapon sysctl umount 


# crunchgen does not like C++ programs; this should be fixed someday
# CRUNCH_PROGS+= devd

CRUNCH_LIBS+= -lbsdxml -lcam -lcurses -lipsec -lipx \
	-lgeom -lmd -lsbuf -lufs -lz -ll

.if ${MACHINE_ARCH} == "i386"
CRUNCH_PROGS_sbin+= fdisk
CRUNCH_ALIAS_bsdlabel= disklabel
#CRUNCH_PROGS+= mount_nwfs mount_smbfs
#CRUNCH_LIBS+= -lncp -lsmb
.endif

.if ${MACHINE} == "pc98"
CRUNCH_SRCDIR_fdisk= $(.CURDIR)/../../sbin/fdisk_pc98
.endif

.if ${MACHINE_ARCH} == "ia64"
CRUNCH_PROGS_sbin+= mca gpt fdisk
.endif

.if ${MACHINE_ARCH} == "sparc64"
CRUNCH_PROGS_sbin+= sunlabel
.endif

.if ${MACHINE_ARCH} == "alpha"
CRUNCH_ALIAS_bsdlabel= disklabel
.endif

.if ${MACHINE_ARCH} == "amd64"
CRUNCH_PROGS_sbin+= fdisk
CRUNCH_ALIAS_bsdlabel= disklabel
.endif

CRUNCH_ALIAS_reboot= halt

# dhclient has historically been troublesome...
CRUNCH_PROGS_sbin+= dhclient
CRUNCH_BUILDOPTS_dhclient= -DRELEASE_CRUNCH -Dlint

##################################################################
# Programs from stock /usr/bin
# 
CRUNCH_SRCDIRS+= usr.bin usr.sbin gnu/usr.bin

CRUNCH_PROGS_usr.bin+= gzip
CRUNCH_ALIAS_gzip= gunzip gzcat zcat

CRUNCH_PROGS_usr.bin+= bzip2
CRUNCH_ALIAS_bzip2= bunzip2 bzcat
CRUNCH_LIBS+= -lbz2

CRUNCH_PROGS_usr.bin+= tar
CRUNCH_LIBS+= -larchive

CRUNCH_PROGS_usr.bin+= ee

CRUNCH_PROGS_usr.bin+= id
CRUNCH_ALIAS_id= groups whoami

CRUNCH_PROGS_gnu/usr.bin+= grep
CRUNCH_LIBS+= -lgnuregex

CRUNCH_PROGS_usr.bin+= less tail head
CRUNCH_ALIAS_less= more
#CRUNCH_PROGS_usr.bin+= ssh
#CRUNCH_LIBS+= -lssh -lgssapi -lcrypto -lcrypt -lpam -lasn1 -lkrb5 -lroken -lcom_err
##################################################################
# Programs from stock /usr/sbin
# 

##################################################################
#  The following is pretty nearly a generic crunchgen-handling makefile
#

CONF=	$(PROG).conf
OUTMK=	$(PROG).mk
OUTC=   $(PROG).c
OUTPUTS=$(OUTMK) $(OUTC) $(PROG).cache
CRUNCHOBJS= ${.OBJDIR}
.if defined(MAKEOBJDIRPREFIX)
CANONICALOBJDIR:= ${MAKEOBJDIRPREFIX}${.CURDIR}
.else
CANONICALOBJDIR:= /usr/obj${.CURDIR}
.endif

NO_MAN=
CLEANFILES+= $(CONF) *.o *.lo *.c *.mk *.cache *.a *.h

# Program names and their aliases contribute hardlinks to 'rescue' executable,
# except for those that get suppressed.
.for D in $(CRUNCH_SRCDIRS)
.for P in $(CRUNCH_PROGS_$(D))
.ifdef CRUNCH_SRCDIR_${P}
$(OUTPUTS): $(CRUNCH_SRCDIR_${P})/Makefile
.else
$(OUTPUTS): $(.CURDIR)/../../$(D)/$(P)/Makefile
.endif
.ifndef CRUNCH_SUPPRESS_LINK_${P}
LINKS+= $(BINDIR)/$(PROG) $(BINDIR)/$(P)
.endif
.for A in $(CRUNCH_ALIAS_$(P))
.ifndef CRUNCH_SUPPRESS_LINK_${A}
LINKS+= $(BINDIR)/$(PROG) $(BINDIR)/$(A)
.endif
.endfor
.endfor
.endfor

all: $(PROG)
exe: $(PROG)

$(CONF): Makefile
	echo \# Auto-generated, do not edit >$(.TARGET)
.ifdef CRUNCH_BUILDOPTS
	echo buildopts $(CRUNCH_BUILDOPTS) >>$(.TARGET)
.endif
.ifdef CRUNCH_LIBS
	echo libs $(CRUNCH_LIBS) >>$(.TARGET)
.endif
.for D in $(CRUNCH_SRCDIRS)
.for P in $(CRUNCH_PROGS_$(D))
	echo progs $(P) >>$(.TARGET)
.ifdef CRUNCH_SRCDIR_${P}
	echo special $(P) srcdir $(CRUNCH_SRCDIR_${P}) >>$(.TARGET)
.else
	echo special $(P) srcdir $(.CURDIR)/../../$(D)/$(P) >>$(.TARGET)
.endif
.ifdef CRUNCH_BUILDOPTS_${P}
	echo special $(P) buildopts DIRPRFX=${DIRPRFX}${P}/ \
	    $(CRUNCH_BUILDOPTS_${P}) >>$(.TARGET)
.else
	echo special $(P) buildopts DIRPRFX=${DIRPRFX}${P}/ >>$(.TARGET)
.endif
.for A in $(CRUNCH_ALIAS_$(P))
	echo ln $(P) $(A) >>$(.TARGET)
.endfor
.endfor
.endfor

# XXX Make sure we don't pass -P to crunchgen(1).
.MAKEFLAGS:= ${.MAKEFLAGS:N-P}
.ORDER: $(OUTPUTS) objs
$(OUTPUTS): $(CONF)
	MAKEOBJDIRPREFIX=${CRUNCHOBJS} crunchgen -fq -m $(OUTMK) \
	    -c $(OUTC) $(CONF)

$(PROG): $(OUTPUTS) objs
	MAKEOBJDIRPREFIX=${CRUNCHOBJS} ${MAKE} -f $(OUTMK) exe

objs: $(OUTMK)
	MAKEOBJDIRPREFIX=${CRUNCHOBJS} ${MAKE} -f $(OUTMK) objs

# <sigh> Someone should replace the bin/csh and bin/sh build-tools with
# shell scripts so we can remove this nonsense.
build-tools:
.for _tool in bin/csh bin/sh 
	cd $(.CURDIR)/../../${_tool}; \
	MAKEOBJDIRPREFIX=${CRUNCHOBJS} ${MAKE} obj; \
	MAKEOBJDIRPREFIX=${CRUNCHOBJS} ${MAKE} build-tools
.endfor

# Use a separate build tree to hold files compiled for this crunchgen binary
# Yes, this does seem to partly duplicate bsd.subdir.mk, but I can't
# get that to cooperate with bsd.prog.mk.  Besides, many of the standard
# targets should NOT be propagated into the components.
cleandepend cleandir obj objlink:
.for D in $(CRUNCH_SRCDIRS)
.for P in $(CRUNCH_PROGS_$(D))
.ifdef CRUNCH_SRCDIR_${P}
	cd ${CRUNCH_SRCDIR_$(P)} && \
	    MAKEOBJDIRPREFIX=${CANONICALOBJDIR} ${MAKE} \
	    DIRPRFX=${DIRPRFX}${P}/ ${.TARGET}
.else
	cd $(.CURDIR)/../../${D}/${P} && \
	    MAKEOBJDIRPREFIX=${CANONICALOBJDIR} ${MAKE} \
	    DIRPRFX=${DIRPRFX}${P}/ ${.TARGET}
.endif
.endfor
.endfor

clean:
	rm -f ${CLEANFILES}
	if [ -e ${.OBJDIR}/$(OUTMK) ]; then				\
		MAKEOBJDIRPREFIX=${CRUNCHOBJS} ${MAKE} -f $(OUTMK) clean;	\
	fi
.for D in $(CRUNCH_SRCDIRS)
.for P in $(CRUNCH_PROGS_$(D))
.ifdef CRUNCH_SRCDIR_${P}
	cd ${CRUNCH_SRCDIR_$(P)} && \
	    MAKEOBJDIRPREFIX=${CANONICALOBJDIR} ${MAKE} \
	    DIRPRFX=${DIRPRFX}${P}/ ${.TARGET}
.else
	cd $(.CURDIR)/../../${D}/${P} && \
	    MAKEOBJDIRPREFIX=${CANONICALOBJDIR} ${MAKE} \
	    DIRPRFX=${DIRPRFX}${P}/ ${.TARGET}
.endif
.endfor
.endfor

.include <bsd.prog.mk>
