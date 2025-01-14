#!/bin/bash

set -eux

mkdir _build
cd _build

emconfigure ../configure \
    CFLAGS="-fPIC" \
    --prefix=$PREFIX \
    --build="x86_64-conda-linux-gnu" \
    --host="wasm32-unknown-emscripten" \
    --disable-dependency-tracking \
    --disable-shared
emmake make -j ${CPU_COUNT:-3} install

find . -iname "iconv.wasm" -exec cp {} $PREFIX/bin/ \;