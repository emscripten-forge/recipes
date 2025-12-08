#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* . || true

emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC" \
    --prefix=$PREFIX \
    --with-gmp=$PREFIX \
    --enable-shared=no

make -j${CPU_COUNT}
make install
