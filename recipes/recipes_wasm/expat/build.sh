#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/libtool/build-aux/config.* ./conftools

if [[ "${target_platform}" == "emscripten-wasm64" ]]; then
  host="wasm64-unknown-emscripten"
else
  host="wasm32-unknown-emscripten"
fi

export CFLAGS="-fPIC"

emconfigure ./configure --prefix=$PREFIX \
            --host="${host}" \
            --enable-static \
            --enable-shared \
            --without-examples \
            --without-tests

make -j${CPU_COUNT}

make install

cp ./xmlwf/xmlwf.wasm $PREFIX/bin/
