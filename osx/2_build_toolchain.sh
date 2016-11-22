#!/bin/bash

# abort on error
set -e

export WORKSPACE=$PWD

export TARGET_HOST=i386-apple-darwin
export PLATFORM_PREFIX=$WORKSPACE
export PKG_CONFIG_PATH=$PLATFORM_PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_PATH

# Number of CPU
#NBPROC=$(getconf _NPROCESSORS_ONLN)
NBPROC=$(sysctl -n hw.ncpu)

# Use ccache?
if [ -z ${NO_CCACHE+x} ]; then
	if hash ccache >/dev/null 2>&1; then
		ENABLE_CCACHE=1
		echo "CCACHE enabled"
	fi
fi

if [ ! -f .patches-applied ]; then
	echo "patching libraries"

	cp -r icu icu-native

	# disable pixman examples and tests
	cd pixman-0.34.0
	sed -i.bak 's/SUBDIRS = pixman demos test/SUBDIRS = pixman/' Makefile.am
	autoreconf -fi
	cd ..

	# disable png utils
	cd libpng-1.6.26
	sed -i.bak 's/^bin_PROGRAMS/# &/' Makefile.am
	autoreconf -fi
	cd ..

	# disable sndfile examples and tests
	cd libsndfile-1.0.27
	sed -i.bak 's/SUBDIRS = \(.*\) examples regtest tests programs/SUBDIRS = \1/' Makefile.am
	autoreconf -fi	
	cd ..

	# disable SDL_mixer smpeg check and playmus/playwave
	cd SDL2_mixer-2.0.1
	sed -i.bak 's/AM_PATH_SMPEG2.*//' configure.in
	sed -i.bak 's/^all: \(.*\) $(objects)\/playwave$(EXE) $(objects)\/playmus$(EXE)/all: \1/' Makefile.in
	autoreconf -fi
	cd ..

	touch .patches-applied
fi

function set_build_flags {
	CCOMPILER=$(xcrun --find clang)
	CXXCOMPILER=$(xcrun --find clang++)
	SDKPATH=$(xcrun --show-sdk-path)

	# Enabling i386 breaks SDL compilation because objc-codegen is not supported
	# Though the only system with i386 is MacOSX 10.6 which is pretty old
#       export CC="$CCOMPILER -isysroot $SDKPATH -arch i386 -arch x86_64"
#       export CPP="$CCOMPILER -isysroot $SDKPATH -arch i386 -E"
#       export CXXCPP="$CXXCOMPILER -isysroot $SDKPATH -arch i386 -E"
#       export CXX="$CXXCOMPILER -isysroot $SDKPATH -arch i386 -arch x86_64"

	export CC="$CCOMPILER -isysroot $SDKPATH -arch x86_64"
	export CXX="$CXXCOMPILER -isysroot $SDKPATH -arch x86_64"

	if [ "$ENABLE_CCACHE" ]; then  
		export CC="ccache $CC"  
		export CXX="ccache $CXX"
	fi

	export CFLAGS="-I$PLATFORM_PREFIX/include -g -O2"
	export CPPFLAGS="$CFLAGS"
	export LDFLAGS="-L$PLATFORM_PREFIX/lib"
	if [ "$NBPROC" ]; then
		export MAKEFLAGS="-j$NBPROC"
	fi
}

# Default lib installer
function install_lib {
	echo ""
	echo "**** Building ${1%-*} ****"
	echo ""

	cd $1
	shift
	./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX \
		--disable-shared --enable-static $@
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

# Install zlib
function install_lib_zlib {
	echo ""
	echo "**** Building zlib ****"
	echo ""

	cd zlib-1.2.8
	CHOST=$TARGET_HOST ./configure --static --prefix=$PLATFORM_PREFIX
	make clean
	make
	make install
	cd ..

	echo " -> done"
}

# Install ICU
function install_lib_icu_native {
	echo ""
	echo "**** Building ICU (native) ****"
	echo ""

	# Compile native version
	unset CC
	unset CPP
	unset CXX
	unset CXXCPP
	unset CFLAGS
	unset CPPFLAGS
	unset LDFLAGS

	cp icudt58l.dat icu/source/data/in/
	cp icudt58l.dat icu-native/source/data/in/
	cd icu-native/source
	sed -i.bak 's/SMALL_BUFFER_MAX_SIZE 512/SMALL_BUFFER_MAX_SIZE 2048/' tools/toolutil/pkg_genc.h
	chmod u+x configure
	./configure --enable-static --enable-shared=no --enable-tests=no --enable-samples=no \
		--enable-dyload=no --enable-tools --enable-extras=no --enable-icuio=no \
		--with-data-packaging=static
	make

	cd ../..
}

function install_lib_icu {
	echo ""
	echo "**** Building ICU ****"
	echo ""

	export ICU_CROSS_BUILD=$PWD/icu-native/source

	cd icu/source

	cp config/mh-linux config/mh-unknown

	chmod u+x configure
	./configure --with-cross-build=$ICU_CROSS_BUILD --enable-strict=no \
		--enable-static --enable-shared=no --enable-tests=no --enable-samples=no --enable-dyload=no \
		--enable-tools=no --enable-extras=no --enable-icuio=no --host=$TARGET_HOST \
		--with-data-packaging=static --prefix=$PLATFORM_PREFIX
	make clean
	make
	make install
	cd ../..

	echo " -> done"
}

function install_lib_wildmidi {
	echo ""
	echo "**** Building WildMidi ****"
	echo ""

	cd wildmidi-wildmidi-0.3.10
	cmake . -DCMAKE_SYSTEM_NAME=Generic -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWANT_PLAYER=OFF
	make clean
	make
	cp -p include/wildmidi_lib.h $PLATFORM_PREFIX/include
	cp -p libWildMidi.a $PLATFORM_PREFIX/lib
	cd ..

	echo " -> done"
}

function install_lib_sdl {
	echo ""
	echo "**** Building SDL ****"
	echo ""

	cd SDL2-2.0.5

	cp include/SDL_config_macosx.h  include/SDL_config.h

#	no-obj-arc because garbage collection is broken with some SDL code
	CFLAGS="-fno-objc-arc $CFLAGS" ./configure --host=$TARGET_HOST --prefix=$PLATFORM_PREFIX \
		--disable-shared --enable-static
	make clean
	make install
	cd ../

	echo " -> done"
}

# Prepare ICU
install_lib_icu_native

# Install libraries
set_build_flags

install_lib_zlib
install_lib libpng-1.6.26
install_lib freetype-2.7 --with-harfbuzz=no --without-bzip2
install_lib harfbuzz-1.3.3
install_lib freetype-2.7 --with-harfbuzz=yes --without-bzip2
install_lib pixman-0.34.0
install_lib expat-2.2.0
install_lib libogg-1.3.2
install_lib libvorbis-1.3.5
install_lib_icu
install_lib mpg123-1.23.8 --enable-fifo=no --enable-ipv6=no --enable-network=no \
	--enable-int-quality=no --with-cpu=generic --with-default-audio=dummy
install_lib libsndfile-1.0.27
install_lib speexdsp-1.2rc3 --disable-neon
install_lib_wildmidi
install_lib libxmp-lite-4.4.1
install_lib_sdl
install_lib SDL2_mixer-2.0.1 --disable-music-mp3 \
	--disable-music-mod --disable-music-midi --disable-music-ogg
