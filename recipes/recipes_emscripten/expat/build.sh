#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./conftools

export CFLAGS="-fPIC"

emconfigure ./configure --prefix=$PREFIX \
            --host="wasm32-unknown-emscripten" \
            --enable-static \
            --disable-shared

make -j${CPU_COUNT}

make install

cp xmlwf/xmlwf.wasm $PREFIX/bin/