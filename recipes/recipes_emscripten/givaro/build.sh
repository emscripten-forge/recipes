#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=c++11" \
emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --with-gmp="${PREFIX}" \
    --without-archnative \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install