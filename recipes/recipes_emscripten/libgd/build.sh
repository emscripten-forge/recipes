#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* . || true

emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC" \
    --prefix=$PREFIX \
    --enable-shared=no \
    --without-jpeg --without-xpm --without-x --without-fontconfig \
    --without-avif --without-freetype --without-raqm --without-liq \
    --without-tiff --without-webp --without-heif \
    --disable-gd-formats

make -j${CPU_COUNT}
make install
