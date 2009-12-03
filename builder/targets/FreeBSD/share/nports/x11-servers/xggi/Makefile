# New ports collection makefile for:   xggi
# Date created:        3 December 2009
# Whom:                Dylan Cochran <a134qaed@gmail.com>
#
# $FreeBSD$
# $Id$
#

PORTNAME=      xggi
PORTVERSION=   200912031642
CATEGORIES=    x11-servers
MASTER_SITES=  http://evoke.googlecode.com/files/

MAINTAINER=    a134qaed@gmail.com

#BUILD_DEPENDS=	pkg-config:${PORTSDIR}/devel/pkg-config
#BUILD_DEPENDS+=	gnome-config:${PORTSDIR}/x11/gnome-libs
#BUILD_DEPENDS+=	fc-cache:${PORTSDIR}/x11-fonts/fontconfig
#BUILD_DEPENDS+=	xcursorgen:${PORTSDIR}/x11/xcursorgen
#BUILD_DEPENDS+= xkbcomp:${PORTSDIR}/x11/xkbcomp
#BUILD_DEPENDS+= mkfontscale:${PORTSDIR}/x11-fonts/mkfontscale

LIB_DEPENDS=	ggi.2:${PORTSDIR}/graphics/libggi
#LIB_DEPENDS+=	freetype.9:${PORTSDIR}/print/freetype2

WRKSRC=		${WRKDIR}/xggi
FAKEROOT=	${WRKDIR}/fakeroot

#USE_XORG=       x11 xf86driproto glproto randrproto renderproto fixesproto \
#                dri2proto damageproto xcmiscproto xtrans inputproto \
#                xf86bigfontproto scrnsaverproto bigreqsproto \
#                resourceproto fontsproto videoproto \
#                compositeproto trapproto recordproto \
#                xineramaproto xinerama evieproto xkbfile xfont \
#                xau xdmcp xext fontenc xv pixman dmxproto printproto \
#		bigreqsproto fontcacheproto kbproto xextproto \
#		xf86bigfontproto xf86dgaproto xf86miscproto xf86rushproto \
#		xf86vidmodeproto xproto xmu xpm xfixes xrender fontutil xp \
#		xprintutil xt xaw7 dmx ice sm xi xkbui \
#		xmuu xres xtst xxf86misc xxf86vm


#do-configure:
#	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi configure
do-build:
	${MKDIR} ${FAKEROOT}
	cd ${WRKSRC} && DESTDIR="${FAKEROOT}" ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi build
#do-install:
#	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi install

.include <bsd.port.mk>
