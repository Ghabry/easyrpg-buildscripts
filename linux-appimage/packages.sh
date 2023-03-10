#!/bin/bash

EXPAT_ARGS="-DEXPAT_BUILD_TOOLS=OFF -DEXPAT_BUILD_EXAMPLES=OFF -DEXPAT_BUILD_TESTS=OFF -DEXPAT_BUILD_DOCS=OFF -DEXPAT_SHARED_LIBS=ON"

lib=SDL2
ver=2.0.20
SDL2_URL="https://libsdl.org/release/$lib-$ver.tar.gz"
SDL2_DIR="$lib-$ver"

ICU_ARGS="--enable-strict=no --disable-tests --disable-samples \
	--disable-dyload --disable-extras --disable-icuio \
	--with-data-packaging=library --disable-layout --disable-layoutex"
