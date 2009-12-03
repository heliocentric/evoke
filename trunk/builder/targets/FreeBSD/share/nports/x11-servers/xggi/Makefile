# New ports collection makefile for:   xggi
# Date created:        3 December 2009
# Whom:                Dylan Cochran <a134qaed@gmail.com>
#
# $FreeBSD$
# $Id$
#

PORTNAME=      xggi
PORTVERSION=   200912030951
CATEGORIES=    x11-servers
MASTER_SITES=  http://evoke.googlecode.com/files/

WRKSRC=		${WRKDIR}/xggi
MAINTAINER=    a134qaed@gmail.com
BUILD_DEPENDS=	pkg-config:${PORTSDIR}devel/pkg-config
LIB_DEPENDS=	ggi.2:${PORTSDIR}/graphics/jpeg

USE_XORG=       x11 xf86driproto glproto randrproto renderproto fixesproto \
                dri2proto damageproto xcmiscproto xtrans inputproto \
                xf86bigfontproto scrnsaverproto bigreqsproto \
                resourceproto fontsproto videoproto \
                compositeproto trapproto recordproto \
                xineramaproto xinerama evieproto xkbfile xfont \
                xau xdmcp xext fontenc xv pixman

do-configure:
	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi configure
do-build:
	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi build
do-install:
	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi install

.include <bsd.port.mk>
