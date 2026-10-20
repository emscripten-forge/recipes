#!/usr/bin/env bash
set -euxo pipefail

emconfigure ./configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    CFLAGS="${CFLAGS:-}" \
    CXXFLAGS="${CXXFLAGS:-}" \
    LDFLAGS="${LDFLAGS:-}"

emmake make -j8
emmake make install