 #!/bin/bash

set -e
set -x

mkdir ~/tinc && cd ~/tinc

BASE=`pwd`
SRC=$BASE/src
WGET="wget --prefer-family=IPv4"
RPATH=/jffs/lib
DEST=$BASE/jffs
LDFLAGS="-L$DEST/lib -Wl,--gc-sections"
CPPFLAGS="-I$DEST/include -I$DEST/include/ncursesw"
CFLAGS="-mtune=mips32 -mips32 -O3 -ffunction-sections -fdata-sections"
CXXFLAGS=$CFLAGS
CONFIGURE="./configure --prefix=/jffs --host=mipsel-linux"
MAKE="make -j`nproc`"
mkdir $SRC

######## ####################################################################
# ZLIB # ####################################################################
######## ####################################################################

mkdir $SRC/zlib && cd $SRC/zlib
$WGET http://zlib.net/zlib-1.2.8.tar.gz
tar zxvf zlib-1.2.8.tar.gz
cd zlib-1.2.8

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
CROSS_PREFIX=mipsel-linux- \
./configure \
--prefix=/jffs \
--static

$MAKE
make install DESTDIR=$BASE

####### #####################################################################
# LZO # #####################################################################
####### #####################################################################

mkdir $SRC/lzo && cd $SRC/lzo
$WGET http://www.oberhumer.com/opensource/lzo/download/lzo-2.08.tar.gz
tar zxvf lzo-2.08.tar.gz
cd lzo-2.08

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE

$MAKE
make install DESTDIR=$BASE

########### #################################################################
# OPENSSL # #################################################################
########### #################################################################

mkdir -p $SRC/openssl && cd $SRC/openssl
$WGET http://www.openssl.org/source/openssl-1.0.1k.tar.gz
tar zxvf openssl-1.0.1k.tar.gz
cd openssl-1.0.1k

cat << "EOF" > openssl.patch
--- Configure_orig      2013-11-19 11:32:38.755265691 -0700
+++ Configure   2013-11-19 11:31:49.749650839 -0700
@@ -402,6 +402,7 @@ my %table=(
 "linux-alpha+bwx-gcc","gcc:-O3 -DL_ENDIAN -DTERMIO::-D_REENTRANT::-ldl:SIXTY_FOUR_BIT_LONG RC4_CHAR RC4_CHUNK DES_RISC1 DES_UNROLL:${alpha_asm}:dlfcn:linux-shared:-fPIC::.so.\$(SHLIB_MAJOR).\$(SHLIB_MINOR)",
 "linux-alpha-ccc","ccc:-fast -readonly_strings -DL_ENDIAN -DTERMIO::-D_REENTRANT:::SIXTY_FOUR_BIT_LONG RC4_CHUNK DES_INT DES_PTR DES_RISC1 DES_UNROLL:${alpha_asm}",
 "linux-alpha+bwx-ccc","ccc:-fast -readonly_strings -DL_ENDIAN -DTERMIO::-D_REENTRANT:::SIXTY_FOUR_BIT_LONG RC4_CHAR RC4_CHUNK DES_INT DES_PTR DES_RISC1 DES_UNROLL:${alpha_asm}",
+"linux-mipsel", "gcc:-DL_ENDIAN -DTERMIO -O3 -mtune=mips32 -mips32 -fomit-frame-pointer -Wall::-D_REENTRANT::-ldl:BN_LLONG RC4_CHAR RC4_CHUNK DES_INT DES_UNROLL BF_PTR:${mips32_asm}:o32:dlfcn:linux-shared:-fPIC::.so.\$(SHLIB_MAJOR).\$(SHLIB_MINOR)",

 # Android: linux-* but without -DTERMIO and pointers to headers and libs.
 "android","gcc:-mandroid -I\$(ANDROID_DEV)/include -B\$(ANDROID_DEV)/lib -O3 -fomit-frame-pointer -Wall::-D_REENTRANT::-ldl:BN_LLONG RC4_CHAR RC4_CHUNK DES_INT DES_UNROLL BF_PTR:${no_asm}:dlfcn:linux-shared:-fPIC::.so.\$(SHLIB_MAJOR).\$(SHLIB_MINOR)",
EOF

patch < openssl.patch

./Configure linux-mipsel \
-ffunction-sections -fdata-sections  -Wl,--gc-sections \
--prefix=/jffs zlib \
--with-zlib-lib=$DEST/lib \
--with-zlib-include=$DEST/include

make CC=mipsel-linux-gcc AR="mipsel-linux-ar r" RANLIB=mipsel-linux-ranlib
make install CC=mipsel-linux-gcc AR="mipsel-linux-ar r" RANLIB=mipsel-linux-ranlib INSTALLTOP=$DEST OPENSSLDIR=$DEST/ssl

########### #################################################################
# NCURSES # #################################################################
########### #################################################################

mkdir $SRC/curses && cd $SRC/curses
$WGET http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz
tar zxvf ncurses-5.9.tar.gz
cd ncurses-5.9

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--enable-widec \
--disable-database \
--with-fallbacks=xterm

$MAKE
make install DESTDIR=$BASE
ln -s libncursesw.a $DEST/lib/libcurses.a

############### #############################################################
# LIBREADLINE # #############################################################
############### #############################################################

mkdir $SRC/libreadline && cd $SRC/libreadline
$WGET ftp://ftp.cwru.edu/pub/bash/readline-6.2.tar.gz
tar zxvf readline-6.2.tar.gz
cd readline-6.2

$WGET https://raw.github.com/lancethepants/tomatoware/master/patches/readline.patch
patch < readline.patch

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--disable-shared

$MAKE
make install DESTDIR=$BASE

############ ################################################################
# TINC 1.0 # ################################################################
############ ################################################################

mkdir $SRC/tinc1.0 && cd $SRC/tinc1.0
$WGET http://www.tinc-vpn.org/packages/tinc-1.0.25.tar.gz
tar zxvf tinc-1.0.25.tar.gz
cd tinc-1.0.25

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--disable-hardening \
--localstatedir=/var \
--with-zlib=$DEST \
--with-lzo=$DEST \
--with-openssl=$DEST \

$MAKE LIBS="-static -lcrypto -ldl -llzo2 -lz"
make install DESTDIR=$BASE/tinc1.0 LIBS="-static -lcrypto -llzo2 -lz"

############ ################################################################
# TINC 1.1 # ################################################################
############ ################################################################

mkdir $SRC/tinc1.1 && cd $SRC/tinc1.1
$WGET http://www.tinc-vpn.org/packages/tinc-1.1pre11.tar.gz
tar zxvf tinc-1.1pre11.tar.gz
cd tinc-1.1pre11

LDFLAGS=$LDFLAGS \
CPPFLAGS=$CPPFLAGS \
CFLAGS=$CFLAGS \
CXXFLAGS=$CXXFLAGS \
$CONFIGURE \
--disable-hardening \
--localstatedir=/var \
--with-zlib=$DEST \
--with-lzo=$DEST \
--with-openssl=$DEST \
--with-curses=$DEST \
--with-readline=$DEST

$MAKE LIBS="-static -lcrypto -ldl -llzo2 -lz"
make install DESTDIR=$BASE/tinc1.1 LIBS="-static -lcrypto -ldl -llzo2 -lz"
