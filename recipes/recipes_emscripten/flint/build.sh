#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* . || true

emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC" \
    --prefix=$PREFIX \
    --with-gmp=$PREFIX \
    --with-mpfr=$PREFIX \
    --disable-dependency-tracking \
    --disable-shared \
    --host=wasm32-unknown-emscripten \
    --disable-assembly \
    --disable-pthread

make -j${CPU_COUNT}
make install
