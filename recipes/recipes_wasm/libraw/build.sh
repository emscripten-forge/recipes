#!/bin/bash
set -ex

cd libraw

autoreconf --install

export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"

emconfigure ./configure --prefix="${PREFIX}" \
    --host=wasm32-unknown-emscripten \
    --disable-openmp \
    --disable-examples \
    --enable-static \
    --disable-shared

emmake make -j${CPU_COUNT}
emmake make install
