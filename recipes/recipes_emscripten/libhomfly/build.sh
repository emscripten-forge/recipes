#!/usr/bin/env bash
set -euxo pipefail

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    CPPFLAGS="-I${PREFIX}/include" \
    CFLAGS="-O2 -I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib"

emmake make -j8
emmake make install