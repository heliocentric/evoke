--- build-release.sh	2009-12-05 15:46:55.000000000 +0000
+++ build-release.sh	2009-12-06 02:27:33.000000000 +0000
@@ -34,29 +34,24 @@
 }
 
 build() {
-    cd $1
-
-    TARBALL=`ls -1rt $2-*.tar.$COMPRESSION 2> /dev/null | tail -1`
-
-    if test x"$TARBALL" = x; then
-	echo "WARNING: $2 does not exist -- skipping"
-	cd ..
-	return
+    STORDIR="`pwd`"
+    if [ -d "${1}/${2}" ] ; then
+	cd "${1}/${2}"
+    else
+	    if [ ! -d "${1}" ] ; then
+		cd "${STORDIR}"
+		exit 2
+	    fi
+
+	    cd "$1"
+	    TARDIR=`echo $2-* 2> /dev/null | tail -1`
+	    if [ ! -d "${TARDIR}" ] ; then
+		cd "${STORDIR}"
+		exit 2
+	    fi
+	    echo "${1}/${TARDIR}"
+	    cd $TARDIR
     fi
-    TARDIR=`echo $TARBALL | sed "s,.tar.$COMPRESSION,,"`
-
-    echo "Building $1 module component $TARDIR..."
-
-    case $COMPRESSION in
-	bz2)
-	    tar xjf $TARBALL
-	    break;;
-	gz)
-	    tar xvf $TARBALL
-	    break;;
-    esac
-
-    cd $TARDIR
 
     if test "$1" = "xserver" && test "$2" = "xorg-server" && test -n "$MESAPATH"; then
 	MESA=-"-with-mesa-source=${MESAPATH}"
@@ -64,38 +59,41 @@
 	MESA=
     fi
 
-    if test "$1" = "xserver" && test "$2" = "xggi-server"; then
+    if test "$1" = "xserver" && test "$2" = "xggi"; then
 	GGIROOT="--with-ggi=${GGIPREFIX}"
     else
 	GGIROOT=
     fi
 
-    sh configure --prefix=${PREFIX} ${MESA} ${GGIROOT} ${QUIET:+--quiet} \
-        ${CACHE:+--cache-file=}${CACHE} ${CONFFLAGS} || failed configure $1 $2
-    make || failed make $1 $2
-    if test x"$CLEAN" = x1; then
-	make clean || failed clean $1 $2
-    fi
+
+		    if test -r "configure"; then
+		        AUTOGEN="sh configure"
+		    else
+		        AUTOGEN="sh autogen.sh"
+		    fi
+		    ${AUTOGEN} --prefix=${PREFIX} ${MESA} ${GGIROOT} --disable-xcsecurity ${QUIET:+--quiet} \
+		        ${CACHE:+--cache-file=}${CACHE} ${CONFFLAGS} --with-rgb-path="${LOCALBASE}/lib/X11/rgb" --with-xkb-path="${LOCALBASE}/lib/X11/xkb" || failed autogen $1 $2
+			make || failed make $1 $2
+			make clean || failed clean $1 $2
+			    $SUDO env LD_LIBRARY_PATH=$LD_LIBRARY_PATH DESTDIR="${FAKEROOT}" make install || \
+				failed install $1 $2
     if test x"$DIST" = x1; then
 	make dist || failed dist $1 $2
     fi
     if test x"$DISTCHECK" = x1; then
 	make distcheck || failed distcheck $1 $2
     fi
-    $SUDO env LD_LIBRARY_PATH=$LD_LIBRARY_PATH make install || \
-	failed install $1 $2
-
-    cd ../..
+	cd "${STORDIR}"
 }
 
 # protocol headers have no build order dependencies
 build_proto() {
-    build proto applewmproto
+#    build proto applewmproto
     build proto bigreqsproto
     build proto compositeproto
     build proto damageproto
     build proto dmxproto
-    build proto evieext
+#    build proto evieext
     build proto fixesproto
     build proto fontcacheproto
     build proto fontsproto
@@ -110,7 +108,7 @@
     build proto scrnsaverproto
     build proto trapproto
     build proto videoproto
-    build proto windowswmproto
+#    build proto windowswmproto
     build proto xcmiscproto
     build proto xextproto
     build proto xf86bigfontproto
@@ -121,7 +119,7 @@
     build proto xf86vidmodeproto
     build proto xineramaproto
     build proto xproto
-    build proto xproxymanagementprotocol
+#    build proto xproxymanagementprotocol
 }
 
 # bitmaps is needed for building apps, so has to be done separately first
@@ -152,8 +150,8 @@
     build lib libXdmcp
     build lib libX11
     build lib libXext
-    build lib libAppleWM
-    build lib libWindowsWM
+#    build lib libAppleWM
+#    build lib libWindowsWM
     build lib libdmx
     build lib libfontenc
     build lib libFS
@@ -171,7 +169,7 @@
     build lib libXrender
     build lib libXdamage
     build lib libXcursor
-    build lib libXevie
+#    build lib libXevie
     build lib libXfont
     build lib libXfontcache
     build lib libXft
@@ -299,7 +297,7 @@
 # The server requires at least the following libraries:
 # Xfont, Xau, Xdmcp
 build_xserver() {
-    build xserver xggi-server
+    build xserver xggi
 }
 
 build_driver_input() {
@@ -556,6 +554,8 @@
 	;;
     *)
 	PREFIX=$1
+	shift
+	BUILD_MODE="$1"
 	;;
     esac
 
@@ -566,9 +566,8 @@
     usage
     exit
 fi
-
 # Must create local aclocal dir or aclocal fails
-ACLOCAL_LOCALDIR="${DESTDIR}${PREFIX}/share/aclocal"
+ACLOCAL_LOCALDIR="${FAKEROOT}${PREFIX}/share/aclocal"
 $SUDO mkdir -p ${ACLOCAL_LOCALDIR}
 
 # The following is required to make aclocal find our .m4 macros
@@ -581,25 +580,25 @@
 
 # The following is required to make pkg-config find our .pc metadata files
 if test x"$PKG_CONFIG_PATH" = x; then
-    PKG_CONFIG_PATH=${DESTDIR}${PREFIX}/lib/pkgconfig
+    PKG_CONFIG_PATH=${FAKEROOT}${PREFIX}/lib/pkgconfig
 else
-    PKG_CONFIG_PATH=${DESTDIR}${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
+    PKG_CONFIG_PATH=${FAKEROOT}${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}
 fi
 export PKG_CONFIG_PATH
 
 # Set the library path so that locally built libs will be found by apps
 if test x"$LD_LIBRARY_PATH" = x; then
-    LD_LIBRARY_PATH=${DESTDIR}${PREFIX}/lib
+    LD_LIBRARY_PATH=${FAKEROOT}${PREFIX}/lib
 else
-    LD_LIBRARY_PATH=${DESTDIR}${PREFIX}/lib:${LD_LIBRARY_PATH}
+    LD_LIBRARY_PATH=${FAKEROOT}${PREFIX}/lib:${LD_LIBRARY_PATH}
 fi
 export LD_LIBRARY_PATH
 
 # Set the path so that locally built apps will be found and used
 if test x"$PATH" = x; then
-    PATH=${DESTDIR}${PREFIX}/bin
+    PATH=${FAKEROOT}${PREFIX}/bin
 else
-    PATH=${DESTDIR}${PREFIX}/bin:${PATH}
+    PATH=${FAKEROOT}${PREFIX}/bin:${PATH}
 fi
 export PATH
 
@@ -610,7 +609,7 @@
 fi
 
 # Create the log file directory
-$SUDO mkdir -p ${DESTDIR}${PREFIX}/var/log
+$SUDO mkdir -p ${FAKEROOT}${PREFIX}/var/log
 
 date
 
