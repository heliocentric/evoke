#	@(#)Makefile	8.1 (Berkeley) 7/19/93
# $FreeBSD$

PROG=	nexusd
MAN=    nexusd.8

PRECIOUSPROG=
INSTALLFLAGS=-b -B.bak
WARNS?=	6
CFLAGS+=-DDEBUGSHELL -DSECURE -DLOGIN_CAP -DCOMPAT_SYSV_INIT
DPADD=	${LIBUTIL} ${LIBCRYPT}
LDADD=	-lutil -lcrypt
DPADD+=  ${LIBMD}                                                                                                            
LDADD+=  -lmd  

NO_SHARED?=	YES

.include <bsd.prog.mk>
