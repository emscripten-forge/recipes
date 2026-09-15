#!/usr/bin/env bash
set -euxo pipefail

autoreconf -vfi

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    CPPFLAGS="${CPPFLAGS:-} -I${PREFIX}/include" \
    CFLAGS="${CFLAGS:-} -I${PREFIX}/include" \
    CXXFLAGS="${CXXFLAGS:-} -I${PREFIX}/include" \
    LDFLAGS="${LDFLAGS:-} -L${PREFIX}/lib"

emmake make -j8
emmake make install