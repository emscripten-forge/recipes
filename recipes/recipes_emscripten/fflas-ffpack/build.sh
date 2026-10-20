#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib -sALLOW_MEMORY_GROWTH=1" \
CXXFLAGS="-std=c++11" \
emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --without-archnative \
    --disable-openmp \
    --with-blas-libs="-L${PREFIX}/lib -lopenblas" \
    --with-blas-cflags="-I${PREFIX}/include" \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    GIVARO_CFLAGS="-I${PREFIX}/include" \
    GIVARO_LIBS="-L${PREFIX}/lib -lgivaro -lgmp"

emmake make -j8
emmake make install