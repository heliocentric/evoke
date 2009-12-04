# New ports collection makefile for:   xggi
# Date created:        3 December 2009
# Whom:                Dylan Cochran <a134qaed@gmail.com>
#
# $FreeBSD$
# $Id$
#

PORTNAME=      xggi
PORTVERSION=   200912031804
CATEGORIES=    x11-servers
MASTER_SITES=  http://evoke.googlecode.com/files/

MAINTAINER=    a134qaed@gmail.com


LIB_DEPENDS=	ggi.2:${PORTSDIR}/graphics/libggi
LIB_DEPENDS=	freetype.9:${PORTSDIR}/print/freetype2
BUILD_DEPENDS=       ${LOCALBASE}/libdata/pkgconfig/fontconfig.pc:${PORTSDIR}/x11-fonts/fontconfig

WRKSRC=		${WRKDIR}/xggi
FAKEROOT=	${WRKDIR}/fakeroot

CPPFLAGS=	-I${LOCALBASE}/xggi/include ${CPPFLAGS}
LDFLAGS=	-L${LOCALBASE}/xggi/lib ${CPPFLAGS}

do-build:
	${MKDIR} ${FAKEROOT}
	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi build

.include <bsd.port.mk>
