#!/usr/bin/env bash
set -euxo pipefail

./autogen.sh

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=gnu++0x" \
emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --with-gtest=no \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"

emmake make -j8
emmake make install