#!/usr/bin/env bash
set -euxo pipefail

./autogen.sh

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=gnu++14" \
emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --with-tbb=no \
    --with-gtest=no \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    MEMTAILOR_CFLAGS="-I${PREFIX}/include" \
    MEMTAILOR_LIBS="-L${PREFIX}/lib -lmemtailor" \
    MATHIC_CFLAGS="-I${PREFIX}/include" \
    MATHIC_LIBS="-L${PREFIX}/lib -lmathic"

emmake make -j8
emmake make install