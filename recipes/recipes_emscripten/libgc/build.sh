#!/usr/bin/env bash
set -euxo pipefail

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CFLAGS="-fPIC" \
CXXFLAGS="-std=c++11 -fPIC" \
emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --disable-threads \
    --enable-cplusplus \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install