# New ports collection makefile for:   xggi
# Date created:        3 December 2009
# Whom:                Dylan Cochran <a134qaed@gmail.com>
#
# $FreeBSD$
# $Id$
#

PORTNAME=      xggi
PORTVERSION=   200912030903
CATEGORIES=    x11-servers
MASTER_SITES=  http://evoke.googlecode.com/files/

WRKSRC=		${WRKDIR}/xggi
MAINTAINER=    a134qaed@gmail.com

do-configure:
	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xxggi configure
do-build:
	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi build
do-install:
	cd ${WRKSRC} && ./build-release.sh --with-ggi=${LOCALBASE} ${LOCALBASE}/xggi install

.include <bsd.port.mk>
