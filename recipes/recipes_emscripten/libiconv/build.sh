#!/bin/bash

set -ex

mkdir _build
cd _build

export CFLAGS="$CFLAGS -fPIC -fwasm-exceptions"
export CXXFLAGS="$CXXFLAGS -fwasm-exceptions"
export LDFLAGS="$LDFLAGS -fwasm-exceptions"

emconfigure ../configure \
    CFLAGS="$CFLAGS" \
    --prefix=$PREFIX \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --disable-dependency-tracking \
    --disable-shared
emmake make -j ${CPU_COUNT:-3} install

find . -iname "iconv.wasm" -exec cp {} $PREFIX/bin/ \;
